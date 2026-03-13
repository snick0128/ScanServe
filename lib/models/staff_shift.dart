import 'package:cloud_firestore/cloud_firestore.dart';

class StaffShift {
  final String id;
  final String staffId;
  final DateTime date; // day start
  final DateTime startTime;
  final DateTime endTime;
  final String status; // assigned | completed | cancelled
  final String? note;

  const StaffShift({
    required this.id,
    required this.staffId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = 'assigned',
    this.note,
  });

  factory StaffShift.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return StaffShift(
      id: doc.id,
      staffId: data['staffId'] ?? '',
      date: parseDate(data['date']),
      startTime: parseDate(data['startTime']),
      endTime: parseDate(data['endTime']),
      status: data['status'] ?? 'assigned',
      note: data['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'staffId': staffId,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status,
      if (note != null) 'note': note,
    };
  }
}
