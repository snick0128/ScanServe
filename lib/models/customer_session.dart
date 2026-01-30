import 'dart:convert';

class CustomerSession {
  final String tenantId;
  final String tableId;
  final String sessionId;
  final String guestId;
  final int createdAt;

  CustomerSession({
    required this.tenantId,
    required this.tableId,
    required this.sessionId,
    required this.guestId,
    required this.createdAt,
  });

  factory CustomerSession.fromMap(Map<String, dynamic> map) {
    return CustomerSession(
      tenantId: map['tenantId'] ?? '',
      tableId: map['tableId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      guestId: map['guestId'] ?? '',
      createdAt: map['createdAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'tableId': tableId,
      'sessionId': sessionId,
      'guestId': guestId,
      'createdAt': createdAt,
    };
  }

  String toJson() => json.encode(toMap());

  factory CustomerSession.fromJson(String source) =>
      CustomerSession.fromMap(json.decode(source));

  bool isValidFor(String targetTenantId, String? targetTableId) {
    if (tenantId != targetTenantId) return false;
    if (targetTableId != null && tableId != targetTableId) return false;
    return true;
  }
}
