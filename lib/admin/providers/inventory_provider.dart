import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/inventory_item.dart';
import '../../models/inventory_log.dart';
import '../../services/inventory_service.dart';

class InventoryProvider with ChangeNotifier {
  final InventoryService _service = InventoryService();
  final String tenantId;
  
  List<InventoryItem> _items = [];
  List<InventoryLog> _recentLogs = [];
  bool _isLoading = true;
  StreamSubscription? _itemsSub;
  StreamSubscription? _logsSub;

  InventoryProvider(this.tenantId) {
    _init();
  }

  List<InventoryItem> get items => _items;
  List<InventoryLog> get recentLogs => _recentLogs;
  bool get isLoading => _isLoading;

  List<InventoryItem> get lowStockItems => 
      _items.where((i) => i.status == StockStatus.low).toList();

  List<InventoryItem> get outOfStockItems => 
      _items.where((i) => i.status == StockStatus.out).toList();

  void _init() {
    if (tenantId.isEmpty) {
      _isLoading = false;
      return;
    }

    _itemsSub = _service.getInventoryStream(tenantId).listen((data) {
      _items = data;
      _isLoading = false;
      notifyListeners();
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
