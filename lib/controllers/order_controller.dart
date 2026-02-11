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
  final List<OrderDetails> _activeOrders = <OrderDetails>[];
  final List<OrderDetails> _pastOrders = <OrderDetails>[];
  StreamSubscription<QuerySnapshot>? _ordersSubscription;
  StreamSubscription<QuerySnapshot>? _tableOrdersSubscription;
  final Map<String, StreamSubscription> _orderStatusSubscriptions = {};
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
  List<OrderDetails> get activeOrders => _activeOrders.toList();
  List<OrderDetails> get pastOrders => _pastOrders.toList();

  Future<void> setSession(String tenantId, String? tableId, {String? sessionId}) async {
    // Get guest ID first
    final guestId = await _guestSession.getGuestId();

    if (sessionId != null) {
      _currentSession = OrderSession(
        orderId: DateTime.now().millisecondsSinceEpoch.toString(),
        tableId: tableId,
        tenantId: tenantId,
        type: _currentOrderType,
        timestamp: DateTime.now(),
        guestId: guestId,
        sessionId: sessionId,
      );
    } else {
      _currentSession = OrderSession.create(
        guestId: guestId,
        tenantId: tenantId,
        type: _currentOrderType,
        tableId: tableId,
      );
    }

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
    await _firestore
        .collection('tenants')
        .doc(_currentSession!.tenantId)
        .collection('orders')
        .add({
      'guestId': guestId,
      'tenantId': _currentSession!.tenantId,
      'type': type.name,
      'tableId': _currentSession!.tableId,
      'status': OrderStatus.pending.name,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(), // Added for consistency with Admin model
      'items': [], // Will be populated when order is placed
      'subtotal': 0,
      'tax': 0,
      'total': 0,
      'sessionId': _currentSession!.sessionId, // Persist session ID
    });

    await setOrderType(type);

    // Initialize tracking after session is set
    await _initializeOrderTracking();

    notifyListeners();
    return _currentSession!;
  }

  // Subscribe to order status changes
  void _subscribeToOrderStatus(String orderId, String tenantId) {
    if (_orderStatusSubscriptions.containsKey(orderId)) return;

    _orderStatusSubscriptions[orderId] = _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      
      final updatedOrder = OrderDetails.fromMap(doc.data()!..['id'] = doc.id);
      final index = _activeOrders.indexWhere((o) => o.orderId == orderId);
      
      if (index != -1) {
        _activeOrders[index] = updatedOrder;
        notifyListeners();
      }
    });
  }

  void _pruneOrderStatusSubscriptions(Set<String> activeOrderIds) {
    final stale = _orderStatusSubscriptions.keys.where((id) => !activeOrderIds.contains(id)).toList();
    for (final id in stale) {
      _orderStatusSubscriptions[id]?.cancel();
      _orderStatusSubscriptions.remove(id);
    }
  }

  bool _isPaymentCompleted = false;
  bool get isPaymentCompleted => _isPaymentCompleted;

  void acknowledgePayment() {
    _isPaymentCompleted = false;
    notifyListeners();
  }

  // Initialize real-time order tracking
  Future<void> _initializeOrderTracking() async {
    if (_currentSession == null) {
      print('❌ No current session, skipping order tracking initialization');
      return;
    }

    final guestId = _currentSession!.guestId;
    final tenantId = _currentSession!.tenantId;
    final tableId = _currentSession!.tableId;

    print(
      '🚀 Initializing order tracking for guest: $guestId, tenant: $tenantId, table: $tableId',
    );

    // Cancel existing subscriptions if any
    await _ordersSubscription?.cancel();
    await _tableOrdersSubscription?.cancel();

    print('📍 Setting up unified orders listener: tenants/$tenantId/orders');

    // Listen to ALL orders from unified location, filtered by guestId
    // Show all orders except cancelled (pending, preparing, served)
    _ordersSubscription = _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('orders')
        .where('guestId', isEqualTo: guestId)
        .snapshots()
        .listen((snapshot) {
          print(
            '📦 Received ${snapshot.docs.length} orders from unified collection',
          );

          // Clear existing orders
          _activeOrders.clear();
          _pastOrders.clear();

          for (final doc in snapshot.docs) {
            final orderData = doc.data();
            
            try {
              final orderDetails = OrderDetails.fromMap(orderData);
              
              final isPast = orderDetails.status == OrderStatus.cancelled || 
                             orderDetails.status == OrderStatus.completed;
              
              // If we have a tableId filter, only show orders for this table AND session (dine-in)
              // Otherwise show all orders for this guest
              if (tableId != null && orderDetails.type == OrderType.dineIn) {
                if (orderDetails.tableId == tableId && orderDetails.sessionId == _currentSession?.sessionId) {
                  if (isPast) {
                    _pastOrders.add(orderDetails);
                  } else {
                    _activeOrders.add(orderDetails);
                    _subscribeToOrderStatus(orderDetails.orderId, tenantId);
                  }
                }
              } else if (orderDetails.type == OrderType.parcel) {
                // Show all active orders (parcel orders)
                if (isPast) {
                  _pastOrders.add(orderDetails);
                } else {
                  _activeOrders.add(orderDetails);
                  _subscribeToOrderStatus(orderDetails.orderId, tenantId);
                }
              }
            } catch (e) {
              print('Error parsing order ${doc.id}: $e');
            }
          }

          print(
            '📊 Total active orders: ${_activeOrders.length}, Past orders: ${_pastOrders.length}',
          );
          // Sort by timestamp, newest first
          _activeOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _pastOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _pruneOrderStatusSubscriptions(_activeOrders.map((o) => o.orderId).toSet());

          // REQUIREMENT: Detect when all orders for this session are PAID
          // Instead of silent clearing, we trigger a flag for the UI to show the prompt
          if (tableId != null && _activeOrders.isEmpty && _pastOrders.isNotEmpty) {
            final latestPastOrder = _pastOrders.first;
            if (latestPastOrder.status == OrderStatus.completed) {
              if (!_isPaymentCompleted) {
                 debugPrint('💰 [GOAL] All orders PAID for table $tableId. Triggering customer prompt.');
                 _isPaymentCompleted = true;
              }
            }
          }

          notifyListeners();
        });
  }



  // Check if there are active orders for the current table
  bool hasActiveTableOrders(String tableId) {
    return _activeOrders.any(
      (order) =>
          order.tableId == tableId &&
          order.type == OrderType.dineIn &&
          order.status == OrderStatus.pending,
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
  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _tableOrdersSubscription?.cancel();
    for (var sub in _orderStatusSubscriptions.values) {
      sub.cancel();
    }
    _orderStatusSubscriptions.clear();
    super.dispose();
  }
}
