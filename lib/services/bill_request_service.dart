import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_request_model.dart';

/// Bill Request Service
/// 
/// Manages bill requests from customers to admin.
/// Customers can request a bill, and admin receives real-time notifications.
class BillRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Create a new bill request
  /// 
  /// This notifies the admin that a customer wants to pay and leave.
  /// The request is stored in Firestore and can be monitored in real-time.
  Future<String> createBillRequest({
    required String tenantId,
    required String guestId,
    required String customerName,
    String? customerPhone,
    String? tableId,
    String? tableName,
    List<String> orderIds = const [],
    String? notes,
  }) async {
    try {
      final requestId = _uuid.v4();
      
      final billRequest = BillRequest(
        requestId: requestId,
        tenantId: tenantId,
        tableId: tableId,
        tableName: tableName,
        guestId: guestId,
        customerName: customerName,
        customerPhone: customerPhone,
        requestedAt: DateTime.now(),
        status: BillRequestStatus.pending,
        orderIds: orderIds,
        notes: notes,
      );

      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('billRequests')
          .doc(requestId)
          .set(billRequest.toMap());

      // Update table status to 'billRequested' if tableId is provided
      if (tableId != null) {
        try {
          await _firestore
              .collection('tenants')
              .doc(tenantId)
              .collection('tables')
              .doc(tableId)
              .update({'status': 'billRequested'});
          print('📋 Table $tableId status updated to billRequested');
        } catch (e) {
          print('⚠️ Error updating table status: $e');
        }
      }

      print('📝 Bill request created: $requestId for $customerName');
      return requestId;
    } catch (e) {
      print('❌ Error creating bill request: $e');
      rethrow;
    }
  }

  /// Get all bill requests for a tenant (real-time stream)
  /// 
  /// Admin can listen to this stream to receive notifications
  /// when customers request bills.
  Stream<List<BillRequest>> getBillRequests(String tenantId) {
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('billRequests')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BillRequest.fromMap(doc.data()))
          .toList();
    });
  }

  /// Get pending bill requests only
  Stream<List<BillRequest>> getPendingBillRequests(String tenantId) {
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('billRequests')
        .where('status', isEqualTo: BillRequestStatus.pending.name)
        .orderBy('requestedAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BillRequest.fromMap(doc.data()))
          .toList();
    });
  }

  /// Get a specific bill request
  Future<BillRequest?> getBillRequest(String tenantId, String requestId) async {
    try {
      final doc = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('billRequests')
          .doc(requestId)
          .get();

      if (!doc.exists) return null;
      return BillRequest.fromMap(doc.data()!);
    } catch (e) {
      print('❌ Error fetching bill request: $e');
      return null;
    }
  }

  /// Update bill request status
  /// 
  /// Admin can mark requests as processing, completed, or cancelled.
  Future<void> updateBillRequestStatus({
    required String tenantId,
    required String requestId,
    required BillRequestStatus status,
  }) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('billRequests')
          .doc(requestId)
          .update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Bill request $requestId updated to ${status.displayName}');
    } catch (e) {
      print('❌ Error updating bill request status: $e');
      rethrow;
    }
  }

  /// Mark bill request as completed
  Future<void> completeBillRequest({
    required String tenantId,
    required String requestId,
  }) async {
    await updateBillRequestStatus(
      tenantId: tenantId,
      requestId: requestId,
      status: BillRequestStatus.completed,
    );
  }

  /// Delete a bill request
  Future<void> deleteBillRequest({
    required String tenantId,
    required String requestId,
  }) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('billRequests')
          .doc(requestId)
          .delete();

      print('🗑️ Bill request deleted: $requestId');
    } catch (e) {
      print('❌ Error deleting bill request: $e');
      rethrow;
    }
  }

  /// Get bill requests for a specific guest
  Stream<List<BillRequest>> getGuestBillRequests({
    required String tenantId,
    required String guestId,
  }) {
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('billRequests')
        .where('guestId', isEqualTo: guestId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BillRequest.fromMap(doc.data()))
          .toList();
    });
  }

  /// Check if guest has a pending bill request
  Future<bool> hasPendingBillRequest({
    required String tenantId,
    required String guestId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('billRequests')
          .where('guestId', isEqualTo: guestId)
          .where('status', isEqualTo: BillRequestStatus.pending.name)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking pending bill request: $e');
      return false;
    }
  }
}
