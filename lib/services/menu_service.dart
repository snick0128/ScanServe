import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tenant_model.dart';

class MenuService {
  final _firestore = FirebaseFirestore.instance;

  Future<List<MenuItem>> getMenuItems(String tenantId) async {
    try {
      print('🔥 FETCHING MENU ITEMS: Starting for tenant $tenantId');
      final categoriesSnapshot = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('categories')
          .get();

      List<MenuItem> allMenuItems = [];

      for (var categoryDoc in categoriesSnapshot.docs) {
        final categoryData = categoryDoc.data();
        final categoryName = categoryData['name'] as String? ?? categoryDoc.id;

        // Fetch items from subcollection: tenants/{tenantId}/categories/{categoryId}/items
        final itemsSnapshot = await categoryDoc.reference.collection('items').get();
        
        for (var itemDoc in itemsSnapshot.docs) {
          final itemData = itemDoc.data();
          
          // Add category field if missing
          if (!itemData.containsKey('category')) {
            itemData['category'] = categoryName;
          }
          
          try {
            allMenuItems.add(MenuItem.fromMap(itemData));
          } catch (e) {
            print('❌ Error parsing menu item ${itemDoc.id}: $e');
          }
        }

        // BACKWARD COMPATIBILITY: Also check the old 'menu_items' array
        final legacyItems = categoryData['menu_items'] as List<dynamic>? ?? [];
        if (legacyItems.isNotEmpty) {
          print('⚠️ Found ${legacyItems.length} legacy items in category ${categoryDoc.id}');
          for (var item in legacyItems) {
            final itemData = item as Map<String, dynamic>;
            if (!allMenuItems.any((i) => i.id == itemData['id'])) {
              try {
                allMenuItems.add(MenuItem.fromMap(itemData));
              } catch (e) { /* ignore legacy errors */ }
            }
          }
        }
      }

      return allMenuItems;
    } catch (e) {
      print('❌ ERROR FETCHING MENU ITEMS: $e');
      return [];
    }
  }
  Future<List> loadMenuItemsForTenant(String tenantId) async {
    try {
      final menuItems = await getMenuItems(tenantId);
      print('Loaded ${menuItems.length} menu items for tenant: $tenantId');
      return menuItems;
    } catch (e) {
      print('Error loading menu items for tenant: $e');
      return [];
    }
  }

  Future<List<Category>> getCategories(String tenantId) async {
    try {
      final snapshot = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('categories')
          .get();

      return snapshot.docs
          .map((doc) => Category.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<void> addMenuItem(String tenantId, String categoryId, MenuItem item) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('categories')
          .doc(categoryId)
          .collection('items')
          .doc(item.id)
          .set(item.toMap());
    } catch (e) {
      print('Error adding menu item: $e');
      rethrow;
    }
  }

  Future<void> updateMenuItem(String tenantId, String categoryId, MenuItem item) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('categories')
          .doc(categoryId)
          .collection('items')
          .doc(item.id)
          .update(item.toMap());
    } catch (e) {
      print('Error updating menu item: $e');
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String tenantId, String categoryId, String itemId) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('categories')
          .doc(categoryId)
          .collection('items')
          .doc(itemId)
          .delete();
    } catch (e) {
      print('Error deleting menu item: $e');
      rethrow;
    }
  }

  Future<void> addCategory(String tenantId, Category category) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('categories')
          .doc(category.id)
          .set(category.toMap());
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(String tenantId, Category category) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('categories')
          .doc(category.id)
          .update(category.toMap());
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String tenantId, String categoryId) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('categories')
          .doc(categoryId)
          .delete();
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }
}
