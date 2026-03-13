import 'package:cloud_firestore/cloud_firestore.dart';

class StaffPayment {
  final String id;
  final String staffId;
  final double amount;
  final String type; // advance | weekly | monthly
  final DateTime paidAt;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? note;

  const StaffPayment({
    required this.id,
    required this.staffId,
    required this.amount,
    required this.type,
    required this.paidAt,
    this.periodStart,
    this.periodEnd,
    this.note,
  });

  factory StaffPayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return StaffPayment(
      id: doc.id,
      staffId: data['staffId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      type: data['type'] ?? 'advance',
      paidAt: parseDate(data['paidAt']),
      periodStart: data['periodStart'] != null
          ? parseDate(data['periodStart'])
          : null,
      periodEnd: data['periodEnd'] != null
          ? parseDate(data['periodEnd'])
          : null,
      note: data['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'staffId': staffId,
      'amount': amount,
      'type': type,
      'paidAt': Timestamp.fromDate(paidAt),
      if (periodStart != null) 'periodStart': Timestamp.fromDate(periodStart!),
      if (periodEnd != null) 'periodEnd': Timestamp.fromDate(periodEnd!),
      if (note != null) 'note': note,
    };
  }
}
