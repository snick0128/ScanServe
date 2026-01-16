import 'dart:convert';

/// Guest Profile Model
/// 
/// Stores customer information locally on the device to prevent
/// creating duplicate customer records and enable prefilling of
/// customer details in checkout and bill requests.
class GuestProfile {
  final String guestId;
  final String name;
  final String? phone;
  final DateTime lastUpdated;
  final int visitCount;
  final List<String> orderIds;

  GuestProfile({
    required this.guestId,
    required this.name,
    this.phone,
    required this.lastUpdated,
    this.visitCount = 1,
    this.orderIds = const [],
  });

  /// Create a new guest profile
  factory GuestProfile.create({
    required String guestId,
    required String name,
    String? phone,
  }) {
    return GuestProfile(
      guestId: guestId,
      name: name,
      phone: phone,
      lastUpdated: DateTime.now(),
      visitCount: 1,
      orderIds: [],
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'guestId': guestId,
      'name': name,
      'phone': phone,
      'lastUpdated': lastUpdated.toIso8601String(),
      'visitCount': visitCount,
      'orderIds': orderIds,
    };
  }

  /// Create from JSON
  factory GuestProfile.fromJson(Map<String, dynamic> json) {
    return GuestProfile(
      guestId: json['guestId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      visitCount: json['visitCount'] ?? 1,
      orderIds: List<String>.from(json['orderIds'] ?? []),
    );
  }
  
  /// Convert to JSON string for storage
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON string
  factory GuestProfile.fromJsonString(String jsonString) {
    return GuestProfile.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Create a copy with updated fields
  GuestProfile copyWith({
    String? guestId,
    String? name,
    String? phone,
    DateTime? lastUpdated,
    int? visitCount,
    List<String>? orderIds,
  }) {
    return GuestProfile(
      guestId: guestId ?? this.guestId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      lastUpdated: lastUpdated ?? DateTime.now(),
      visitCount: visitCount ?? this.visitCount,
      orderIds: orderIds ?? this.orderIds,
    );
  }

  @override
  String toString() {
    return 'GuestProfile(guestId: $guestId, name: $name, phone: $phone, visitCount: $visitCount, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuestProfile &&
        other.guestId == guestId &&
        other.name == name &&
        other.phone == phone &&
        other.visitCount == visitCount;
  }

  @override
  int get hashCode {
    return guestId.hashCode ^ name.hashCode ^ phone.hashCode ^ visitCount.hashCode;
  }
}
