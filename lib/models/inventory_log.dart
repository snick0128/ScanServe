import 'package:cloud_firestore/cloud_firestore.dart';

enum InventoryChangeType {
  stockIn('IN'),
  stockOut('OUT'),
  adjustment('ADJUSTMENT');

  final String label;
  const InventoryChangeType(this.label);
}

enum InventoryChangeReason {
  purchase('Purchase'),
  sale('Sale'),
  wastage('Wastage'),
  damage('Damage/Expiry'),
  manual('Manual Correction'),
  physicalCount('Physical Count Correction'),
  opening('Opening Stock');

  final String label;
  const InventoryChangeReason(this.label);
}

class InventoryLog {
  final String id;
  final String itemId;
  final String itemName;
  final InventoryChangeType type;
  final double quantityBefore;
  final double quantityChanged;
  final double quantityAfter;
  final InventoryChangeReason reason;
  final String? sourceId; // Order ID or Purchase Ref
  final String performedBy;
  final DateTime timestamp;

  InventoryLog({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.type,
    required this.quantityBefore,
    required this.quantityChanged,
    required this.quantityAfter,
    required this.reason,
    this.sourceId,
    required this.performedBy,
    required this.timestamp,
  });

  factory InventoryLog.fromMap(Map<String, dynamic> data, String docId) {
    return InventoryLog(
      id: docId,
      itemId: data['itemId'] ?? '',
      itemName: data['itemName'] ?? '',
      type: InventoryChangeType.values.firstWhere((e) => e.name == data['type']),
      quantityBefore: (data['quantityBefore'] ?? 0).toDouble(),
      quantityChanged: (data['quantityChanged'] ?? 0).toDouble(),
      quantityAfter: (data['quantityAfter'] ?? 0).toDouble(),
      reason: InventoryChangeReason.values.firstWhere((e) => e.name == data['reason']),
      sourceId: data['sourceId'],
      performedBy: data['performedBy'] ?? 'Unknown',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'type': type.name,
      'quantityBefore': quantityBefore,
      'quantityChanged': quantityChanged,
      'quantityAfter': quantityAfter,
      'reason': reason.name,
      'sourceId': sourceId,
      'performedBy': performedBy,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
