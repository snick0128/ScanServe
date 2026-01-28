import 'package:flutter/foundation.dart' hide Category;
import '../../models/tenant_model.dart';
import '../../services/menu_service.dart';

class MenuProvider with ChangeNotifier {
  final MenuService _menuService = MenuService();
  
  List<MenuItem> _allItems = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _tenantId;

  // Search & Filter state
  String _searchQuery = '';
  String _selectedCategory = 'All Items';
  String _selectedType = 'All'; // All, Veg, Non-Veg
  bool _isBestsellerOnly = false;

  List<MenuItem> get allItems => _allItems;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get selectedType => _selectedType;
  bool get isBestsellerOnly => _isBestsellerOnly;

  // Filtered items based on current search & filter state
  List<MenuItem> get filteredItems {
    var items = List<MenuItem>.from(_allItems);

    // Search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items.where((i) => 
        i.name.toLowerCase().contains(query) || 
        (i.category?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    // Category
    if (_selectedCategory != 'All Items') {
      items = items.where((i) => i.category == _selectedCategory).toList();
    }

    // Type (Veg/Non-Veg/etc)
    if (_selectedType != 'All') {
      if (_selectedType == 'Veg') {
        items = items.where((i) => i.isVeg).toList();
      } else if (_selectedType == 'Non-Veg') {
        items = items.where((i) => !i.isVeg).toList();
      }
    }

    // Bestseller
    if (_isBestsellerOnly) {
      items = items.where((i) => i.isBestseller).toList();
    }

    return items;
  }

  Future<void> initialize(String tenantId) async {
    if (_tenantId == tenantId && _allItems.isNotEmpty) return;
    
    _tenantId = tenantId;
    _isLoading = true;
    notifyListeners();

    try {
      await refreshData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    if (_tenantId == null) return;
    try {
      _allItems = await _menuService.getMenuItems(_tenantId!);
      _categories = await _menuService.getCategories(_tenantId!);
      notifyListeners();
    } catch (e) {
      print('Error refreshing menu data: $e');
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setTypeFilter(String type) {
    _selectedType = type;
    notifyListeners();
  }

  void toggleBestsellerFilter() {
    _isBestsellerOnly = !_isBestsellerOnly;
    notifyListeners();
  }

  Future<void> updateBestsellerStatus(String categoryId, String itemId, bool isBestseller) async {
    if (_tenantId == null) return;

    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final originalItem = _allItems[index];
    final updatedItem = originalItem.copyWith(isBestseller: isBestseller);

    // Optimistic UI Update
    _allItems[index] = updatedItem;
    notifyListeners();

    try {
      await _menuService.updateMenuItem(_tenantId!, categoryId, updatedItem);
    } catch (e) {
      // Revert on error
      _allItems[index] = originalItem;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleAvailability(String categoryId, String itemId) async {
    if (_tenantId == null) return;

    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final originalItem = _allItems[index];
    final updatedItem = originalItem.copyWith(isManualAvailable: !originalItem.isManualAvailable);

    // Optimistic UI Update
    _allItems[index] = updatedItem;
    notifyListeners();

    try {
      await _menuService.updateMenuItem(_tenantId!, categoryId, updatedItem);
    } catch (e) {
      // Revert on error
      _allItems[index] = originalItem;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addMenuItem(String categoryId, MenuItem item) async {
    if (_tenantId == null) return;
    await _menuService.addMenuItem(_tenantId!, categoryId, item);
    await refreshData();
  }

  Future<void> updateMenuItem(String categoryId, MenuItem item) async {
    if (_tenantId == null) return;
    await _menuService.updateMenuItem(_tenantId!, categoryId, item);
    await refreshData();
  }

  Future<void> deleteMenuItem(String categoryId, String itemId) async {
    if (_tenantId == null) return;
    await _menuService.deleteMenuItem(_tenantId!, categoryId, itemId);
    await refreshData();
  }

  Future<void> addCategory(Category category) async {
    if (_tenantId == null) return;
    await _menuService.addCategory(_tenantId!, category);
    await refreshData();
  }

  Future<void> updateCategory(Category category) async {
    if (_tenantId == null) return;
    await _menuService.updateCategory(_tenantId!, category);
    await refreshData();
  }

  Future<void> deleteCategory(String categoryId) async {
    if (_tenantId == null) return;
    await _menuService.deleteCategory(_tenantId!, categoryId);
    await refreshData();
  }
}
