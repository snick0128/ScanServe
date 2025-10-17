import 'package:flutter/material.dart';
import '../models/tenant_model.dart';
import '../services/menu_service.dart';

class MenuController extends ChangeNotifier {
  final MenuService _menuService = MenuService();

  String _selectedMealTime = 'Breakfast';
  String? _selectedSubcategory;
  String _searchQuery = '';
  final List<MenuItem> _items = [];
  bool _isLoading = false;

  String get selectedMealTime => _selectedMealTime;
  String? get selectedSubcategory => _selectedSubcategory;
  String get searchQuery => _searchQuery;
  List<MenuItem> get filteredItems => _items
      .where(
        (item) =>
            item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.description.toLowerCase().contains(_searchQuery.toLowerCase()),
      )
      .toList();
  bool get isLoading => _isLoading;

  void setMealTime(String mealTime) {
    _selectedMealTime = mealTime;
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

  void startLoading() {
    _isLoading = true;
    Future.microtask(() => notifyListeners());
  }

  void stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void setMenuItems(List<MenuItem> items) {
    _items.clear();
    _items.addAll(items);
    _isLoading = false;
    notifyListeners();
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
