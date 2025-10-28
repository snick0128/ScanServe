import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/order_details.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  /// Process payment for an order
  Future<String> processPayment({
    required String orderId,
    required String tenantId,
    required PaymentMethod paymentMethod,
    required double amount,
    String? customerId,
    String? tableId,
  }) async {
    try {
      final paymentId = _uuid.v4();
      final timestamp = DateTime.now();

      // Create payment record
      await _firestore.collection('payments').doc(paymentId).set({
        'paymentId': paymentId,
        'orderId': orderId,
        'tenantId': tenantId,
        'customerId': customerId,
        'tableId': tableId,
        'amount': amount,
        'paymentMethod': paymentMethod.name,
        'status': PaymentStatus.pending.name,
        'timestamp': Timestamp.fromDate(timestamp),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // For demo purposes, we'll simulate different payment methods
      // In a real app, you'd integrate with actual payment gateways

      PaymentStatus finalStatus;

      switch (paymentMethod) {
        case PaymentMethod.cash:
          // Cash payments are marked as paid immediately
          finalStatus = PaymentStatus.paid;
          break;
        case PaymentMethod.upi:
          // For UPI payments, simulate processing
          await Future.delayed(const Duration(seconds: 2)); // Simulate processing time
          finalStatus = PaymentStatus.paid; // Assume success for demo
          break;
      }

      // Update payment status
      await _firestore.collection('payments').doc(paymentId).update({
        'status': finalStatus.name,
        'completedAt': finalStatus == PaymentStatus.paid
            ? Timestamp.fromDate(DateTime.now())
            : null,
      });

      // Update order payment status
      await _updateOrderPaymentStatus(orderId, tenantId, finalStatus, paymentId, tableId);

      return paymentId;
    } catch (e) {
      print('Error processing payment: $e');
      rethrow;
    }
  }

  /// Update order payment status in Firestore
  Future<void> _updateOrderPaymentStatus(
    String orderId,
    String tenantId,
    PaymentStatus paymentStatus,
    String paymentId,
    String? tableId,
  ) async {
    try {
      final updateData = {
        'paymentStatus': paymentStatus.name,
        'paymentId': paymentId,
        'paymentTimestamp': Timestamp.fromDate(DateTime.now()),
      };

      // If payment is paid, also update order status
      if (paymentStatus == PaymentStatus.paid) {
        updateData['status'] = tableId != null ? OrderStatus.preparing.name : OrderStatus.confirmed.name;
      }

      if (tableId != null) {
        // Update dine-in order
        await _firestore
            .collection('tenants')
            .doc(tenantId)
            .collection('tables')
            .doc(tableId)
            .collection('orders')
            .doc(orderId)
            .update(updateData);
      } else {
        // Update parcel order
        await _firestore
            .collection('tenants')
            .doc(tenantId)
            .collection('orders')
            .doc(orderId)
            .update(updateData);
      }
    } catch (e) {
      print('Error updating order payment status: $e');
      rethrow;
    }
  }

  /// Get payment status for an order
  Future<PaymentStatus> getPaymentStatus(String orderId, String tenantId) async {
    try {
      // Try to find the order in both locations
      DocumentSnapshot? orderDoc;

      // Check parcel orders first
      orderDoc = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('orders')
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        final data = orderDoc.data() as Map<String, dynamic>;
        final paymentStatus = data['paymentStatus'] as String?;
        if (paymentStatus != null) {
          return PaymentStatus.values.firstWhere(
            (status) => status.name == paymentStatus,
            orElse: () => PaymentStatus.pending,
          );
        }
      }

      return PaymentStatus.pending;
    } catch (e) {
      print('Error getting payment status: $e');
      return PaymentStatus.pending;
    }
  }

  /// Refund payment
  Future<bool> refundPayment(String paymentId, String reason) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': PaymentStatus.refunded.name,
        'refundReason': reason,
        'refundedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Get payment details to find the order
      final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();
      if (paymentDoc.exists) {
        final data = paymentDoc.data() as Map<String, dynamic>;
        final orderId = data['orderId'] as String?;
        final tenantId = data['tenantId'] as String?;
        final tableId = data['tableId'] as String?;

        if (orderId != null && tenantId != null) {
          // Update order status to refunded
          await _updateOrderPaymentStatus(
            orderId,
            tenantId,
            PaymentStatus.refunded,
            paymentId,
            tableId,
          );
        }
      }

      return true;
    } catch (e) {
      print('Error refunding payment: $e');
      return false;
    }
  }

  /// Cancel payment
  Future<bool> cancelPayment(String paymentId, String reason) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': PaymentStatus.cancelled.name,
        'cancellationReason': reason,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
      });

      // Get payment details to find the order
      final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();
      if (paymentDoc.exists) {
        final data = paymentDoc.data() as Map<String, dynamic>;
        final orderId = data['orderId'] as String?;
        final tenantId = data['tenantId'] as String?;
        final tableId = data['tableId'] as String?;

        if (orderId != null && tenantId != null) {
          // Update order status to cancelled
          await _updateOrderPaymentStatus(
            orderId,
            tenantId,
            PaymentStatus.cancelled,
            paymentId,
            tableId,
          );
        }
      }

      return true;
    } catch (e) {
      print('Error cancelling payment: $e');
      return false;
    }
  }

  /// Get payment history for a customer
  Stream<List<Map<String, dynamic>>> getPaymentHistory(String tenantId, String? customerId) {
    return _firestore
        .collection('payments')
        .where('tenantId', isEqualTo: tenantId)
        .where('customerId', isEqualTo: customerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
