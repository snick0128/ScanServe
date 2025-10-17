import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/order_model.dart';
import '../models/order_details.dart';
import '../services/guest_session_service.dart';

class OrderController extends ChangeNotifier {
  static const String _orderTypeKey = 'last_order_type';
  final _guestSession = GuestSessionService();
  final _prefs = SharedPreferences.getInstance();
  final _firestore = FirebaseFirestore.instance;

  OrderType _currentOrderType = OrderType.dineIn;
  OrderSession? _currentSession;
  final List<OrderDetails> _activeOrders = [];
  StreamSubscription<QuerySnapshot>? _ordersSubscription;

  OrderController() {
    _initializeOrderTracking();
  }

  OrderType get currentOrderType => _currentOrderType;
  OrderSession? get currentSession => _currentSession;
  List<OrderDetails> get activeOrders => List.unmodifiable(_activeOrders);

  void setSession(String tenantId, String? tableId) {
    _currentSession = OrderSession.create(
      guestId: '', // Will be set later
      tenantId: tenantId,
      type: _currentOrderType,
      tableId: tableId,
    );
    notifyListeners();
  }

  // Load last used order type from preferences
  Future<OrderType?> loadLastOrderType() async {
    final prefs = await _prefs;
    final savedType = prefs.getString(_orderTypeKey);
    if (savedType != null) {
      _currentOrderType = OrderType.values.firstWhere(
        (type) => type.name == savedType,
        orElse: () => OrderType.dineIn,
      );
      notifyListeners();
    }
    return _currentOrderType;
  }

  // Set and save order type
  Future<void> setOrderType(OrderType type) async {
    _currentOrderType = type;
    final prefs = await _prefs;
    await prefs.setString(_orderTypeKey, type.name);
    notifyListeners();
  }

  // Create new order session
  Future<OrderSession> createOrderSession(
    OrderType type, {
    String? tenantId,
    String? tableId,
  }) async {
    final session = await _guestSession.getCurrentSession();
    final guestId = session['guestId'] ?? '';

    _currentSession = OrderSession.create(
      guestId: guestId,
      tenantId: tenantId ?? _currentSession?.tenantId ?? '',
      type: type,
      tableId: type == OrderType.dineIn
          ? (tableId ?? _currentSession?.tableId ?? session['tableId'])
          : null,
    );

    // Save the session to Firestore which will trigger the real-time listener
    await _firestore.collection('orders').add({
      'guestId': guestId,
      'tenantId': _currentSession!.tenantId,
      'type': type.name,
      'tableId': _currentSession!.tableId,
      'status': OrderStatus.pending.name,
      'timestamp': FieldValue.serverTimestamp(),
      'estimatedWaitTime': 0, // Will be updated by the restaurant
      'items': [], // Will be populated when order is placed
      'subtotal': 0,
      'tax': 0,
      'total': 0,
    });

    await setOrderType(type);
    notifyListeners();
    return _currentSession!;
  }

  // Initialize real-time order tracking
  Future<void> _initializeOrderTracking() async {
    final session = await _guestSession.getCurrentSession();
    final guestId = session['guestId'] ?? '';

    // Cancel existing subscription if any
    await _ordersSubscription?.cancel();

    // Listen to orders for the current guest
    _ordersSubscription = _firestore
        .collection('orders')
        .where('guestId', isEqualTo: guestId)
        .where('status', whereNotIn: [OrderStatus.completed.name])
        .snapshots()
        .listen((snapshot) {
          _activeOrders.clear();
          for (final doc in snapshot.docs) {
            _activeOrders.add(OrderDetails.fromMap(doc.data()));
          }
          // Sort by timestamp, newest first
          _activeOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          notifyListeners();
        });
  }

  // Check if there are active orders for the current table
  bool hasActiveTableOrders(String tableId) {
    return _activeOrders.any(
      (order) =>
          order.tableId == tableId &&
          order.type == OrderType.dineIn &&
          order.status != OrderStatus.completed,
    );
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
