import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseOrderItem {
  final String itemId;
  final String name;
  final String unit;
  final double quantity;
  final double unitPrice;

  PurchaseOrderItem({
    required this.itemId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> data) {
    return PurchaseOrderItem(
      itemId: data['itemId'] ?? '',
      name: data['name'] ?? '',
      unit: data['unit'] ?? 'pcs',
      quantity: (data['quantity'] ?? 0).toDouble(),
      unitPrice: (data['unitPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }
}

class PurchaseOrder {
  final String id;
  final String vendorId;
  final String vendorName;
  final String status; // draft | sent | received | closed
  final List<PurchaseOrderItem> items;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? expectedAt;
  final DateTime? receivedAt;
  final String? notes;

  PurchaseOrder({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    this.expectedAt,
    this.receivedAt,
    this.notes,
  });

  PurchaseOrder copyWith({
    String? id,
    String? vendorId,
    String? vendorName,
    String? status,
    List<PurchaseOrderItem>? items,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? expectedAt,
    DateTime? receivedAt,
    String? notes,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      status: status ?? this.status,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      expectedAt: expectedAt ?? this.expectedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      notes: notes ?? this.notes,
    );
  }

  factory PurchaseOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return PurchaseOrder(
      id: doc.id,
      vendorId: data['vendorId'] ?? '',
      vendorName: data['vendorName'] ?? '',
      status: data['status'] ?? 'draft',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((i) => PurchaseOrderItem.fromMap(Map<String, dynamic>.from(i)))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      createdAt: parseDate(data['createdAt']),
      expectedAt: data['expectedAt'] != null
          ? parseDate(data['expectedAt'])
          : null,
      receivedAt: data['receivedAt'] != null
          ? parseDate(data['receivedAt'])
          : null,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'status': status,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      if (expectedAt != null) 'expectedAt': Timestamp.fromDate(expectedAt!),
      if (receivedAt != null) 'receivedAt': Timestamp.fromDate(receivedAt!),
      if (notes != null) 'notes': notes,
    };
  }
}
