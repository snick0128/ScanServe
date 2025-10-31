import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/order_model.dart';
import '../models/order_details.dart';
import '../services/guest_session_service.dart';
import '../services/payment_service.dart';

class OrderController extends ChangeNotifier {
  static const String _orderTypeKey = 'last_order_type';
  final _guestSession = GuestSessionService();
  final _prefs = SharedPreferences.getInstance();
  final _firestore = FirebaseFirestore.instance;

  OrderType _currentOrderType = OrderType.dineIn;
  OrderSession? _currentSession;
  final List<OrderDetails> _activeOrders = [];
  StreamSubscription<QuerySnapshot>? _ordersSubscription;
  StreamSubscription<QuerySnapshot>? _tableOrdersSubscription;
  final PaymentService _paymentService = PaymentService();
  String? _chefNote;

  String get chefNote => _chefNote ?? '';

  void updateChefNote(String? note) {
    if (_chefNote != note) {
      _chefNote = note?.trim();
      notifyListeners();
    }
  }

  OrderController() {
    // Don't initialize tracking in constructor, do it after session is set
  }

  OrderType get currentOrderType => _currentOrderType;
  OrderSession? get currentSession => _currentSession;
  List<OrderDetails> get activeOrders => List.unmodifiable(_activeOrders);

  void setSession(String tenantId, String? tableId) async {
    // Get guest ID first
    final guestId = await _guestSession.getGuestId();

    _currentSession = OrderSession.create(
      guestId: guestId,
      tenantId: tenantId,
      type: _currentOrderType,
      tableId: tableId,
    );

    // Initialize order tracking with proper session
    await _initializeOrderTracking();
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
    // Re-initialize tracking when order type changes
    if (_currentSession != null) {
      await _initializeOrderTracking();
    }
    notifyListeners();
  }

  // Create new order session
  Future<OrderSession> createOrderSession(
    OrderType type, {
    String? tenantId,
    String? tableId,
  }) async {
    final guestId = await _guestSession.getGuestId();

    _currentSession = OrderSession.create(
      guestId: guestId,
      tenantId: tenantId ?? _currentSession?.tenantId ?? '',
      type: type,
      tableId: type == OrderType.dineIn
          ? (tableId ?? _currentSession?.tableId ?? '')
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

    // Initialize tracking after session is set
    await _initializeOrderTracking();

    notifyListeners();
    return _currentSession!;
  }

  // Initialize real-time order tracking
  Future<void> _initializeOrderTracking() async {
    if (_currentSession == null) {
      print('❌ No current session, skipping order tracking initialization');
      return;
    }

    final guestId = _currentSession!.guestId;
    final tenantId = _currentSession!.tenantId;

    print(
      '🚀 Initializing order tracking for guest: $guestId, tenant: $tenantId',
    );

    // Cancel existing subscriptions if any
    await _ordersSubscription?.cancel();
    await _tableOrdersSubscription?.cancel();

    print('📍 Setting up parcel orders listener: tenants/$tenantId/orders');

    // Listen to parcel orders (main tenant orders collection)
    _ordersSubscription = _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('orders')
        .where('guestId', isEqualTo: guestId)
        .where(
          'status',
          whereNotIn: [OrderStatus.completed.name, OrderStatus.confirmed.name],
        )
        .snapshots()
        .listen((snapshot) {
          print(
            '📦 Received ${snapshot.docs.length} parcel orders from tenant collection',
          );

          // Remove existing parcel orders to avoid duplicates
          _activeOrders.removeWhere((order) => order.type == OrderType.parcel);

          for (final doc in snapshot.docs) {
            final orderData = doc.data();
            final orderType = OrderType.values.firstWhere(
              (type) => type.name == orderData['type'],
              orElse: () => OrderType.parcel,
            );

            if (orderType == OrderType.parcel) {
              print('➕ Adding parcel order: ${orderData['orderId']}');
              _activeOrders.add(OrderDetails.fromMap(orderData));
            }
          }

          print(
            '📊 Total active orders after parcel update: ${_activeOrders.length}',
          );
          // Sort by timestamp, newest first
          _activeOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          notifyListeners();
        });

    // Listen to dine-in orders if we have a table
    if (_currentSession?.tableId != null) {
      final tableId = _currentSession!.tableId!;
      print(
        '🍽️ Setting up dine-in orders listener: tenants/$tenantId/tables/$tableId/orders',
      );

      _tableOrdersSubscription = _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('tables')
          .doc(tableId)
          .collection('orders')
          .where('guestId', isEqualTo: guestId)
          .where(
            'status',
            whereNotIn: [
              OrderStatus.completed.name,
              OrderStatus.confirmed.name,
            ],
          )
          .snapshots()
          .listen((snapshot) {
            print(
              '🍽️ Received ${snapshot.docs.length} dine-in orders from table collection',
            );

            // Remove existing dine-in orders to avoid duplicates
            _activeOrders.removeWhere(
              (order) => order.type == OrderType.dineIn,
            );

            for (final doc in snapshot.docs) {
              final orderData = doc.data();
              // Add tenantId from the path since it's not in the document
              orderData['tenantId'] = tenantId;

              final orderType = OrderType.values.firstWhere(
                (type) => type.name == orderData['type'],
                orElse: () => OrderType.dineIn,
              );

              if (orderType == OrderType.dineIn) {
                print('➕ Adding dine-in order: ${orderData['orderId']}');
                _activeOrders.add(OrderDetails.fromMap(orderData));
              }
            }

            print(
              '📊 Total active orders after dine-in update: ${_activeOrders.length}',
            );
            // Sort by timestamp, newest first
            _activeOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            notifyListeners();
          });
    } else {
      print('⚠️ No table ID, skipping dine-in orders listener');
    }
  }

  // Check if there are active orders for the current table
  bool hasActiveTableOrders(String tableId) {
    return _activeOrders.any(
      (order) =>
          order.tableId == tableId &&
          order.type == OrderType.dineIn &&
          (order.status == OrderStatus.pending ||
              order.status == OrderStatus.confirmed),
    );
  }

  // Force refresh order tracking (for debugging)
  Future<void> refreshOrderTracking() async {
    print('🔄 Force refreshing order tracking');
    await _initializeOrderTracking();
  }

  // Debug method to print current state
  void debugPrintState() {
    print('=== ORDER CONTROLLER DEBUG STATE ===');
    print(
      'Current session: ${_currentSession?.tenantId}/${_currentSession?.tableId}',
    );
    print('Current order type: $_currentOrderType');
    print('Active orders count: ${_activeOrders.length}');
    print('Active orders:');
    for (var order in _activeOrders) {
      print(
        '  - ${order.orderId}: ${order.type.name} (${order.status.name}) - Payment: ${order.paymentStatus.name}',
      );
    }
    print('=====================================');
  }

  // Get payment status for a specific order
  Future<PaymentStatus> getOrderPaymentStatus(String orderId) async {
    if (_currentSession == null) return PaymentStatus.pending;

    return await _paymentService.getPaymentStatus(
      orderId,
      _currentSession!.tenantId,
    );
  }

  // Update payment status for an order (called by payment service)
  Future<void> updateOrderPaymentStatus(
    String orderId,
    PaymentStatus status,
  ) async {
    final orderIndex = _activeOrders.indexWhere(
      (order) => order.orderId == orderId,
    );
    if (orderIndex != -1) {
      // Update the order in the local list
      final updatedOrder = OrderDetails(
        orderId: _activeOrders[orderIndex].orderId,
        guestId: _activeOrders[orderIndex].guestId,
        tableId: _activeOrders[orderIndex].tableId,
        tenantId: _activeOrders[orderIndex].tenantId,
        type: _activeOrders[orderIndex].type,
        items: _activeOrders[orderIndex].items,
        timestamp: _activeOrders[orderIndex].timestamp,
        status: _activeOrders[orderIndex].status,
        estimatedWaitTime: _activeOrders[orderIndex].estimatedWaitTime,
        subtotal: _activeOrders[orderIndex].subtotal,
        tax: _activeOrders[orderIndex].tax,
        total: _activeOrders[orderIndex].total,
        paymentStatus: status,
        paymentMethod: _activeOrders[orderIndex].paymentMethod,
        customerName: _activeOrders[orderIndex].customerName,
        customerPhone: _activeOrders[orderIndex].customerPhone,
        paymentId: _activeOrders[orderIndex].paymentId,
        paymentTimestamp: _activeOrders[orderIndex].paymentTimestamp,
      );

      _activeOrders[orderIndex] = updatedOrder;
      notifyListeners();
    }
  }
}
