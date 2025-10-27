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
            if (categoryId == 'meals') {
              itemData['category'] = 'Meals'; // Use 'Meals' for the meals category
            } else {
              itemData['category'] = categoryName; // Use the category name for others (like 'Breakfast')
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
}
