import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/order.dart' as model;
import '../../models/tenant_model.dart';

class AnalyticsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _tenantId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _dateFilter = 'Today';

  bool _isLoading = false;
  
  double _totalRevenue = 0;
  int _totalOrders = 0;
  double _avgOrderValue = 0;
  int _activeTablesCount = 0;
  
  Map<int, double> _hourlyRevenue = {};
  List<Map<String, dynamic>> _topItems = [];
  Map<String, double> _categorySales = {};

  // Trends
  double _revenueTrend = 0;
  double _ordersTrend = 0;
  double _aovTrend = 0;
  double _tablesTrend = 0;

  // Getters
  bool get isLoading => _isLoading;
  double get totalRevenue => _totalRevenue;
  int get totalOrders => _totalOrders;
  double get avgOrderValue => _avgOrderValue;
  int get activeTablesCount => _activeTablesCount;
  String get dateFilter => _dateFilter;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  
  double get revenueTrend => _revenueTrend;
  double get ordersTrend => _ordersTrend;
  double get aovTrend => _aovTrend;
  double get tablesTrend => _tablesTrend;

  Map<int, double> get hourlyRevenue => _hourlyRevenue;
  List<Map<String, dynamic>> get topItems => _topItems;
  Map<String, double> get categorySales => _categorySales;

  void initialize(String tenantId) {
    if (_tenantId == tenantId) return;
    _tenantId = tenantId;
    setDateFilter('Today');
  }

  Future<void> setDateFilter(String filter) async {
    _dateFilter = filter;
    final now = DateTime.now();
    
    switch (filter) {
      case 'Today':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
        break;
      case 'Week':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
        _endDate = now;
        break;
      case 'Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
    }
    
    await refreshData();
  }

  Future<void> setCustomDateRange(DateTime start, DateTime end) async {
    _dateFilter = 'Custom';
    _startDate = start;
    _endDate = end;
    await refreshData();
  }

  Future<void> refreshData() async {
    if (_tenantId == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      // Use normalized boundaries
      final startBoundary = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endBoundary = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      debugPrint('📊 Analytics Refreshing: $startBoundary to $endBoundary');

      // 1. Fetch Orders regardless of index (Bypass composite index requirements)
      // We fetch all recent orders and filter in-memory for maximum reliability
      Query ordersQueryBuilder = _firestore.collectionGroup('orders');
      
      final ordersSnapshot = await ordersQueryBuilder.get();
      debugPrint('📊 Analytics: Found raw ${ordersSnapshot.docs.length} orders in DB');

      _totalRevenue = 0;
      _totalOrders = 0;
      _hourlyRevenue = Map.fromIterable(List.generate(24, (i) => i), key: (i) => i, value: (_) => 0.0);
      
      Map<String, int> itemUnits = {};
      Map<String, double> itemRevenue = {};
      Map<String, Map<String, dynamic>> itemDetails = {};
      Map<String, double> catSales = {};

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Filter by Tenant in-memory
        if (_tenantId != 'global' && data['tenantId'] != _tenantId) continue;

        // Priority timestamp
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? 
                          (data['timestamp'] as Timestamp?)?.toDate();
        
        if (createdAt == null) continue;
        if (createdAt.isBefore(startBoundary) || createdAt.isAfter(endBoundary)) continue;

        // Count as revenue if Paid OR formally Completed/Served
        final pStatus = data['paymentStatus'] as String?;
        final orderStatus = data['status'] as String?;
        final isCompleted = orderStatus == 'completed' || orderStatus == 'served';
        final isPaid = pStatus == 'paid';

        if (!isPaid && !isCompleted) continue;

        _totalOrders++;
        final amount = (data['total'] ?? (data['totalAmount'] ?? 0)).toDouble();
        _totalRevenue += amount;
        _hourlyRevenue[createdAt.hour] = (_hourlyRevenue[createdAt.hour] ?? 0) + amount;

        final items = (data['items'] as List? ?? []);
        for (var itemData in items) {
          final item = Map<String, dynamic>.from(itemData);
          final name = item['name'] ?? 'Unknown';
          final qty = (item['quantity'] ?? 1) as int;
          final price = (item['price'] ?? 0).toDouble();
          final category = item['category'] ?? 'Others';
          
          itemUnits[name] = (itemUnits[name] ?? 0) + qty;
          itemRevenue[name] = (itemRevenue[name] ?? 0) + (qty * price);
          itemDetails[name] = item;
          catSales[category] = (catSales[category] ?? 0) + (qty * price);
        }
      }
      debugPrint('📊 Analytics: Processed $_totalOrders total relevant orders');
      _avgOrderValue = _totalOrders > 0 ? _totalRevenue / _totalOrders : 0;

      _categorySales = catSales;

      // Sort top items
      var sortedItems = itemRevenue.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      _topItems = sortedItems.take(5).map((e) {
        final details = itemDetails[e.key] ?? {};
        return {
          'name': e.key,
          'units': itemUnits[e.key] ?? 0,
          'revenue': e.value,
          'imageUrl': details['imageUrl'],
          'isBestseller': details['isBestseller'] ?? false,
        };
      }).toList();

      // Active Tables
      if (_tenantId == 'global') {
        final tableQuery = await _firestore.collectionGroup('tables').where('status', isEqualTo: 'occupied').get();
        _activeTablesCount = tableQuery.size;
      } else {
        final tableQuery = await _firestore
            .collection('tenants')
            .doc(_tenantId)
            .collection('tables')
            .where('status', isEqualTo: 'occupied')
            .get();
        _activeTablesCount = tableQuery.size;
      }

      // Trends (Simulated for now based on some randomness to show UI, 
      // in real it would compare with previous period)
      _revenueTrend = 12.5; 
      _ordersTrend = 5.2;
      _aovTrend = -2.1;
      _tablesTrend = 4.0;

    } catch (e) {
      print('Error refreshing analytics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
