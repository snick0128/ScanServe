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

  GuestProfile({
    required this.guestId,
    required this.name,
    this.phone,
    required this.lastUpdated,
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
    );
  }

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'guestId': guestId,
      'name': name,
      'phone': phone,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON stored in SharedPreferences
  factory GuestProfile.fromJson(Map<String, dynamic> json) {
    return GuestProfile(
      guestId: json['guestId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
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
  }) {
    return GuestProfile(
      guestId: guestId ?? this.guestId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'GuestProfile(guestId: $guestId, name: $name, phone: $phone, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuestProfile &&
        other.guestId == guestId &&
        other.name == name &&
        other.phone == phone;
  }

  @override
  int get hashCode {
    return guestId.hashCode ^ name.hashCode ^ phone.hashCode;
  }
}
