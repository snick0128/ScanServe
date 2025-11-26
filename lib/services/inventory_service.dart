import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tenant_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore;

  InventoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Update stock for a specific item
  Future<void> updateStock(
    String tenantId,
    String categoryId,
    String itemId,
    int newStock, {
    bool isTracked = true,
  }) async {
    try {
      final categoryRef = _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('categories')
          .doc(categoryId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(categoryRef);
        if (!snapshot.exists) {
          throw Exception('Category not found');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final items = (data['menu_items'] as List<dynamic>).map((item) {
          final map = item as Map<String, dynamic>;
          if (map['id'] == itemId) {
            return {
              ...map,
              'stockCount': newStock,
              'isTracked': isTracked,
            };
          }
          return map;
        }).toList();

        transaction.update(categoryRef, {'menu_items': items});
      });
    } catch (e) {
      print('Error updating stock: $e');
      rethrow;
    }
  }

  // Decrement stock when an order is placed
  Future<void> decrementStock(
    String tenantId,
    String categoryId,
    String itemId,
    int quantity,
  ) async {
    try {
      final categoryRef = _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('categories')
          .doc(categoryId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(categoryRef);
        if (!snapshot.exists) {
          throw Exception('Category not found');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final items = (data['menu_items'] as List<dynamic>).map((item) {
          final map = item as Map<String, dynamic>;
          if (map['id'] == itemId) {
            final currentStock = map['stockCount'] ?? 0;
            final isTracked = map['isTracked'] ?? false;
            
            if (isTracked) {
              if (currentStock < quantity) {
                throw Exception('Insufficient stock for item: ${map['name']}');
              }
              return {
                ...map,
                'stockCount': currentStock - quantity,
              };
            }
          }
          return map;
        }).toList();

        transaction.update(categoryRef, {'menu_items': items});
      });
    } catch (e) {
      print('Error decrementing stock: $e');
      rethrow;
    }
  }

  // Stream of low stock items
  Stream<List<MenuItem>> getLowStockItems(String tenantId, {int threshold = 5}) {
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('categories')
        .snapshots()
        .map((snapshot) {
      final lowStockItems = <MenuItem>[];
      for (var doc in snapshot.docs) {
        final category = Category.fromMap(doc.data());
        for (var item in category.items) {
          if (item.isTracked && item.stockCount <= threshold) {
            lowStockItems.add(item);
          }
        }
      }
      return lowStockItems;
    });
  }
}
