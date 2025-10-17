import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tenant_model.dart';

class MenuService {
  final _firestore = FirebaseFirestore.instance;

  Future<List<MenuItem>> getMenuItems(String tenantId) async {
    try {
      final tenantDoc = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .get();

      if (!tenantDoc.exists) {
        print('Tenant not found: $tenantId');
        return [];
      }

      final tenantData = tenantDoc.data() as Map<String, dynamic>;
      final categories = tenantData['categories'] as List<dynamic>? ?? [];

      List<MenuItem> allMenuItems = [];

      for (var category in categories) {
        final menuItems = category['menu_items'] as List<dynamic>? ?? [];
        for (var item in menuItems) {
          allMenuItems.add(MenuItem.fromMap(item as Map<String, dynamic>));
        }
      }

      return allMenuItems;
    } catch (e) {
      print('Error fetching menu items: $e');
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
