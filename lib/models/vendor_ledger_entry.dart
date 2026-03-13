import 'package:cloud_firestore/cloud_firestore.dart';

class VendorLedgerEntry {
  final String id;
  final String vendorId;
  final String type; // debit | credit
  final double amount;
  final String? referenceId; // PO ID or payment ref
  final String note;
  final DateTime createdAt;

  VendorLedgerEntry({
    required this.id,
    required this.vendorId,
    required this.type,
    required this.amount,
    this.referenceId,
    required this.note,
    required this.createdAt,
  });

  factory VendorLedgerEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return VendorLedgerEntry(
      id: doc.id,
      vendorId: data['vendorId'] ?? '',
      type: data['type'] ?? 'debit',
      amount: (data['amount'] ?? 0).toDouble(),
      referenceId: data['referenceId'],
      note: data['note'] ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'type': type,
      'amount': amount,
      if (referenceId != null) 'referenceId': referenceId,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
