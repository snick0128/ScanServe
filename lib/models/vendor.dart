import 'package:cloud_firestore/cloud_firestore.dart';

class Vendor {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstin;
  final double openingBalance;
  final double currentBalance;
  final DateTime createdAt;

  Vendor({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.gstin,
    this.openingBalance = 0,
    this.currentBalance = 0,
    required this.createdAt,
  });

  factory Vendor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return Vendor(
      id: doc.id,
      name: data['name'] ?? 'Vendor',
      phone: data['phone'],
      email: data['email'],
      address: data['address'],
      gstin: data['gstin'],
      openingBalance: (data['openingBalance'] ?? 0).toDouble(),
      currentBalance: (data['currentBalance'] ?? 0).toDouble(),
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (gstin != null) 'gstin': gstin,
      'openingBalance': openingBalance,
      'currentBalance': currentBalance,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Vendor copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? gstin,
    double? openingBalance,
    double? currentBalance,
    DateTime? createdAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
