import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart' as model;
import '../models/order_model.dart' as orm;
import '../models/order_details.dart' as model_details;
import '../controllers/cart_controller.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

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
  }) async {
    try {
      final tenantSettings = await getTenantSettings(tenantId);
      final taxRate = (tenantSettings['taxRate'] as num?)?.toDouble() ?? 0.18;

      // 1. Check for existing active order for this table (Dine-in only)
      if (orderType == orm.OrderType.dineIn && tableId != null) {
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

        if (existingOrdersQuery.docs.isNotEmpty) {
          final existingOrderDoc = existingOrdersQuery.docs.first;
          final existingOrder = model.Order.fromFirestore(existingOrderDoc);
          
          print('🔄 Appending add-ons to order ${existingOrder.id} for table $tableId');

          // Add-on items must be visually marked and maintained with timestamps
          List<model.OrderItem> updatedItems = List.from(existingOrder.items);
          for (var cartItem in cartItems) {
            updatedItems.add(model.OrderItem(
              id: cartItem.item.id,
              name: cartItem.item.name,
              price: cartItem.item.price,
              quantity: cartItem.quantity,
              notes: cartItem.note,
              imageUrl: cartItem.item.imageUrl,
              timestamp: DateTime.now(),
              isAddon: true, // Mark as add-on (Requirement 4)
              chefNote: chefNote,
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

      final List<model.OrderItem> items = cartItems.map((c) => model.OrderItem(
        id: c.item.id,
        name: c.item.name,
        price: c.item.price,
        quantity: c.quantity,
        notes: c.note,
        imageUrl: c.item.imageUrl,
        timestamp: DateTime.now(),
        isAddon: false,
      )).toList();

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
          'currentSessionId': orderId,
        });
      }

      return orderId;
    } catch (e) {
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
