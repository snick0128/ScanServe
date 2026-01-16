import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart' as model;

class BillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  /// Generate bill for a table
  Future<String> generateBill({
    required String tenantId,
    required String tableId,
    required List<model.Order> orders,
    double discount = 0.0,
  }) async {
    try {
      final billId = _uuid.v4();
      
      // Calculate totals
      double subtotal = 0.0;
      double tax = 0.0;
      double total = 0.0;
      
      for (final order in orders) {
        subtotal += order.subtotal;
        tax += order.tax;
        total += order.total;
      }
      
      // Apply discount on subtotal (Requirement 9)
      final discountAmount = subtotal * (discount / 100);
      final discountedSubtotal = subtotal - discountAmount;
      
      // Recalculate tax based on discounted subtotal
      // (Assuming tax rate is proportional to subtotal)
      final taxRate = subtotal > 0 ? (tax / subtotal) : 0.05; 
      final newTax = discountedSubtotal * taxRate;
      final finalTotal = discountedSubtotal + newTax;
      
      // Harvest customer info from orders
      String? customerName;
      String? customerPhone;
      for (final order in orders) {
        if (order.customerName != null && customerName == null) customerName = order.customerName;
        if (order.customerPhone != null && customerPhone == null) customerPhone = order.customerPhone;
        if (customerName != null && customerPhone != null) break;
      }

      // Create bill document
      final billData = {
        'billId': billId,
        'tenantId': tenantId,
        'tableId': tableId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'orders': orders.map((model.Order o) => o.id).toList(),
        'subtotal': subtotal,
        'tax': newTax, // Use recalculated tax
        'discount': discount,
        'discountAmount': discountAmount,
        'total': subtotal + tax, // Original total
        'finalTotal': finalTotal,
        'createdAt': FieldValue.serverTimestamp(),
        'orderDetails': orders.map((model.Order o) => {
          'orderId': o.id,
          'items': o.items.map((item) => {
            'name': item.name,
            'quantity': item.quantity,
            'price': item.price,
            'total': item.price * item.quantity,
          }).toList(),
          'subtotal': o.subtotal,
          'tax': o.tax,
          'total': o.total,
        }).toList(),
      };
      
      // Save bill
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('bills')
          .doc(billId)
          .set(billData);
      
      // Mark all orders as served (final state)
      final batch = _firestore.batch();
      for (final order in orders) {
        final orderRef = _firestore
            .collection('tenants')
            .doc(tenantId)
            .collection('orders')
            .doc(order.id);
        
        batch.update(orderRef, {
          'status': model.OrderStatus.served.toString().split('.').last,
          'updatedAt': FieldValue.serverTimestamp(),
          'billId': billId,
        });
      }
      await batch.commit();
      
      /* Table release moved to Mark Paid button in UI 
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('tables')
          .doc(tableId)
          .update({
        'isAvailable': true,
        'status': 'available',
        'isOccupied': false,
        'currentSessionId': null,
        'occupiedAt': null,
        'lastBillId': billId,
        'lastBillTime': FieldValue.serverTimestamp(),
      });
      */
      
      print('Bill generated successfully: $billId');
      return billId;
    } catch (e) {
      print('Error generating bill: $e');
      rethrow;
    }
  }
  
  /// Get bill by ID
  Future<Map<String, dynamic>?> getBill(String tenantId, String billId) async {
    try {
      final doc = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('bills')
          .doc(billId)
          .get();
      
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error fetching bill: $e');
      return null;
    }
  }
  
  /// Get all bills for a tenant
  Stream<List<Map<String, dynamic>>> getBills(String tenantId) {
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('bills')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }
}
