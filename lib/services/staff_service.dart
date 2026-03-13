import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../models/staff_profile.dart';
import '../models/staff_attendance.dart';
import '../models/staff_shift.dart';
import '../models/staff_task.dart';
import '../models/staff_payment.dart';
import '../models/staff_notification.dart';

class StaffService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _staffAuthAppName = 'staffAuth';

  Future<FirebaseAuth> _getStaffAuth() async {
    try {
      final existing = Firebase.apps.where(
        (app) => app.name == _staffAuthAppName,
      );
      final app = existing.isNotEmpty
          ? existing.first
          : await Firebase.initializeApp(
              name: _staffAuthAppName,
              options: DefaultFirebaseOptions.currentPlatform,
            );
      return FirebaseAuth.instanceFor(app: app);
    } catch (_) {
      return FirebaseAuth.instance;
    }
  }

  CollectionReference<Map<String, dynamic>> _staffCollection(String tenantId) =>
      _firestore.collection('tenants').doc(tenantId).collection('staff');

  CollectionReference<Map<String, dynamic>> _attendanceCollection(
    String tenantId,
  ) => _firestore
      .collection('tenants')
      .doc(tenantId)
      .collection('staffAttendance');

  CollectionReference<Map<String, dynamic>> _shiftCollection(String tenantId) =>
      _firestore.collection('tenants').doc(tenantId).collection('staffShifts');

  CollectionReference<Map<String, dynamic>> _taskCollection(String tenantId) =>
      _firestore.collection('tenants').doc(tenantId).collection('staffTasks');

  CollectionReference<Map<String, dynamic>> _paymentCollection(
    String tenantId,
  ) => _firestore
      .collection('tenants')
      .doc(tenantId)
      .collection('staffPayments');

  CollectionReference<Map<String, dynamic>> _notificationCollection(
    String tenantId,
  ) => _firestore
      .collection('tenants')
      .doc(tenantId)
      .collection('staffNotifications');

  Stream<List<StaffProfile>> watchStaff(String tenantId) {
    return _staffCollection(tenantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StaffProfile.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addStaff(String tenantId, StaffProfile staff) async {
    final doc = _staffCollection(tenantId).doc();
    await doc.set(staff.copyWith(id: doc.id).toMap());
  }

  Future<String> createStaffLogin({
    required String tenantId,
    required String tenantName,
    required String name,
    required String role,
    required String email,
    required String password,
  }) async {
    final auth = await _getStaffAuth();
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user?.uid;
    if (uid == null) {
      throw Exception('Unable to create user');
    }

    await _firestore.collection('users').doc(uid).set({
      'role': role,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      await auth.signOut();
    } catch (_) {}

    return uid;
  }

  Future<void> updateStaff(String tenantId, StaffProfile staff) async {
    await _staffCollection(tenantId).doc(staff.id).update({
      ...staff.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setStaffActive(
    String tenantId,
    String staffId,
    bool isActive,
  ) async {
    await _staffCollection(tenantId).doc(staffId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<StaffAttendance>> watchAttendance(String tenantId) {
    return _attendanceCollection(tenantId)
        .orderBy('clockInAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StaffAttendance.fromFirestore(doc))
              .toList(),
        );
  }

  Future<StaffAttendance?> getOpenAttendance(
    String tenantId,
    String staffId,
  ) async {
    final query = await _attendanceCollection(tenantId)
        .where('staffId', isEqualTo: staffId)
        .where('clockOutAt', isNull: true)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return StaffAttendance.fromFirestore(query.docs.first);
  }

  Future<void> clockIn(String tenantId, StaffAttendance attendance) async {
    final doc = _attendanceCollection(tenantId).doc();
    await doc.set(attendance.toMap());
  }

  Future<void> clockOut(String tenantId, StaffAttendance attendance) async {
    await _attendanceCollection(
      tenantId,
    ).doc(attendance.id).update(attendance.toMap());
  }

  Stream<List<StaffShift>> watchShifts(String tenantId) {
    return _shiftCollection(tenantId)
        .orderBy('date', descending: false)
        .limit(200)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StaffShift.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addShift(String tenantId, StaffShift shift) async {
    final doc = _shiftCollection(tenantId).doc();
    await doc.set(shift.toMap());
  }

  Stream<List<StaffTask>> watchTasks(String tenantId) {
    return _taskCollection(tenantId)
        .orderBy('createdAt', descending: true)
        .limit(300)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => StaffTask.fromFirestore(doc)).toList(),
        );
  }

  Future<void> addTask(String tenantId, StaffTask task) async {
    final doc = _taskCollection(tenantId).doc();
    await doc.set(task.toMap());
  }

  Future<void> updateTaskStatus(
    String tenantId,
    String taskId,
    String status,
  ) async {
    await _taskCollection(tenantId).doc(taskId).update({'status': status});
  }

  Stream<List<StaffPayment>> watchPayments(String tenantId) {
    return _paymentCollection(tenantId)
        .orderBy('paidAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StaffPayment.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addPayment(String tenantId, StaffPayment payment) async {
    final doc = _paymentCollection(tenantId).doc();
    await doc.set(payment.toMap());
  }

  Stream<List<StaffNotification>> watchNotifications(String tenantId) {
    return _notificationCollection(tenantId)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StaffNotification.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addNotification(
    String tenantId,
    StaffNotification notification,
  ) async {
    final doc = _notificationCollection(tenantId).doc();
    await doc.set(notification.toMap());
  }
}
