import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  menuItemUpdate,
  menuItemAdd,
  menuItemDelete,
  orderCreate,
  orderStatusUpdate,
  orderCancel,
  orderItemAdd,
  orderItemUpdate,
  orderItemDelete,
  orderItemServed,
  orderItemStatusUpdate,
  tableUpdate,
  payment,
  other
}

class ActivityLog {
  final String id;
  final String action;
  final String description;
  final String actorId;
  final String actorName;
  final String actorRole;
  final ActivityType type;
  final DateTime timestamp;
  final String tenantId;
  final Map<String, dynamic>? metadata;

  ActivityLog({
    required this.id,
    required this.action,
    required this.description,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.type,
    required this.timestamp,
    required this.tenantId,
    this.metadata,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> map, String id) {
    return ActivityLog(
      id: id,
      action: map['action'] ?? '',
      description: map['description'] ?? '',
      actorId: map['actorId'] ?? '',
      actorName: map['actorName'] ?? 'Unknown User',
      actorRole: map['actorRole'] ?? 'unknown',
      type: _parseType(map['type']),
      timestamp: (map['timestamp'] is Timestamp) 
          ? (map['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      tenantId: map['tenantId'] ?? '',
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'description': description,
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': actorRole,
      'type': type.name,
      'timestamp': FieldValue.serverTimestamp(),
      'tenantId': tenantId,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static ActivityType _parseType(String? type) {
    return ActivityType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ActivityType.other,
    );
  }
}
