import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart' as model;
import '../models/order_model.dart' as orm;
import '../models/order_details.dart' as model_details;
import '../controllers/cart_controller.dart';
import '../utils/session_validator.dart';
import '../utils/request_debouncer.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();
  final RequestDebouncer _debouncer = RequestDebouncer();

  /// Create or append to an order
  Future<String> createOrder({
    required String tenantId,
    required String guestId,
    required orm.OrderType orderType, 
    String? tableId,
    required List<CartItem> cartItems,
    String? notes,
    String? chefNote,
    String customerName = '',
    String? customerPhone,
    model.PaymentStatus paymentStatus = model.PaymentStatus.pending,
    String? paymentMethod,
    String? requestId, // UUID for deduplication
    String? sessionId, // session ID for Bug #6
  }) async {
    try {
      // CRITICAL: Validate session identifiers
      final validation = SessionValidator.validateForOrder(
        tenantId: tenantId,
        tableId: tableId,
        isParcelOrder: orderType == orm.OrderType.parcel,
      );

      if (!validation.isValid) {
        throw Exception('Order creation failed: ${validation.errorMessage}');
      }

      // CRITICAL: Check for duplicate request
      if (requestId != null) {
        if (!_debouncer.canProcessRequest(requestId)) {
          throw Exception('Duplicate order request detected. Please wait.');
        }
        _debouncer.markRequestStarted(requestId);
      }

      final tenantSettings = await getTenantSettings(tenantId);
      final taxRate = (tenantSettings['taxRate'] as num?)?.toDouble() ?? 0.18;

      // 1. Check for existing active order for this table (Dine-in only)
      if (orderType == orm.OrderType.dineIn && tableId != null) {
        // Bug #6: Robust Order Merge Validation
        final tableDoc = await _firestore.collection('tenants').doc(tenantId).collection('tables').doc(tableId).get();
        final lastReleasedAt = (tableDoc.data()?['lastReleasedAt'] as Timestamp?)?.toDate();
        final fourHoursAgo = DateTime.now().subtract(const Duration(hours: 4));

        final existingOrdersQuery = await _firestore
            .collection('tenants')
            .doc(tenantId)
            .collection('orders')
            .where('tableId', isEqualTo: tableId)
            .where('status', whereIn: [
              model.OrderStatus.pending.name,
              model.OrderStatus.preparing.name,
              model.OrderStatus.ready.name,
              model.OrderStatus.served.name,
            ])
            .get();

        model.Order? orderToMerge;
        
        for (final doc in existingOrdersQuery.docs) {
          final order = model.Order.fromFirestore(doc);
          
          // CRITICAL VALIDATION (Bug #6):
          // 1. Matches sessionId (Highest confidence)
          // 2. Created AFTER last table release (New session)
          // 3. Not older than 4 hours (Archive threshold)
          bool canMerge = false;
          
          if (sessionId != null && order.sessionId == sessionId) {
            canMerge = true;
          } else if (order.createdAt.isAfter(lastReleasedAt ?? DateTime(2000)) && 
                     order.createdAt.isAfter(fourHoursAgo)) {
            // If session ID matches but we don't have it on order yet (legacy)
            // or if it's the same physical session but guest refreshed
            canMerge = true;
          }

          if (canMerge) {
            orderToMerge = order;
            break;
          }
        }

        if (orderToMerge != null) {
          final existingOrder = orderToMerge;
          
          print('🔄 Appending add-ons to order ${existingOrder.id} for table $tableId');

          // Add-on items must be visually marked and maintained with timestamps
          List<model.OrderItem> updatedItems = List.from(existingOrder.items);
          for (var cartItem in cartItems) {
            final price = cartItem.selectedVariant?.price ?? cartItem.item.price;
            updatedItems.add(model.OrderItem(
              id: cartItem.item.id,
              name: cartItem.item.name,
              price: price,
              quantity: cartItem.quantity,
              notes: cartItem.note,
              imageUrl: cartItem.item.imageUrl,
              timestamp: DateTime.now(),
              isAddon: true, // Mark as add-on (Requirement 4)
              chefNote: chefNote,
              variantName: cartItem.selectedVariant?.name,
            ));
          }

          // Recalculate totals
          final newSubtotal = updatedItems.fold<double>(0, (sum, item) => sum + item.total);
          // Apply existing discounts if any
          final discountAmount = existingOrder.discountPercentage > 0 
              ? (newSubtotal * existingOrder.discountPercentage / 100) 
              : existingOrder.discountAmount;
          
          final taxAmount = (newSubtotal - discountAmount) * taxRate;
          final newTotal = (newSubtotal - discountAmount) + taxAmount;

          await _firestore
              .collection('tenants')
              .doc(tenantId)
              .collection('orders')
              .doc(existingOrder.id)
              .update({
            'items': updatedItems.map((i) => i.toMap()).toList(),
            'subtotal': newSubtotal,
            'tax': taxAmount,
            'total': newTotal,
            'updatedAt': FieldValue.serverTimestamp(),
            // Append chef notes if provided
            if (chefNote != null && chefNote.isNotEmpty) 
              'chefNote': existingOrder.chefNote != null 
                  ? '${existingOrder.chefNote} | $chefNote' 
                  : chefNote,
          });

          return existingOrder.id;
        }
      }

      // 2. Create New Order
      final orderId = _uuid.v4();
      
      // Get table name
      String? tableName;
      if (orderType == orm.OrderType.dineIn && tableId != null) {
        final tableDoc = await _firestore.collection('tenants').doc(tenantId).collection('tables').doc(tableId).get();
        tableName = tableDoc.data()?['name'] as String?;
      }

      final List<model.OrderItem> items = cartItems.map((c) {
        final price = c.selectedVariant?.price ?? c.item.price;
        return model.OrderItem(
          id: c.item.id,
          name: c.item.name,
          price: price,
          quantity: c.quantity,
          notes: c.note,
          imageUrl: c.item.imageUrl,
          timestamp: DateTime.now(),
          isAddon: false,
          variantName: c.selectedVariant?.name,
        );
      }).toList();

      final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
      final taxAmount = subtotal * taxRate;
      final total = subtotal + taxAmount;

      final order = model.Order(
        id: orderId,
        tenantId: tenantId,
        guestId: guestId,
        type: orderType.name,
        tableId: tableId,
        tableName: tableName,
        items: items,
        subtotal: subtotal,
        tax: taxAmount,
        total: total,
        status: model.OrderStatus.pending,
        paymentStatus: paymentStatus,
        createdAt: DateTime.now(),
        customerName: customerName,
        customerPhone: customerPhone,
        paymentMethod: paymentMethod,
        notes: notes,
        chefNote: chefNote,
        sessionId: sessionId,
      );

      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('orders')
          .doc(orderId)
          .set(order.toMap());

      // 3. Update table status (Requirement 7)
      if (orderType == orm.OrderType.dineIn && tableId != null) {
        await _firestore.collection('tenants').doc(tenantId).collection('tables').doc(tableId).update({
          'status': 'occupied',
          'isOccupied': true,
          'isAvailable': false,
          'occupiedAt': FieldValue.serverTimestamp(),
          'currentSessionId': sessionId ?? orderId, // Use sessionId if available
        });
      }

      // Mark request as completed
      if (requestId != null) {
        _debouncer.markRequestCompleted(requestId);
      }

      return orderId;
    } catch (e) {
      // Mark request as failed
      if (requestId != null) {
        _debouncer.markRequestFailed(requestId);
      }
      
      print('Error in OrderService.createOrder: $e');
      rethrow;
    }
  }

  /// Mark all active orders for a table as paid (Atomic Operation)
  /// Requirement 1: Payment success results in Table Vacate immediately
  Future<void> markTableOrdersAsPaid({
    required String tenantId,
    required String tableId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Find all non-completed orders for this table
        final ordersQuery = await _firestore
            .collection('tenants')
            .doc(tenantId)
            .collection('orders')
            .where('tableId', isEqualTo: tableId)
            .where('status', whereNotIn: [
              model.OrderStatus.completed.name,
              model.OrderStatus.cancelled.name
            ])
            .get();

        // 2. Update each order to 'completed'
        for (var doc in ordersQuery.docs) {
          transaction.update(doc.reference, {
            'status': model.OrderStatus.completed.name,
            'paymentStatus': model.PaymentStatus.paid.name,
            'updatedAt': FieldValue.serverTimestamp(),
            'closedAt': FieldValue.serverTimestamp(),
          });
        }

        // 3. Update table status to 'vacant'
        final tableRef = _firestore
            .collection('tenants')
            .doc(tenantId)
            .collection('tables')
            .doc(tableId);
        
        transaction.update(tableRef, {
          'status': 'available', // Consistent with Table lifecycle
          'isAvailable': true,
          'isOccupied': false,
          'currentSessionId': null,
          'occupiedAt': null,
          'lastReleasedAt': FieldValue.serverTimestamp(),
        });
      });
      
      print('✅ Atomic PaymentSuccess completed for table $tableId');
    } catch (e) {
      print('❌ Error in markTableOrdersAsPaid: $e');
      rethrow;
    }
  }

  /// Update order status (Strict lifecycle)
  Future<void> updateOrderStatus(String tenantId, String orderId, model.OrderStatus status) async {
    // Note: 'Completed' should ideally be via payment callback
    await _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('orders')
        .doc(orderId)
        .update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> getTenantSettings(String tenantId) async {
    final doc = await _firestore.collection('tenants').doc(tenantId).get();
    return doc.data() ?? {};
  }

  /// Get active orders for a specific table
  Stream<List<model_details.OrderDetails>> getTableOrders(String tenantId, String tableId) {
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('orders')
        .where('tableId', isEqualTo: tableId)
        .where('status', whereNotIn: [
          model.OrderStatus.completed.name,
          model.OrderStatus.cancelled.name
        ])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => model_details.OrderDetails.fromMap({
                    ...doc.data(),
                    'orderId': doc.id, // Ensure ID is mapped correctly
                  }))
              .toList();
        });
  }
}
