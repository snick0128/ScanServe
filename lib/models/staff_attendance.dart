import 'package:cloud_firestore/cloud_firestore.dart';

class StaffAttendance {
  final String id;
  final String staffId;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final int? totalMinutes;
  final String status; // on_time | late
  final DateTime? shiftStart;
  final DateTime? shiftEnd;
  final String? shiftId;

  const StaffAttendance({
    required this.id,
    required this.staffId,
    required this.clockInAt,
    this.clockOutAt,
    this.totalMinutes,
    this.status = 'on_time',
    this.shiftStart,
    this.shiftEnd,
    this.shiftId,
  });

  factory StaffAttendance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return StaffAttendance(
      id: doc.id,
      staffId: data['staffId'] ?? '',
      clockInAt: parseDate(data['clockInAt']),
      clockOutAt: data['clockOutAt'] != null
          ? parseDate(data['clockOutAt'])
          : null,
      totalMinutes: (data['totalMinutes'] as num?)?.toInt(),
      status: data['status'] ?? 'on_time',
      shiftStart: data['shiftStart'] != null
          ? parseDate(data['shiftStart'])
          : null,
      shiftEnd: data['shiftEnd'] != null ? parseDate(data['shiftEnd']) : null,
      shiftId: data['shiftId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'staffId': staffId,
      'clockInAt': Timestamp.fromDate(clockInAt),
      if (clockOutAt != null) 'clockOutAt': Timestamp.fromDate(clockOutAt!),
      if (totalMinutes != null) 'totalMinutes': totalMinutes,
      'status': status,
      if (shiftStart != null) 'shiftStart': Timestamp.fromDate(shiftStart!),
      if (shiftEnd != null) 'shiftEnd': Timestamp.fromDate(shiftEnd!),
      if (shiftId != null) 'shiftId': shiftId,
    };
  }
}
