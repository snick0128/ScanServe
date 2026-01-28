import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tenant_model.dart';

class MenuService {
  final _firestore = FirebaseFirestore.instance;

  Future<List<MenuItem>> getMenuItems(String tenantId) async {
    try {
      print('🔥 FETCHING MENU ITEMS: Starting for tenant $tenantId');
      // Get categories subcollection
      final categoriesCollection = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('categories')
          .get();

      print('🔥 FOUND CATEGORIES: ${categoriesCollection.docs.length} categories');

      if (categoriesCollection.docs.isEmpty) {
        print('❌ NO CATEGORIES FOUND for tenant $tenantId');
        return [];
      }

      List<MenuItem> allMenuItems = [];

      for (var categoryDoc in categoriesCollection.docs) {
        final categoryData = categoryDoc.data();
        final categoryName = categoryData['name'] as String? ?? categoryDoc.id;

        print('Processing category: ${categoryDoc.id}');
        print('Category data: ${categoryDoc.data()}');

        final menuItems = categoryData['menu_items'] as List<dynamic>? ?? [];
        print('Found ${menuItems.length} items in category ${categoryDoc.id}');

        for (var item in menuItems) {
          final itemData = item as Map<String, dynamic>;

          // Add category field based on the category document ID
          if (!itemData.containsKey('category')) {
            final categoryId = categoryDoc.id.toLowerCase();
            // Include both 'lunch' and 'dinner' in the 'Meals' category
            if (categoryId == 'meals' || categoryId == 'lunch' || categoryId == 'dinner') {
              itemData['category'] = 'Meals';
            } else {
              itemData['category'] = categoryName;
            }
          }

          print('🔍 RAW ITEM DATA: ${itemData.toString()}');
          try {
            final menuItem = MenuItem.fromMap(itemData);
            print(
              '📝 CREATED: ${menuItem.name} | Category: "${menuItem.category}" | Subcategory: "${menuItem.subcategory}"',
            );
            allMenuItems.add(menuItem);
          } catch (e) {
            print('❌ Error parsing menu item: $e');
          }
        }
      }

      return allMenuItems;
    } catch (e) {
      print('❌ ERROR FETCHING MENU ITEMS: $e');
      print('Stack trace: ${StackTrace.current}');
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
      final categoryRef = _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('categories')
          .doc(categoryId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(categoryRef);
        if (!snapshot.exists) throw Exception('Category not found');

        final data = snapshot.data() as Map<String, dynamic>;
        final items = List<Map<String, dynamic>>.from(data['menu_items'] ?? []);
        
        items.add(item.toMap());
        
        transaction.update(categoryRef, {'menu_items': items});
      });
    } catch (e) {
      print('Error adding menu item: $e');
      rethrow;
    }
  }

  Future<void> updateMenuItem(String tenantId, String categoryId, MenuItem item) async {
    try {
      final categoryRef = _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('categories')
          .doc(categoryId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(categoryRef);
        if (!snapshot.exists) throw Exception('Category not found');

        final data = snapshot.data() as Map<String, dynamic>;
        final items = List<Map<String, dynamic>>.from(data['menu_items'] ?? []);
        
        final index = items.indexWhere((i) => i['id'] == item.id);
        if (index != -1) {
          items[index] = item.toMap();
          transaction.update(categoryRef, {'menu_items': items});
        } else {
          throw Exception('Item not found in category');
        }
      });
    } catch (e) {
      print('Error updating menu item: $e');
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String tenantId, String categoryId, String itemId) async {
    try {
      final categoryRef = _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('categories')
          .doc(categoryId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(categoryRef);
        if (!snapshot.exists) throw Exception('Category not found');

        final data = snapshot.data() as Map<String, dynamic>;
        final items = List<Map<String, dynamic>>.from(data['menu_items'] ?? []);
        
        items.removeWhere((i) => i['id'] == itemId);
        
        transaction.update(categoryRef, {'menu_items': items});
      });
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
