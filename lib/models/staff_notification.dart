import 'package:cloud_firestore/cloud_firestore.dart';

class StaffNotification {
  final String id;
  final String? staffId; // null for broadcast
  final String title;
  final String message;
  final String type; // task | payment | shift | general
  final DateTime createdAt;
  final bool read;

  const StaffNotification({
    required this.id,
    this.staffId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.read = false,
  });

  factory StaffNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return StaffNotification(
      id: doc.id,
      staffId: data['staffId'],
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? '',
      type: data['type'] ?? 'general',
      createdAt: parseDate(data['createdAt']),
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (staffId != null) 'staffId': staffId,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
    };
  }
}
