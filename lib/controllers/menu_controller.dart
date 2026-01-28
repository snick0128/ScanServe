import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tenant_model.dart';
import '../models/inventory_item.dart';
import '../services/menu_service.dart';
import '../services/inventory_service.dart';

enum SortOrder { none, priceLowToHigh, priceHighToLow }

class MenuController extends ChangeNotifier {
  final MenuService _menuService = MenuService();
  final InventoryService _inventoryService = InventoryService();
  StreamSubscription? _inventorySub;

  String _selectedMealTime = ''; // Start with no filter
  String? _selectedSubcategory;
  List<String> _selectedCategories = [];
  String _searchQuery = '';
  bool _isVegOnly = false;
  bool _isNonVegOnly = false;
  bool _isBestsellerOnly = false;
  bool _isStrictVeg = false; // Restaurant-level setting
  SortOrder _sortOrder = SortOrder.none;
  final List<MenuItem> _items = [];
  List<InventoryItem> _inventory = [];
  bool _isLoading = false;

  String get selectedMealTime => _selectedMealTime;
  String? get selectedSubcategory => _selectedSubcategory;
  List<String> get selectedCategories => _selectedCategories;
  String get searchQuery => _searchQuery;
  int get searchResultsCount => filteredItems.length;
  bool get isSearching => _searchQuery.isNotEmpty;
  bool get isVegOnly => _isVegOnly || _isStrictVeg;
  bool get isNonVegOnly => _isNonVegOnly;
  bool get isBestsellerOnly => _isBestsellerOnly;
  bool get isStrictVeg => _isStrictVeg;
  SortOrder get sortOrder => _sortOrder;

  List<String> get availableCategories {
    final categories = _items
        .map((item) => item.category)
        .where((cat) => cat != null && cat.isNotEmpty)
        .map((cat) => cat!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  int get activeFiltersCount {
    int count = 0;
    if (_isVegOnly) count++;
    if (_isNonVegOnly) count++;
    if (_isBestsellerOnly) count++;
    if (_selectedCategories.isNotEmpty) count++;
    if (_sortOrder != SortOrder.none) count++;
    return count;
  }
  
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

      // Filter Bottom Sheet Categories filter
      if (_selectedCategories.isNotEmpty && (item.category == null || !_selectedCategories.contains(item.category))) {
        return false;
      }

      // Veg filter
      if ((_isVegOnly || _isStrictVeg) && !item.isVeg) return false;

      // Non-Veg filter
      if (_isNonVegOnly && item.isVeg) return false;

      // Bestseller filter
      if (_isBestsellerOnly && !item.isBestseller) return false;

      // NEW: Dynamic Availability filter (Recipe based)
      if (!item.isAvailable(_inventory)) {
        return false;
      }
      
      return true;
    }).toList();

    // Apply Sorting
    if (_sortOrder == SortOrder.priceLowToHigh) {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortOrder == SortOrder.priceHighToLow) {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    }

    return filtered;
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

  void setSubcategory(String? subcategory) {
    _selectedSubcategory = subcategory;
    notifyListeners();
  }

  void setCategories(List<String> categories) {
    _selectedCategories = categories;
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

  void setSortOrder(SortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  void applyFilters({
    required bool isVegOnly,
    required bool isNonVegOnly,
    required bool isBestsellerOnly,
    required SortOrder sortOrder,
    List<String> selectedCategories = const [],
  }) {
    _isVegOnly = isVegOnly;
    _isNonVegOnly = isNonVegOnly;
    _isBestsellerOnly = isBestsellerOnly;
    _sortOrder = sortOrder;
    _selectedCategories = List.from(selectedCategories);
    notifyListeners();
  }

  void setStrictVegMode(bool enable) {
    _isStrictVeg = enable;
    if (enable) {
      _isVegOnly = true;
      _isNonVegOnly = false;
    }
    notifyListeners();
  }

  void clearAllFilters() {
    _isVegOnly = false;
    _isNonVegOnly = false;
    _isBestsellerOnly = false;
    _sortOrder = SortOrder.none;
    _selectedCategories = [];
    notifyListeners();
  }

  void toggleVegOnly() {
    _isVegOnly = !_isVegOnly;
    if (_isVegOnly) _isNonVegOnly = false;
    notifyListeners();
  }

  void toggleNonVegOnly() {
    _isNonVegOnly = !_isNonVegOnly;
    if (_isNonVegOnly) _isVegOnly = false;
    notifyListeners();
  }

  void toggleBestsellerOnly() {
    _isBestsellerOnly = !_isBestsellerOnly;
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

