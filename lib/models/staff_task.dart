import 'package:cloud_firestore/cloud_firestore.dart';

class StaffTask {
  final String id;
  final String staffId;
  final String title;
  final String? description;
  final String? orderId;
  final String priority; // normal | urgent
  final String status; // assigned | in_progress | done
  final DateTime createdAt;
  final DateTime? dueAt;

  const StaffTask({
    required this.id,
    required this.staffId,
    required this.title,
    this.description,
    this.orderId,
    this.priority = 'normal',
    this.status = 'assigned',
    required this.createdAt,
    this.dueAt,
  });

  factory StaffTask.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return StaffTask(
      id: doc.id,
      staffId: data['staffId'] ?? '',
      title: data['title'] ?? 'Task',
      description: data['description'],
      orderId: data['orderId'],
      priority: data['priority'] ?? 'normal',
      status: data['status'] ?? 'assigned',
      createdAt: parseDate(data['createdAt']),
      dueAt: data['dueAt'] != null ? parseDate(data['dueAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'staffId': staffId,
      'title': title,
      if (description != null) 'description': description,
      if (orderId != null) 'orderId': orderId,
      'priority': priority,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (dueAt != null) 'dueAt': Timestamp.fromDate(dueAt!),
    };
  }
}
