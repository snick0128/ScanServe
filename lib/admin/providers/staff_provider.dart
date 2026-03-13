import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/staff_profile.dart';
import '../../models/staff_attendance.dart';
import '../../models/staff_shift.dart';
import '../../models/staff_task.dart';
import '../../models/staff_payment.dart';
import '../../models/staff_notification.dart';
import '../../services/staff_service.dart';
import './admin_auth_provider.dart';
import './orders_provider.dart';
import '../../models/order.dart' as model;

class StaffProvider with ChangeNotifier {
  final StaffService _service = StaffService();
  String? _tenantId;
  AdminAuthProvider? _auth;
  OrdersProvider? _orders;

  List<StaffProfile> _staff = [];
  List<StaffAttendance> _attendance = [];
  List<StaffShift> _shifts = [];
  List<StaffTask> _tasks = [];
  List<StaffPayment> _payments = [];
  List<StaffNotification> _notifications = [];

  bool _isLoading = false;
  String? _error;

  StreamSubscription? _staffSub;
  StreamSubscription? _attendanceSub;
  StreamSubscription? _shiftSub;
  StreamSubscription? _taskSub;
  StreamSubscription? _paymentSub;
  StreamSubscription? _notificationSub;

  bool _selfEnsured = false;
  StaffProfile? _selfStaff;

  List<StaffProfile> get staff => _staff;
  List<StaffAttendance> get attendance => _attendance;
  List<StaffShift> get shifts => _shifts;
  List<StaffTask> get tasks => _tasks;
  List<StaffPayment> get payments => _payments;
  List<StaffNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  StaffProfile? get selfStaff => _selfStaff;

  void initialize(
    String tenantId, {
    AdminAuthProvider? auth,
    OrdersProvider? orders,
  }) {
    if (_tenantId == tenantId && _auth == auth && _orders == orders) return;

    _tenantId = tenantId;
    _auth = auth;
    _orders = orders;
    _selfEnsured = false;
    _selfStaff = null;
    _isLoading = true;
    notifyListeners();

    _disposeStreams();
    _listen();
  }

  void _listen() {
    if (_tenantId == null) return;

    _staffSub = _service
        .watchStaff(_tenantId!)
        .listen(
          (items) {
            _staff = items;
            _selfStaff = _resolveSelfStaff();
            if (_auth?.isCaptain == true) {
              _ensureSelfStaff();
            }
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _isLoading = false;
            notifyListeners();
          },
        );

    _attendanceSub = _service.watchAttendance(_tenantId!).listen((items) {
      _attendance = items;
      notifyListeners();
    });

    _shiftSub = _service.watchShifts(_tenantId!).listen((items) {
      _shifts = items;
      notifyListeners();
    });

    _taskSub = _service.watchTasks(_tenantId!).listen((items) {
      _tasks = items;
      notifyListeners();
    });

    _paymentSub = _service.watchPayments(_tenantId!).listen((items) {
      _payments = items;
      notifyListeners();
    });

    _notificationSub = _service.watchNotifications(_tenantId!).listen((items) {
      _notifications = items;
      notifyListeners();
    });
  }

  void _disposeStreams() {
    _staffSub?.cancel();
    _attendanceSub?.cancel();
    _shiftSub?.cancel();
    _taskSub?.cancel();
    _paymentSub?.cancel();
    _notificationSub?.cancel();
  }

  StaffProfile? _resolveSelfStaff() {
    final uid = _auth?.user?.uid;
    final email = _auth?.user?.email?.toLowerCase().trim();
    if (uid == null) return null;
    try {
      return _staff.firstWhere((s) => s.userId == uid);
    } catch (_) {
      if (email == null || email.isEmpty) return null;
      try {
        return _staff.firstWhere(
          (s) => (s.email ?? '').toLowerCase().trim() == email,
        );
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _ensureSelfStaff() async {
    if (_selfEnsured || _tenantId == null || _auth == null) return;
    _selfEnsured = true;

    final uid = _auth!.user?.uid;
    if (uid == null) return;

    final existing = _staff.where((s) => s.userId == uid).toList();
    if (existing.isNotEmpty) return;

    final name = _auth!.displayName ?? 'Captain';
    final email = _auth!.user?.email;
    final now = DateTime.now();
    final staff = StaffProfile(
      id: '',
      name: name,
      email: email,
      contact: '',
      role: 'captain',
      employeeId: uid.substring(0, 8).toUpperCase(),
      shiftSchedule: 'As assigned',
      baseSalary: 0,
      payCycle: 'monthly',
      userId: uid,
      isActive: true,
      createdAt: now,
      rating: 0,
    );
    await _service.addStaff(_tenantId!, staff);
  }

  Future<void> addOrUpdateStaff(StaffProfile staff) async {
    if (_tenantId == null) return;
    if (staff.id.isEmpty) {
      await _service.addStaff(_tenantId!, staff);
    } else {
      await _service.updateStaff(_tenantId!, staff);
    }
  }

  Future<void> addStaffWithLogin({
    required StaffProfile staff,
    required String email,
    required String password,
  }) async {
    if (_tenantId == null || _auth == null) return;
    final tenantName = _auth!.tenantName ?? 'Tenant';
    final uid = await _service.createStaffLogin(
      tenantId: _tenantId!,
      tenantName: tenantName,
      name: staff.name,
      role: staff.role,
      email: email,
      password: password,
    );
    await _service.addStaff(
      _tenantId!,
      staff.copyWith(userId: uid, email: email),
    );
  }

  Future<void> setStaffActive(String staffId, bool isActive) async {
    if (_tenantId == null) return;
    await _service.setStaffActive(_tenantId!, staffId, isActive);
  }

  StaffShift? _findShiftForStaffToday(String staffId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final shift in _shifts) {
      final sDay = DateTime(shift.date.year, shift.date.month, shift.date.day);
      if (shift.staffId == staffId && sDay == today) return shift;
    }
    return null;
  }

  Future<void> clockIn(String staffId) async {
    if (_tenantId == null) return;
    final open = await _service.getOpenAttendance(_tenantId!, staffId);
    if (open != null) {
      throw Exception('Already clocked in');
    }
    final now = DateTime.now();
    final shift = _findShiftForStaffToday(staffId);
    final lateThreshold = shift?.startTime.add(const Duration(minutes: 10));
    final status = (lateThreshold != null && now.isAfter(lateThreshold))
        ? 'late'
        : 'on_time';

    final attendance = StaffAttendance(
      id: '',
      staffId: staffId,
      clockInAt: now,
      status: status,
      shiftStart: shift?.startTime,
      shiftEnd: shift?.endTime,
      shiftId: shift?.id,
    );
    await _service.clockIn(_tenantId!, attendance);
  }

  Future<void> clockOut(String staffId) async {
    if (_tenantId == null) return;
    final open = await _service.getOpenAttendance(_tenantId!, staffId);
    if (open == null) {
      throw Exception('No active shift found');
    }
    final now = DateTime.now();
    final minutes = now.difference(open.clockInAt).inMinutes;
    final updated = StaffAttendance(
      id: open.id,
      staffId: open.staffId,
      clockInAt: open.clockInAt,
      clockOutAt: now,
      totalMinutes: minutes < 0 ? 0 : minutes,
      status: open.status,
      shiftStart: open.shiftStart,
      shiftEnd: open.shiftEnd,
      shiftId: open.shiftId,
    );
    await _service.clockOut(_tenantId!, updated);
  }

  Future<void> addShift(StaffShift shift) async {
    if (_tenantId == null) return;
    await _service.addShift(_tenantId!, shift);
  }

  Future<void> addTask(StaffTask task) async {
    if (_tenantId == null) return;
    await _service.addTask(_tenantId!, task);
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    if (_tenantId == null) return;
    await _service.updateTaskStatus(_tenantId!, taskId, status);
  }

  Future<void> addPayment(StaffPayment payment) async {
    if (_tenantId == null) return;
    await _service.addPayment(_tenantId!, payment);
  }

  Future<void> addNotification(StaffNotification notification) async {
    if (_tenantId == null) return;
    await _service.addNotification(_tenantId!, notification);
  }

  List<StaffTask> tasksForStaff(String staffId) {
    return _tasks.where((t) => t.staffId == staffId).toList();
  }

  List<StaffAttendance> attendanceForStaff(String staffId) {
    return _attendance.where((a) => a.staffId == staffId).toList();
  }

  List<StaffPayment> paymentsForStaff(String staffId) {
    return _payments.where((p) => p.staffId == staffId).toList();
  }

  double paidForPeriod(String staffId, Duration period) {
    final cutoff = DateTime.now().subtract(period);
    return _payments
        .where((p) => p.staffId == staffId && p.paidAt.isAfter(cutoff))
        .fold<double>(0, (sum, p) => sum + p.amount);
  }

  double remainingSalary(StaffProfile staff) {
    final period = staff.payCycle == 'weekly'
        ? const Duration(days: 7)
        : const Duration(days: 30);
    final paid = paidForPeriod(staff.id, period);
    final remaining = staff.baseSalary - paid;
    return remaining < 0 ? 0 : remaining;
  }

  String formatHours(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  Map<String, dynamic> performanceForStaff(StaffProfile staff) {
    if (_orders == null) {
      return {'orders': 0, 'revenue': 0.0};
    }

    final captainKey = staff.userId ?? staff.id;
    final allOrders = [..._orders!.orders, ..._orders!.pastOrders];
    final served = allOrders.where((o) {
      final matchesCaptain =
          (o.captainId != null && o.captainId == captainKey) ||
          (o.captainName != null &&
              o.captainName!.toLowerCase() == staff.name.toLowerCase());
      if (!matchesCaptain) return false;
      return o.status == model.OrderStatus.served ||
          o.status == model.OrderStatus.completed;
    });
    final revenue = served.fold<double>(0, (sum, o) => sum + o.total);
    return {'orders': served.length, 'revenue': revenue};
  }

  List<StaffAttendance> lateArrivals() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _attendance.where((a) {
      final day = DateTime(
        a.clockInAt.year,
        a.clockInAt.month,
        a.clockInAt.day,
      );
      return a.status == 'late' && day == today;
    }).toList();
  }

  @override
  void dispose() {
    _disposeStreams();
    super.dispose();
  }
}
