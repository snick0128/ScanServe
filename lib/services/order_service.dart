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

      final orderDetails = OrderDetails.fromCart(
        orderId: orderId,
        guestId: guestId,
        tenantId: tenantId,
        type: orderType,
        tableId: tableId,
        cartItems: cartItems,
        avgPrepTime: 25,
        taxRate: taxRate,
        paymentStatus: paymentStatus,
        paymentMethod: paymentMethod,
        customerName: customerName,
        customerPhone: customerPhone,
      );

      // Store in appropriate location based on order type
      if (orderType == OrderType.dineIn && tableId != null) {
        print('🍽️ Saving dine-in order to: tenants/$tenantId/tables/$tableId/orders/$orderId');
        // Dine-in: Store under table
        await _firestore
            .collection('tenants')
            .doc(tenantId)
            .collection('tables')
            .doc(tableId)
            .collection('orders')
            .doc(orderId)
            .set(orderDetails.toMap());
      } else {
        print('📦 Saving parcel order to: tenants/$tenantId/orders/$orderId');
        // Parcel: Store directly under tenant orders
        await _firestore
            .collection('tenants')
            .doc(tenantId)
            .collection('orders')
            .doc(orderId)
            .set(orderDetails.toMap());
      }

      print('Order saved successfully: $orderId');
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
            OrderStatus.confirmed.name,
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
