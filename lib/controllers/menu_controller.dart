import 'package:flutter/material.dart';
import '../models/tenant_model.dart';
import '../services/menu_service.dart';

class MenuController extends ChangeNotifier {
  final MenuService _menuService = MenuService();

  String _selectedMealTime = ''; // Start with no filter
  String? _selectedSubcategory;
  String _searchQuery = '';
  bool _showNonVeg = false; // Default to veg-only mode
  final List<MenuItem> _items = [];
  bool _isLoading = false;

  String get selectedMealTime => _selectedMealTime;
  String? get selectedSubcategory => _selectedSubcategory;
  String get searchQuery => _searchQuery;
  bool get showNonVeg => _showNonVeg;
  List<MenuItem> get filteredItems {
    print('🔍 FILTERING: Total items: ${_items.length}, Selected meal time: "$_selectedMealTime", Search query: "$_searchQuery"');

    var filtered = _items
        .where(
          (item) =>
              item.description.toLowerCase().contains(_searchQuery.toLowerCase()),
        );

    print('🔍 AFTER SEARCH: ${filtered.length} items');

    filtered = filtered.where((item) {
      // Filter by meal time (category) if selected
      if (_selectedMealTime.isNotEmpty && item.category != null) {
        if (item.category != _selectedMealTime) {
          print('FILTERING OUT: "${item.name}" (category: "${item.category}") - looking for "$_selectedMealTime"');
          return false;
        }
      }
      return true;
    });

    print('🔍 AFTER MEAL TIME FILTER: ${filtered.length} items');

    // Filter by veg/non-veg preference
    filtered = filtered.where((item) {
      if (_showNonVeg) {
        // Show all items when toggle is true
        return true;
      } else {
        // Show only veg items when toggle is false
        final subcategory = item.subcategory;
        final isVeg = subcategory != null &&
                     (subcategory.toLowerCase() == 'veg' ||
                      subcategory.toLowerCase().contains('veg'));
        print('🔍 Item: "${item.name}" | subcategory: "$subcategory" | isVeg: $isVeg');
        return isVeg;
      }
    });

    print('🔍 AFTER VEG/NON-VEG FILTER: ${filtered.length} items');

    final result = filtered.toList();
    print('🔍 FINAL RESULT: ${result.length} items');
    return result;
  }
  bool get isLoading => _isLoading;

  void setMealTime(String mealTime) {
    print('🍽️ SETTING MEAL TIME: "$_selectedMealTime" → "$mealTime"');
    _selectedMealTime = mealTime;
    notifyListeners();
  }

  void testFiltering() {
    print('🧪 TESTING FILTER: Setting filter to "Meals"');
    _selectedMealTime = 'Meals';
    notifyListeners();
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
        if (categories.length <= 5) { // Only print first few unique categories
          print('Item: "${item.name}" | Category: "${item.category}" | Subcategory: "${item.subcategory}"');
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
}
