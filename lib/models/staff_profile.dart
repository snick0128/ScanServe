import 'package:cloud_firestore/cloud_firestore.dart';

class StaffProfile {
  final String id;
  final String name;
  final String? photoUrl;
  final String? email;
  final String contact;
  final String role;
  final String employeeId;
  final String? shiftSchedule;
  final double baseSalary;
  final String payCycle; // weekly | monthly
  final String? userId;
  final bool isActive;
  final double rating;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const StaffProfile({
    required this.id,
    required this.name,
    this.photoUrl,
    this.email,
    required this.contact,
    required this.role,
    required this.employeeId,
    this.shiftSchedule,
    required this.baseSalary,
    required this.payCycle,
    this.userId,
    this.isActive = true,
    this.rating = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory StaffProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return StaffProfile(
      id: doc.id,
      name: data['name'] ?? 'Unnamed',
      photoUrl: data['photoUrl'],
      email: data['email'],
      contact: data['contact'] ?? '',
      role: data['role'] ?? 'staff',
      employeeId: data['employeeId'] ?? doc.id,
      shiftSchedule: data['shiftSchedule'],
      baseSalary: (data['baseSalary'] ?? 0).toDouble(),
      payCycle: data['payCycle'] ?? 'monthly',
      userId: data['userId'],
      isActive: data['isActive'] ?? true,
      rating: (data['rating'] ?? 0).toDouble(),
      createdAt: parseDate(data['createdAt']),
      updatedAt: data['updatedAt'] != null
          ? parseDate(data['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (email != null) 'email': email,
      'contact': contact,
      'role': role,
      'employeeId': employeeId,
      if (shiftSchedule != null) 'shiftSchedule': shiftSchedule,
      'baseSalary': baseSalary,
      'payCycle': payCycle,
      if (userId != null) 'userId': userId,
      'isActive': isActive,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  StaffProfile copyWith({
    String? id,
    String? name,
    String? photoUrl,
    String? email,
    String? contact,
    String? role,
    String? employeeId,
    String? shiftSchedule,
    double? baseSalary,
    String? payCycle,
    String? userId,
    bool? isActive,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
      contact: contact ?? this.contact,
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      shiftSchedule: shiftSchedule ?? this.shiftSchedule,
      baseSalary: baseSalary ?? this.baseSalary,
      payCycle: payCycle ?? this.payCycle,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
