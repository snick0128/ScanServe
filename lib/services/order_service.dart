import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_details.dart';
import '../controllers/cart_controller.dart';
import '../models/order_model.dart';

class OrderService {
  final _firestore = FirebaseFirestore.instance;

  // Save new order to Firestore
  Future<String> placeOrder({
    required String tenantId,
    required String guestId,
    required OrderType type,
    String? tableId,
    required List<CartItem> items,
    required int avgPrepTime,
  }) async {
    try {
      final orderId = _firestore.collection('orders').doc().id;
      final tenantSettings = await getTenantSettings(tenantId);
      final taxRate = tenantSettings['taxRate'] as double? ?? 0.18;

      final orderDetails = OrderDetails.fromCart(
        orderId: orderId,
        guestId: guestId,
        tenantId: tenantId,
        type: type,
        tableId: tableId,
        cartItems: items,
        avgPrepTime: avgPrepTime,
        taxRate: taxRate,
      );

      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('orders')
          .doc(orderId)
          .set(orderDetails.toMap());

      return orderId;
    } catch (e) {
      print('Error placing order: $e');
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
            OrderStatus.ready.name,
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
