import 'package:cloud_firestore/cloud_firestore.dart';

enum StockStatus {
  inStock('In Stock', 0xFF4CAF50), // Green
  low('Low Stock', 0xFFFFC107),    // Yellow
  out('Out of Stock', 0xFFF44336); // Red

  final String label;
  final int color;
  const StockStatus(this.label, this.color);
}

class InventoryItem {
  final String id;
  final String tenantId;
  final String name;
  final String unit; // kg, gm, litre, pcs
  final double currentStock;
  final double lowStockLevel;
  final DateTime lastUpdated;

  InventoryItem({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.unit,
    required this.currentStock,
    this.lowStockLevel = 0,
    required this.lastUpdated,
  });

  StockStatus get status {
    if (currentStock <= 0) return StockStatus.out;
    if (currentStock <= lowStockLevel) return StockStatus.low;
    return StockStatus.inStock;
  }

  factory InventoryItem.fromMap(Map<String, dynamic> data, String docId) {
    return InventoryItem(
      id: docId,
      tenantId: data['tenantId'] ?? '',
      name: data['name'] ?? '',
      unit: data['unit'] ?? 'pcs',
      currentStock: (data['currentStock'] ?? 0).toDouble(),
      lowStockLevel: (data['lowStockLevel'] ?? 0).toDouble(),
      lastUpdated: data['lastUpdated'] != null 
          ? (data['lastUpdated'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'name': name,
      'unit': unit,
      'currentStock': currentStock,
      'lowStockLevel': lowStockLevel,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}
