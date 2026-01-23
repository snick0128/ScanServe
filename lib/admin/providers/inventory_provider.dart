import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/inventory_item.dart';
import '../../models/inventory_log.dart';
import '../../services/inventory_service.dart';

class InventoryProvider with ChangeNotifier {
  final InventoryService _service = InventoryService();
  final String tenantId;
  
  List<InventoryItem> _items = [];
  List<InventoryItem> _filteredItems = [];
  List<InventoryLog> _recentLogs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;
  StockStatus? _selectedStatus;
  StreamSubscription? _itemsSub;
  StreamSubscription? _logsSub;

  InventoryProvider(this.tenantId) {
    _init();
  }

  List<InventoryItem> get items => _filteredItems; // Return filtered items
  List<InventoryLog> get recentLogs => _recentLogs;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  StockStatus? get selectedStatus => _selectedStatus;

  List<InventoryItem> get lowStockItems => 
      _items.where((i) => i.status == StockStatus.low).toList();

  List<InventoryItem> get outOfStockItems => 
      _items.where((i) => i.status == StockStatus.out).toList();

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void setStatus(StockStatus? status) {
    _selectedStatus = status;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredItems = _items.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null || item.category == _selectedCategory;
      final matchesStatus = _selectedStatus == null || item.status == _selectedStatus;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
    notifyListeners();
  }

  void _init() {
    if (tenantId.isEmpty) {
      _isLoading = false;
      return;
    }

    // Cancel existing subscriptions if any
    _itemsSub?.cancel();
    _logsSub?.cancel();

    _itemsSub = _service.getInventoryStream(tenantId).listen((data) {
      _items = data;
      _applyFilters();
      _isLoading = false;
    }, onError: (e) {
      debugPrint('Error in inventory items stream: $e');
      _isLoading = false;
      notifyListeners();
    });

    _logsSub = _service.getRecentLogsStream(tenantId).listen((data) {
      _recentLogs = data;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error in inventory logs stream: $e');
    });
  }

  /// Manually force a refresh of the inventory data
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    _init();
  }

  Future<void> addItem(InventoryItem item, String adminName) async {
    await _service.addItem(tenantId, item, adminName);
  }

  Future<void> updateStock({
    required String itemId,
    required double quantityChange,
    required InventoryChangeType type,
    required InventoryChangeReason reason,
    required String performedBy,
  }) async {
    await _service.updateStock(
      tenantId: tenantId,
      itemId: itemId,
      quantityChange: quantityChange,
      type: type,
      reason: reason,
      performedBy: performedBy,
    );
  }

  Future<void> reconcileStock({
    required String itemId,
    required double actualQuantity,
    required String performedBy,
  }) async {
    await _service.reconcileStock(
      tenantId: tenantId,
      itemId: itemId,
      actualQuantity: actualQuantity,
      performedBy: performedBy,
    );
  }

  @override
  void dispose() {
    _itemsSub?.cancel();
    _logsSub?.cancel();
    super.dispose();
  }
}
