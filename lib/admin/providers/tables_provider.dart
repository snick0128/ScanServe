import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tenant_model.dart';
import '../../models/table_status.dart';
import '../../services/tables_service.dart';
import './orders_provider.dart';
import '../../models/order.dart' as order_model;

class TablesProvider with ChangeNotifier {
  final TablesService _tablesService = TablesService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<RestaurantTable> _tables = [];
  bool _isLoading = false;
  String? _tenantId;
  StreamSubscription? _tablesSubscription;
  OrdersProvider? _ordersProvider;

  List<RestaurantTable> get tables => _tables;
  bool get isLoading => _isLoading;

  int get totalTablesCount => _tables.length;
  
  int get activeSessionsCount => _tables.where((t) => t.status.hasActiveSession).length;
  
  int get billRequestsCount => _tables.where((t) => t.status == TableStatus.billRequested).length;
  
  int get vacantTablesCount => _tables.where((t) => t.status.canAcceptCustomers).length;

  void initialize(String tenantId, {OrdersProvider? ordersProvider}) {
    print('🔥 TablesProvider: Initialize called for tenant: $tenantId');
    _ordersProvider = ordersProvider;
    if (_tenantId == tenantId) {
      print('🔥 TablesProvider: Already initialized for $tenantId, tables count: ${_tables.length}');
      if (_tables.isNotEmpty && _ordersProvider != null) {
        _syncTablesWithOrders();
      }
      return;
    }
    
    print('🔥 TablesProvider: Setting up new subscription for $tenantId');
    _tablesSubscription?.cancel();
    _tenantId = tenantId;
    _isLoading = true;
    notifyListeners();

    _tablesSubscription = _tablesService.getTablesStream(tenantId).listen(
      (tables) {
        print('🔥 TablesProvider: Received ${tables.length} tables from stream');
        _tables = tables;
        _isLoading = false;
        if (_ordersProvider != null) {
          _syncTablesWithOrders();
        }
        notifyListeners();
      },
      onError: (error) {
        print('❌ TablesProvider: Stream error: $error');
        _isLoading = false;
        _tables = [];
        notifyListeners();
      },
      onDone: () {
        print('🔥 TablesProvider: Stream closed');
      },
    );
  }

  /// Automatically heals the state by syncing table physical status with order data
  void _syncTablesWithOrders() {
    if (_ordersProvider == null || _tables.isEmpty || _tenantId == null) return;

    final activeOrders = _ordersProvider!.orders.where((o) => 
      o.status != order_model.OrderStatus.completed && 
      o.status != order_model.OrderStatus.cancelled
    ).toList();

    // Mapping of tableId -> activeOrder count
    final Map<String, int> tableActiveOrders = {};
    for (var o in activeOrders) {
      if (o.tableId != null) {
        tableActiveOrders[o.tableId!] = (tableActiveOrders[o.tableId!] ?? 0) + 1;
      }
    }

    for (final table in _tables) {
       final hasActiveOrders = tableActiveOrders.containsKey(table.id);
       
       if (hasActiveOrders && table.status == TableStatus.available) {
          print('🛠️ Auto-Sync: Marking table ${table.name} as occupied due to active order');
          updateTable(table.copyWith(
            isOccupied: true,
            isAvailable: false,
            status: TableStatus.occupied,
            occupiedAt: activeOrders.firstWhere((o) => o.tableId == table.id).createdAt,
          ));
       } else if (!hasActiveOrders && table.status == TableStatus.occupied && table.lastReleasedAt != null) {
          // If a table is occupied but has TRULY no orders, and it's been more than 30 mins since last released
          // we could potentially auto-heal, but usually it's best to only do this for specific stale cases
          // to avoid clearing a table that just sat down.
          
          final now = DateTime.now();
          if (table.occupiedAt != null && now.difference(table.occupiedAt!).inHours > 6) {
             print('🛠️ Auto-Sync: Releasing STALE table ${table.name} (Older than 6h with no orders)');
             releaseTable(table.id);
          }
       }
    }
  }

  Future<void> updateTable(RestaurantTable table) async {
    if (_tenantId == null) return;
    await _tablesService.updateTable(_tenantId!, table);
  }

  Future<void> addTable(RestaurantTable table) async {
    if (_tenantId == null) return;
    await _tablesService.addTable(_tenantId!, table);
  }

  Future<void> deleteTable(String tableId) async {
    if (_tenantId == null) return;
    await _tablesService.deleteTable(_tenantId!, tableId);
  }

  Future<void> releaseTable(String tableId) async {
    if (_tenantId == null) return;
    
    try {
      // 1. Mark all active orders for this table as completed using provider
      if (_ordersProvider != null) {
        final activeOrders = _ordersProvider!.orders.where((order) =>
          order.tableId == tableId
        ).toList();
        
        for (final order in activeOrders) {
          await _ordersProvider!.markAsPaid(order.id);
        }
        
        print('🔓 Released table $tableId - Completed ${activeOrders.length} orders via provider');
      }
      
      // 2. Update table status to available and track last released timestamp
      final table = _tables.firstWhere((t) => t.id == tableId);
      await updateTable(table.copyWith(
        status: TableStatus.available,
        isAvailable: true,
        isOccupied: false,
        currentSessionId: null,
        occupiedAt: null,
        lastReleasedAt: DateTime.now(), // Tracking for Bug #6
      ));
    } catch (e) {
      print('Error releasing table: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _tablesSubscription?.cancel();
    super.dispose();
  }
}
