import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart' as model;
import '../utils/bill_calculator.dart';

class BillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  /// Generate bill for a table
  Future<String> generateBill({
    required String tenantId,
    required String tableId,
    required List<model.Order> orders,
    double discount = 0.0,
    bool isPercentage = true,
    double? taxRate,
    String? paymentMethod,
    String? note,
  }) async {
    try {
      final billId = _uuid.v4();
      
      final calculations = BillCalculator.calculateBill(
        orders: orders,
        discountValue: discount,
        isPercentageDiscount: isPercentage,
        customTaxRate: taxRate,
      );

      final subtotal = calculations['subtotal']!;
      final newTax = calculations['taxAmount']!;
      final discountAmount = calculations['totalDiscount']!;
      final finalTotal = calculations['finalTotal']!;
      
      String? customerName;
      String? customerPhone;
      for (final order in orders) {
        if (order.customerName != null && customerName == null) customerName = order.customerName;
        if (order.customerPhone != null && customerPhone == null) customerPhone = order.customerPhone;
        if (customerName != null && customerPhone != null) break;
      }

      final Map<String, Map<String, dynamic>> consolidatedItems = {};
      for (final order in orders) {
        for (final item in order.items) {
          final String key = item.variantName != null 
              ? '${item.name} (${item.variantName})' 
              : item.name;
          
          if (consolidatedItems.containsKey(key)) {
            final existing = consolidatedItems[key]!;
            existing['quantity'] = (existing['quantity'] as int) + item.quantity;
            existing['total'] = (existing['quantity'] as int) * (existing['price'] as double);
          } else {
            consolidatedItems[key] = {
              'name': key,
              'quantity': item.quantity,
              'price': item.price,
              'total': item.price * item.quantity,
            };
          }
        }
      }

      final billData = {
        'billId': billId,
        'tenantId': tenantId,
        'tableId': tableId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'orders': orders.map((model.Order o) => o.id).toList(),
        'subtotal': subtotal,
        'tax': newTax,
        'discount': discount,
        'isPercentageDiscount': isPercentage,
        'discountAmount': discountAmount,
        'totalDiscount': discountAmount,
        'total': subtotal + newTax,
        'finalTotal': finalTotal,
        'taxRate': taxRate,
        'paymentMethod': paymentMethod ?? 'Cash',
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        'orderDetails': consolidatedItems.values.toList(),
      };
      
      await _firestore.runTransaction((transaction) async {
        // Create the bill document
        final billRef = _firestore
            .collection('tenants')
            .doc(tenantId)
            .collection('bills')
            .doc(billId);
        
        transaction.set(billRef, billData);
        
        // Tag orders with this billId, but DON'T complete them yet (Requirement: Release on payment)
        for (final order in orders) {
          final orderRef = _firestore
              .collection('tenants')
              .doc(tenantId)
              .collection('orders')
              .doc(order.id);
          
          transaction.update(orderRef, {
            'billId': billId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      
      print('✅ Bill #$billId created and orders tagged');
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
