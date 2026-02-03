import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import './orders_provider.dart';
import '../../models/order.dart' as model;
import '../../services/bill_service.dart';

class ActiveSession {
  final String tableId;
  final String? tableName;
  final String? guestId;
  final String? customerName;
  final double totalAmount;
  final DateTime sessionStartedAt;
  final List<String> orderIds;

  ActiveSession({
    required this.tableId,
    this.tableName,
    this.guestId,
    this.customerName,
    required this.totalAmount,
    required this.sessionStartedAt,
    required this.orderIds,
  });
}

class BillsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _allBills = [];
  bool _isLoading = false;
  String? _tenantId;
  StreamSubscription? _billsSubscription;
  OrdersProvider? _ordersProvider;

  List<Map<String, dynamic>> get allBills => _allBills;
  bool get isLoading => _isLoading;

  void initialize(String tenantId, {OrdersProvider? ordersProvider}) {
    if (_tenantId == tenantId) return;
    
    _tenantId = tenantId;
    _ordersProvider = ordersProvider;
    _listenToBills();
  }

  void _listenToBills() {
    _billsSubscription?.cancel();
    if (_tenantId == null) return;

    _isLoading = true;
    notifyListeners();

    final Query query;
    if (_tenantId == 'global') {
      query = _firestore.collectionGroup('bills').limit(100);
    } else {
      query = _firestore
          .collection('tenants')
          .doc(_tenantId)
          .collection('bills');
    }

    _billsSubscription = query
        .snapshots()
        .listen((snapshot) {
      _allBills = snapshot.docs.map((doc) => {
        ...(doc.data() as Map<String, dynamic>), 
        'id': doc.id
      }).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      print('❌ BillsProvider Error: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  // Active Sessions (Pending Bills)
  List<ActiveSession> get activeSessions {
    if (_ordersProvider == null) return [];
    
    final activeOrders = _ordersProvider!.allOrders.where((o) => 
      o.status != model.OrderStatus.completed && 
      o.status != model.OrderStatus.cancelled
    ).toList();

    final sessionsMap = <String, ActiveSession>{};

    for (var order in activeOrders) {
      if (order.tableId == null) continue;
      
      if (sessionsMap.containsKey(order.tableId)) {
        final existing = sessionsMap[order.tableId]!;
        sessionsMap[order.tableId!] = ActiveSession(
          tableId: existing.tableId,
          tableName: existing.tableName,
          guestId: existing.guestId,
          customerName: existing.customerName ?? order.customerName,
          totalAmount: existing.totalAmount + order.total,
          sessionStartedAt: existing.sessionStartedAt.isBefore(order.createdAt) 
              ? existing.sessionStartedAt 
              : order.createdAt,
          orderIds: [...existing.orderIds, order.id],
        );
      } else {
        sessionsMap[order.tableId!] = ActiveSession(
          tableId: order.tableId!,
          tableName: order.tableName,
          guestId: order.guestId,
          customerName: order.customerName,
          totalAmount: order.total,
          sessionStartedAt: order.createdAt,
          orderIds: [order.id],
        );
      }
    }

    return sessionsMap.values.toList();
  }

  // KPI Calculations
  double get totalPendingAmount {
    return activeSessions.fold(0, (sum, s) => sum + s.totalAmount);
  }

  int get activeSessionsCount => activeSessions.length;

  int get completedTodayCount {
    final today = DateTime.now();
    return _allBills.where((bill) {
      final createdAt = (bill['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) return false;
      return createdAt.day == today.day && 
             createdAt.month == today.month && 
             createdAt.year == today.year;
    }).length;
  }

  double get completedTodayVolume {
    final today = DateTime.now();
    return _allBills.where((bill) {
      final createdAt = (bill['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) return false;
      return createdAt.day == today.day && 
             createdAt.month == today.month && 
             createdAt.year == today.year;
    }).fold(0, (sum, bill) => sum + (bill['finalTotal'] ?? 0).toDouble());
  }

  double get yesterdayCompletedVolume {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _allBills.where((bill) {
      final createdAt = (bill['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) return false;
      return createdAt.day == yesterday.day && 
             createdAt.month == yesterday.month && 
             createdAt.year == yesterday.year;
    }).fold(0, (sum, bill) => sum + (bill['finalTotal'] ?? 0).toDouble());
  }

  String get pendingTrend {
    if (yesterdayCompletedVolume == 0) return '0%';
    final trend = ((completedTodayVolume - yesterdayCompletedVolume) / yesterdayCompletedVolume) * 100;
    return '${trend > 0 ? '+' : ''}${trend.toStringAsFixed(1)}%';
  }

  Future<String?> markAsPaid(String tableId, List<String> orderIds, {String? paymentMethod, String? note}) async {
    if (_tenantId == null || _ordersProvider == null) return null;
    
    try {
      // 1. Get current orders for this session
      final orders = _ordersProvider!.allOrders
          .where((o) => orderIds.contains(o.id))
          .toList();
      
      if (orders.isEmpty) return null;

      // 2. Generate the bill record
      final billService = BillService();
      final billId = await billService.generateBill(
        tenantId: _tenantId!,
        tableId: tableId,
        orders: orders,
        paymentMethod: paymentMethod,
        note: note,
      );

      // 3. Close the table session
      await _ordersProvider!.markTableAsPaid(tableId);
      
      return billId;
    } catch (e) {
      print('❌ Error in markAsPaid flow: $e');
      rethrow;
    }
  }

  Future<void> bulkCloseSessions() async {
    if (_tenantId == null || _ordersProvider == null) return;
    final sessions = activeSessions;
    for (var session in sessions) {
      await _ordersProvider!.markTableAsPaid(session.tableId);
    }
  }

  void refreshBills() {
    _listenToBills();
  }

  @override
  void dispose() {
    _billsSubscription?.cancel();
    super.dispose();
  }
}
