import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/order_details.dart';
import '../models/order_model.dart';
import '../controllers/cart_controller.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  // Order types
  static const String TYPE_DINE_IN = 'dinein';
  static const String TYPE_PARCEL = 'parcel';

  /// Create a new order
  Future<String> createOrder({
    required String tenantId,
    required String guestId,
    required OrderType orderType,
    String? tableId,
    required List<CartItem> cartItems,
    String? notes,
    String? chefNote,
    String customerName = '',
    String? customerPhone,
    PaymentStatus paymentStatus = PaymentStatus.pending,
    PaymentMethod paymentMethod = PaymentMethod.upi,
  }) async {
    try {
      final orderId = _uuid.v4();
      final tenantSettings = await getTenantSettings(tenantId);
      final taxRate = tenantSettings['taxRate'] as double? ?? 0.18;

      print('Creating order: $orderId for guest: $guestId, type: ${orderType.name}, tableId: $tableId');

      // Get table name if this is a dine-in order
      String? tableName;
      if (orderType == OrderType.dineIn && tableId != null) {
        try {
          final tableDoc = await _firestore
              .collection('tenants')
              .doc(tenantId)
              .collection('tables')
              .doc(tableId)
              .get();
          tableName = tableDoc.data()?['name'] as String?;
        } catch (e) {
          print('Warning: Could not fetch table name: $e');
        }
      }

      final orderDetails = OrderDetails.fromCart(
        orderId: orderId,
        guestId: guestId,
        tenantId: tenantId,
        type: orderType,
        tableId: tableId,
        tableName: tableName,
        cartItems: cartItems,
        avgPrepTime: 25,
        taxRate: taxRate,
        paymentStatus: paymentStatus,
        paymentMethod: paymentMethod,
        customerName: customerName,
        customerPhone: customerPhone,
        chefNote: chefNote,
      );

      // UNIFIED STORAGE: Store ALL orders in tenants/$tenantId/orders
      print('💾 Saving order to unified location: tenants/$tenantId/orders/$orderId');
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('orders')
          .doc(orderId)
          .set(orderDetails.toMap());

      print('Order saved successfully: $orderId');

      // Update table status if dine-in
      if (orderType == OrderType.dineIn && tableId != null) {
        try {
          await _firestore
              .collection('tenants')
              .doc(tenantId)
              .collection('tables')
              .doc(tableId)
              .update({
            'isAvailable': false,
            'status': 'occupied',
            'occupiedAt': FieldValue.serverTimestamp(),
          });
          print('Table $tableId marked as occupied');
        } catch (e) {
          print('Error updating table status: $e');
        }
      }

      return orderId;
    } catch (e) {
      print('Error placing order: $e');
      rethrow;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus({
    required String tenantId,
    required String orderId,
    required OrderStatus newStatus,
  }) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('orders')
          .doc(orderId)
          .update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Order $orderId status updated to ${newStatus.name}');
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  // Get all active orders for a table
  Stream<List<OrderDetails>> getTableOrders(String tenantId, String tableId) {
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('orders')
        .where('tableId', isEqualTo: tableId)
        .where(
          'status',
          whereIn: [
            OrderStatus.pending.name,
            OrderStatus.preparing.name,
            OrderStatus.served.name,
          ],
        )
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderDetails.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get tenant's average preparation time
  Future<int> getTenantPrepTime(String tenantId) async {
    try {
      final doc = await _firestore.collection('tenants').doc(tenantId).get();

      return doc.data()?['avgPrepTime'] ?? 30; // Default 30 minutes
    } catch (e) {
      print('Error getting tenant prep time: $e');
      return 30; // Default fallback
    }
  }

  // Get tenant's settings (tax rate, etc.)
  Future<Map<String, dynamic>> getTenantSettings(String tenantId) async {
    try {
      final doc = await _firestore.collection('tenants').doc(tenantId).get();
      return doc.data() ?? {};
    } catch (e) {
      print('Error getting tenant settings: $e');
      return {}; // Default fallback
    }
  }
}
