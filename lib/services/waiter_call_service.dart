import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Waiter Call Model
class WaiterCall {
  final String callId;
  final String tenantId;
  final String? tableId;
  final String? tableName;
  final String guestId;
  final String? customerName;
  final DateTime requestedAt;
  final String status; // 'pending', 'acknowledged', 'completed'
  final String? notes;

  WaiterCall({
    required this.callId,
    required this.tenantId,
    this.tableId,
    this.tableName,
    required this.guestId,
    this.customerName,
    required this.requestedAt,
    this.status = 'pending',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'tenantId': tenantId,
      'tableId': tableId,
      'tableName': tableName,
      'guestId': guestId,
      'customerName': customerName,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': status,
      'notes': notes,
    };
  }

  factory WaiterCall.fromMap(Map<String, dynamic> map) {
    return WaiterCall(
      callId: map['callId'] ?? '',
      tenantId: map['tenantId'] ?? '',
      tableId: map['tableId'],
      tableName: map['tableName'],
      guestId: map['guestId'] ?? '',
      customerName: map['customerName'],
      requestedAt: (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
    );
  }
}

/// Waiter Call Service
class WaiterCallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Create a waiter call request
  Future<String> createWaiterCall({
    required String tenantId,
    required String guestId,
    String? tableId,
    String? tableName,
    String? customerName,
    String? notes,
  }) async {
    try {
      final callId = _uuid.v4();
      
      final waiterCall = WaiterCall(
        callId: callId,
        tenantId: tenantId,
        tableId: tableId,
        tableName: tableName,
        guestId: guestId,
        customerName: customerName,
        requestedAt: DateTime.now(),
        status: 'pending',
        notes: notes,
      );

      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('waiterCalls')
          .doc(callId)
          .set(waiterCall.toMap());

      print('🔔 Waiter call created: $callId for table $tableName');
      return callId;
    } catch (e) {
      print('❌ Error creating waiter call: $e');
      rethrow;
    }
  }

  /// Get pending waiter calls (real-time stream)
  Stream<List<WaiterCall>> getPendingWaiterCalls(String tenantId) {
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('waiterCalls')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WaiterCall.fromMap(doc.data()))
          .toList();
    });
  }

  /// Acknowledge waiter call
  Future<void> acknowledgeWaiterCall({
    required String tenantId,
    required String callId,
  }) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('waiterCalls')
          .doc(callId)
          .update({
        'status': 'acknowledged',
        'acknowledgedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Waiter call acknowledged: $callId');
    } catch (e) {
      print('❌ Error acknowledging waiter call: $e');
      rethrow;
    }
  }

  /// Complete waiter call
  Future<void> completeWaiterCall({
    required String tenantId,
    required String callId,
  }) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('waiterCalls')
          .doc(callId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Waiter call completed: $callId');
    } catch (e) {
      print('❌ Error completing waiter call: $e');
      rethrow;
    }
  }

  /// Delete waiter call
  Future<void> deleteWaiterCall({
    required String tenantId,
    required String callId,
  }) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('waiterCalls')
          .doc(callId)
          .delete();

      print('🗑️ Waiter call deleted: $callId');
    } catch (e) {
      print('❌ Error deleting waiter call: $e');
      rethrow;
    }
  }
}
