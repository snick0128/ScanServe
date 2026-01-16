import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tenant_model.dart';
import '../models/inventory_item.dart';
import '../services/menu_service.dart';
import '../services/inventory_service.dart';

class MenuController extends ChangeNotifier {
  final MenuService _menuService = MenuService();
  final InventoryService _inventoryService = InventoryService();
  StreamSubscription? _inventorySub;

  String _selectedMealTime = ''; // Start with no filter
  String? _selectedSubcategory;
  String _searchQuery = '';
  bool _showNonVeg = true; 
  final List<MenuItem> _items = [];
  List<InventoryItem> _inventory = [];
  bool _isLoading = false;

  String get selectedMealTime => _selectedMealTime;
  String? get selectedSubcategory => _selectedSubcategory;
  String get searchQuery => _searchQuery;
  int get searchResultsCount => filteredItems.length;
  bool get isSearching => _searchQuery.isNotEmpty;
  
  List<MenuItem> get filteredItems {
    var filtered = _items.where((item) {
      // Search filter
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      // Category (Meal Time) filter
      if (_selectedMealTime.isNotEmpty && item.category != _selectedMealTime) return false;

      // Subcategory filter
      if (_selectedSubcategory != null && item.subcategory != _selectedSubcategory) return false;

      // Veg/Non-Veg filter
      if (!_showNonVeg && !item.isVeg) return false;

      // NEW: Dynamic Availability filter (Recipe based)
      if (!item.isAvailable(_inventory)) {
        return false;
      }
      
      return true;
    });

    return filtered.toList();
  }

  bool get isLoading => _isLoading;

  void updateInventory(List<InventoryItem> inventory) {
    _inventory = inventory;
    notifyListeners();
  }

  void startInventoryListener(String tenantId) {
    _inventorySub?.cancel();
    _inventorySub = _inventoryService.getInventoryStream(tenantId).listen((inventory) {
      updateInventory(inventory);
    });
  }

  void setMealTime(String mealTime) {
    _selectedMealTime = mealTime;
    notifyListeners();
  }

  void testFirebaseConnection() async {
    print('🧪 TESTING FIREBASE CONNECTION...');
    try {
      final menuItems = await _menuService.getMenuItems('demo_tenant');
      print('🧪 TEST RESULT: Loaded ${menuItems.length} items from Firebase');
      setMenuItems(menuItems);
    } catch (e) {
      print('🧪 TEST ERROR: $e');
    }
  }

  void setSubcategory(String? subcategory) {
    _selectedSubcategory = subcategory;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setVegFilter(bool showNonVeg) {
    print('🥬 SETTING VEG FILTER: $_showNonVeg → $showNonVeg');
    _showNonVeg = showNonVeg;
    notifyListeners();
  }

  void startLoading() {
    _isLoading = true;
    Future.microtask(() => notifyListeners());
  }

  void stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void setMenuItems(List<MenuItem> items) {
    print('Setting ${items.length} menu items in controller');
    _items.clear();
    _items.addAll(items);
    _isLoading = false;
    notifyListeners();

    // Debug: Print sample items to verify category/subcategory data
    if (items.isNotEmpty) {
      print('=== SAMPLE ITEMS DEBUG ===');
      final categories = <String>{};
      for (var item in items) {
        categories.add(item.category ?? 'NULL');
        if (categories.length <= 5) {
          // Only print first few unique categories
          print(
            'Item: "${item.name}" | Category: "${item.category}" | Subcategory: "${item.subcategory}"',
          );
        }
      }
      print('Unique categories found: $categories');
      print('=== END SAMPLE DEBUG ===');
    }
  }

  Future<void> loadMenuItems(String tenantId) async {
    startLoading();
    try {
      final menuItems = await _menuService.getMenuItems(tenantId);
      setMenuItems(menuItems);
    } catch (e) {
      print('Error loading menu items: $e');
      stopLoading();
    }
  }

  @override
  void dispose() {
    _inventorySub?.cancel();
    super.dispose();
  }
}

