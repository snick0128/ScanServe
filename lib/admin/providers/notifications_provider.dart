import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../services/bill_request_service.dart';
import '../../services/waiter_call_service.dart';
import '../../models/bill_request_model.dart';

class NotificationsProvider with ChangeNotifier {
  final BillRequestService _billRequestService = BillRequestService();
  final WaiterCallService _waiterCallService = WaiterCallService();
  
  List<BillRequest> _billRequests = [];
  List<WaiterCall> _waiterCalls = [];
  String? _tenantId;
  StreamSubscription? _billRequestsSubscription;
  StreamSubscription? _waiterCallsSubscription;

  List<BillRequest> get billRequests => _billRequests;
  List<WaiterCall> get waiterCalls => _waiterCalls;
  int get pendingBillRequestsCount => _billRequests.where((r) => r.status == BillRequestStatus.pending).length;
  int get pendingWaiterCallsCount => _waiterCalls.where((c) => c.status == 'pending').length;
  int get totalNotificationsCount => pendingBillRequestsCount + pendingWaiterCallsCount;

  void initialize(String tenantId) {
    if (_tenantId == tenantId) return;
    
    print('🔔 NotificationsProvider: Initializing for tenant $tenantId');
    _billRequestsSubscription?.cancel();
    _waiterCallsSubscription?.cancel();
    _tenantId = tenantId;

    // Listen to pending bill requests
    _billRequestsSubscription = _billRequestService
        .getPendingBillRequests(tenantId)
        .listen((requests) {
      print('🔔 NotificationsProvider: Received ${requests.length} pending bill requests');
      _billRequests = requests;
      notifyListeners();
    }, onError: (e) {
      print('❌ NotificationsProvider: Error in bill requests stream: $e');
    });

    // Listen to pending waiter calls
    _waiterCallsSubscription = _waiterCallService
        .getPendingWaiterCalls(tenantId)
        .listen((calls) {
      print('🔔 NotificationsProvider: Received ${calls.length} pending waiter calls');
      _waiterCalls = calls;
      notifyListeners();
    }, onError: (e) {
      print('❌ NotificationsProvider: Error in waiter calls stream: $e');
    });
  }

  Future<void> acknowledgeBillRequest(String requestId) async {
    if (_tenantId == null) return;
    await _billRequestService.updateBillRequestStatus(
      tenantId: _tenantId!,
      requestId: requestId,
      status: BillRequestStatus.processing,
    );
  }

  Future<void> completeBillRequest(String requestId) async {
    if (_tenantId == null) return;
    await _billRequestService.completeBillRequest(
      tenantId: _tenantId!,
      requestId: requestId,
    );
  }

  Future<void> acknowledgeWaiterCall(String callId) async {
    if (_tenantId == null) return;
    await _waiterCallService.acknowledgeWaiterCall(
      tenantId: _tenantId!,
      callId: callId,
    );
  }

  Future<void> completeWaiterCall(String callId) async {
    if (_tenantId == null) return;
    await _waiterCallService.completeWaiterCall(
      tenantId: _tenantId!,
      callId: callId,
    );
  }

  @override
  void dispose() {
    _billRequestsSubscription?.cancel();
    _waiterCallsSubscription?.cancel();
    super.dispose();
  }
}
