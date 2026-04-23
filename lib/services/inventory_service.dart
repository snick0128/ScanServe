import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/inventory_item.dart';
import '../models/inventory_log.dart';
import '../models/tenant_model.dart';
import 'menu_service.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _itemsRef(String tenantId) => _firestore
      .collection('tenants')
      .doc(tenantId)
      .collection('inventory_items');

  CollectionReference _logsRef(String tenantId) => _firestore
      .collection('tenants')
      .doc(tenantId)
      .collection('inventory_logs');

  /// Stream of all inventory items for a tenant
  Stream<List<InventoryItem>> getInventoryStream(String tenantId) {
    return _itemsRef(tenantId)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => InventoryItem.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  /// Get a single inventory item
  Future<InventoryItem?> getItem(String tenantId, String itemId) async {
    final doc = await _itemsRef(tenantId).doc(itemId).get();
    if (!doc.exists) return null;
    return InventoryItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Stream of recent inventory logs
  Stream<List<InventoryLog>> getRecentLogsStream(
    String tenantId, {
    int limit = 50,
  }) {
    return _logsRef(tenantId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => InventoryLog.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  /// Add a new primary inventory item
  Future<void> addItem(
    String tenantId,
    InventoryItem item,
    String adminName,
  ) async {
    final batch = _firestore.batch();
    final itemDoc = _itemsRef(tenantId).doc();

    batch.set(itemDoc, item.toMap());

    // Initial log entry
    final logDoc = _logsRef(tenantId).doc();
    final log = InventoryLog(
      id: '',
      itemId: itemDoc.id,
      itemName: item.name,
      type: InventoryChangeType.stockIn,
      quantityBefore: 0,
      quantityChanged: item.currentStock,
      quantityAfter: item.currentStock,
      reason: InventoryChangeReason.opening,
      performedBy: adminName,
      timestamp: DateTime.now(),
    );
    batch.set(logDoc, log.toMap());

    await batch.commit();
  }

  /// Update stock (IN/OUT/ADJUST) with mandatory logging
  Future<void> updateStock({
    required String tenantId,
    required String itemId,
    required double quantityChange,
    required InventoryChangeType type,
    required InventoryChangeReason reason,
    required String performedBy,
    String? sourceId,
  }) async {
    return _firestore.runTransaction((transaction) async {
      final docRef = _itemsRef(tenantId).doc(itemId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception("Item not found");

      final data = snapshot.data() as Map<String, dynamic>;
      final double before = (data['currentStock'] ?? 0).toDouble();
      final double after = before + quantityChange;

      // Update item
      transaction.update(docRef, {
        'currentStock': after,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Create log
      final logRef = _logsRef(tenantId).doc();
      final log = InventoryLog(
        id: '',
        itemId: itemId,
        itemName: data['name'] ?? 'Unknown',
        type: type,
        quantityBefore: before,
        quantityChanged: quantityChange,
        quantityAfter: after,
        reason: reason,
        sourceId: sourceId,
        performedBy: performedBy,
        timestamp: DateTime.now(),
      );
      transaction.set(logRef, log.toMap());
    });
  }

  /// Physical Reconciliation: Stock is REPLACED, not incremented
  Future<void> reconcileStock({
    required String tenantId,
    required String itemId,
    required double actualQuantity,
    required String performedBy,
  }) async {
    return _firestore.runTransaction((transaction) async {
      final docRef = _itemsRef(tenantId).doc(itemId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception("Item not found");

      final data = snapshot.data() as Map<String, dynamic>;
      final double before = (data['currentStock'] ?? 0).toDouble();
      final double difference = actualQuantity - before;

      if (difference == 0) return; // No change needed

      // Update item to match physical count
      transaction.update(docRef, {
        'currentStock': actualQuantity,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Create log
      final logRef = _logsRef(tenantId).doc();
      final log = InventoryLog(
        id: '',
        itemId: itemId,
        itemName: data['name'] ?? 'Unknown',
        type: InventoryChangeType.adjustment,
        quantityBefore: before,
        quantityChanged: difference,
        quantityAfter: actualQuantity,
        reason: InventoryChangeReason.physicalCount,
        performedBy: performedBy,
        timestamp: DateTime.now(),
      );
      transaction.set(logRef, log.toMap());
    });
  }

  /// Deduct stock based on a completed order and its recipe linkage.
  /// Accepts both List<CartItem> and List<OrderItem> via dynamic dispatch.
  Future<void> deductStockForOrder({
    required String tenantId,
    required String orderId,
    required List<dynamic> orderItems,
    required List<MenuItem> menuDefinitions,
    required String performedBy,
  }) async {
    for (var orderItem in orderItems) {
      // P0-3: Resolve item ID and quantity regardless of CartItem vs OrderItem type
      String itemId;
      int qty;
      try {
        // OrderItem has .id directly; CartItem has .item.id
        final dynamic raw = orderItem;
        if (raw.item != null) {
          // CartItem
          itemId = (raw.item.id as String?) ?? '';
          qty = (raw.quantity as int?) ?? 0;
        } else {
          itemId = (raw.id as String?) ?? '';
          qty = (raw.quantity as int?) ?? 0;
        }
      } catch (_) {
        continue;
      }
      if (itemId.isEmpty || qty <= 0) continue;

      // 1. Find the menu item definition
      final definition = menuDefinitions.firstWhere(
        (m) => m.id == itemId,
        orElse: () => MenuItem(id: '', name: '', description: '', price: 0),
      );

      if (definition.inventoryTrackingType == InventoryTrackingType.none) {
        continue;
      }

      // 2. Process each ingredient
      for (var entry in definition.inventoryIngredients.entries) {
        final ingredientId = entry.key;
        final qtyPerSale = entry.value;
        final totalDeduction = -(qtyPerSale * qty);

        try {
          await updateStock(
            tenantId: tenantId,
            itemId: ingredientId,
            quantityChange: totalDeduction,
            type: InventoryChangeType.stockOut,
            reason: InventoryChangeReason.sale,
            performedBy: performedBy,
            sourceId: 'Order: ${orderId.substring(0, 8)}',
          );

          // P0-3: Check if stock is now zero and flag menu item as out-of-stock
          final updatedItem = await getItem(tenantId, ingredientId);
          if (updatedItem != null && updatedItem.currentStock <= 0) {
            _markLinkedMenuItemsUnavailable(
              tenantId,
              ingredientId,
              menuDefinitions,
            );
          }
        } catch (e) {
          debugPrint('Failed to deduct stock for $ingredientId: $e');
        }
      }
    }
  }

  Future<void> restoreStockForOrder({
    required String tenantId,
    required String orderId,
    required List<dynamic> orderItems,
    required List<MenuItem> menuDefinitions,
    required String performedBy,
  }) async {
    for (var orderItem in orderItems) {
      final definition = menuDefinitions.firstWhere(
        (m) => m.id == (orderItem as dynamic).id,
        orElse: () => MenuItem(id: '', name: '', description: '', price: 0),
      );

      if (definition.inventoryTrackingType == InventoryTrackingType.none) {
        continue;
      }

      for (final entry in definition.inventoryIngredients.entries) {
        final itemId = entry.key;
        final qtyPerSale = entry.value;
        final totalRestore = qtyPerSale * (orderItem as dynamic).quantity;

        try {
          await updateStock(
            tenantId: tenantId,
            itemId: itemId,
            quantityChange: totalRestore,
            type: InventoryChangeType.stockIn,
            reason: InventoryChangeReason.manual,
            performedBy: performedBy,
            sourceId: 'Order restore: ${orderId.substring(0, 8)}',
          );
        } catch (e) {
          print('Failed to restore stock for $itemId: $e');
        }
      }
    }
  }

  Future<void> _markLinkedMenuItemsUnavailable(
    String tenantId,
    String ingredientId,
    List<MenuItem> menuDefinitions,
  ) async {
    final menuService = MenuService();
    final Map<String, Future<String?>> categoryIdCache = {};
    for (var menuItem in menuDefinitions) {
      if (menuItem.inventoryIngredients.containsKey(ingredientId) &&
          menuItem.isManualAvailable) {
        final updatedMenuItem = menuItem.copyWith(isManualAvailable: false);
        final rawCategory = menuItem.category;
        if (rawCategory == null || rawCategory.trim().isEmpty) continue;

        final normalizedKey = _normalizeCategoryKey(rawCategory);
        categoryIdCache.putIfAbsent(
          normalizedKey,
          () => _resolveCategoryId(tenantId, rawCategory),
        );
        final categoryId = await categoryIdCache[normalizedKey]!;
        if (categoryId == null) {
          print(
            '⚠️ Could not resolve category ID for "${menuItem.category}" while updating ${menuItem.name}',
          );
          continue;
        }
        await menuService.updateMenuItem(tenantId, categoryId, updatedMenuItem);
      }
    }
  }

  String _normalizeCategoryKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[_\-\s]+'), '');
  }

  Future<String?> _resolveCategoryId(
    String tenantId,
    String categoryValue,
  ) async {
    final categoriesSnapshot = await _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('categories')
        .get();
    final normalizedInput = _normalizeCategoryKey(categoryValue);

    for (final doc in categoriesSnapshot.docs) {
      final id = doc.id;
      final name = (doc.data()['name'] ?? '').toString();
      if (_normalizeCategoryKey(id) == normalizedInput ||
          _normalizeCategoryKey(name) == normalizedInput) {
        return id;
      }
    }
    return null;
  }

  /// Delete an inventory item
  Future<void> deleteItem(String tenantId, String itemId) async {
    await _itemsRef(tenantId).doc(itemId).delete();
  }
}
