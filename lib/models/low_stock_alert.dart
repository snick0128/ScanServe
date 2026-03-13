import 'package:cloud_firestore/cloud_firestore.dart';

class LowStockAlert {
  final String id;
  final String itemId;
  final String itemName;
  final String status; // low | out
  final double currentStock;
  final String unit;
  final bool acknowledged;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final bool whatsappSent;

  LowStockAlert({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.status,
    required this.currentStock,
    required this.unit,
    required this.acknowledged,
    required this.createdAt,
    this.acknowledgedAt,
    this.whatsappSent = false,
  });

  factory LowStockAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return LowStockAlert(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      itemName: data['itemName'] ?? '',
      status: data['status'] ?? 'low',
      currentStock: (data['currentStock'] ?? 0).toDouble(),
      unit: data['unit'] ?? 'pcs',
      acknowledged: data['acknowledged'] ?? false,
      createdAt: parseDate(data['createdAt']),
      acknowledgedAt: data['acknowledgedAt'] != null
          ? parseDate(data['acknowledgedAt'])
          : null,
      whatsappSent: data['whatsappSent'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'status': status,
      'currentStock': currentStock,
      'unit': unit,
      'acknowledged': acknowledged,
      'createdAt': Timestamp.fromDate(createdAt),
      if (acknowledgedAt != null)
        'acknowledgedAt': Timestamp.fromDate(acknowledgedAt!),
      'whatsappSent': whatsappSent,
    };
  }
}
