import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './activity_provider.dart';
import '../../models/activity_log_model.dart';
import '../../models/order.dart' as model; // Imported the shared model
import './admin_auth_provider.dart';
import '../../services/menu_service.dart';
import '../../services/inventory_service.dart';
import '../../models/tenant_model.dart';
import '../services/print_service.dart';

class OrdersProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<model.Order> _orders = [];
  List<model.Order> _pastOrdersList = [];
  bool _hasPastOrdersIndexError = false;
  bool get hasPastOrdersIndexError => _hasPastOrdersIndexError;
  bool _isLoading = false;
  String? _tenantId;
  String? _error;
  Map<String, dynamic> _tenantSettings = {};
  AdminAuthProvider? _auth;
  ActivityProvider? _activity;
  StreamSubscription<QuerySnapshot>? _ordersSubscription;
  StreamSubscription<QuerySnapshot>? _pastOrdersSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundEnabled = true;
  bool get isSoundEnabled => _isSoundEnabled;

  void toggleSound(bool enabled) async {
    _isSoundEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSoundEnabled', enabled);
  }
  final PrintService _printService = PrintService();
  DateTime? _lastOrderTime;
  bool _isFirstLoad = true;
  bool _isSynced = false;
  final Map<String, StreamSubscription> _orderSubscriptions = {};
  final Map<String, Timer> _prepTimers = {};
  model.Order? _latestNewOrder;
  model.Order? get latestNewOrder => _latestNewOrder;

  void clearLatestNewOrder() {
    _latestNewOrder = null;
    notifyListeners();
  }
  
  // Firestore collections
  CollectionReference get _ordersCollection => _firestore.collection('orders');
  CollectionReference get _tenantOrdersCollection {
    if (_tenantId == null) throw Exception('Tenant ID not set');
    return _firestore.collection('tenants').doc(_tenantId).collection('orders');
  }

  // Getters
  List<model.Order> get orders => _orders;

  List<model.Order> get currentOrders => _orders.where((o) => 
    o.status != model.OrderStatus.completed && 
    o.status != model.OrderStatus.cancelled
  ).toList();

  List<model.Order> get kdsOrders => _orders.where((o) {
    if (o.status == model.OrderStatus.completed || o.status == model.OrderStatus.cancelled) return false;
    
    // PRINCIPLE 1: stays visible until ALL items are SERVED
    // We check if there are any items NOT served
    bool hasUnservedItems = o.items.any((i) => i.status != model.OrderItemStatus.served);
    
    // If there are unserved items, keep it in KDS
    if (hasUnservedItems) return true;
    
    // If all items are served, it might still be visible for a short time or if not completed
    // But for strict KDS operational purity, once served, it moves to the "served" list.
    return false;
  }).toList();

  List<model.Order> get pastOrders => _pastOrdersList;
  
  int get currentOrdersCount => currentOrders.length;
  int get pastOrdersCount => _pastOrdersList.length;
  int get pendingPaymentOrdersCount => pendingPaymentOrders.length;

  List<model.Order> get pendingPaymentOrders => _orders.where((o) => 
    o.status == model.OrderStatus.served && o.paymentStatus == model.PaymentStatus.pending
  ).toList();


  List<model.Order> searchOrders(String query) {
    if (query.isEmpty) return _orders;
    final q = query.toLowerCase();
    return _orders.where((o) => 
      (o.tableName ?? '').toLowerCase().contains(q) ||
      o.id.toLowerCase().contains(q) ||
      o.items.any((i) => i.name.toLowerCase().contains(q))
    ).toList();
  }

  List<model.Order> get allOrders => _orders;
  bool get isLoading => _isLoading;
  bool get isSynced => _isSynced;
  String? get error => _error;
  String? get tenantId => _tenantId;
  Map<String, dynamic> get tenantSettings => _tenantSettings;

  // Initialize with tenant ID and optional logging
  void initialize(String tenantId, {AdminAuthProvider? auth, ActivityProvider? activity}) {
    // Pre-load sound source to avoid first-play block issues
    if (_isFirstLoad) {
      _audioPlayer.setSource(UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'))
        .catchError((e) => debugPrint('Audio preload error: $e'));
      _loadSoundSetting();
    }

    if (_tenantId == tenantId && _auth == auth && _activity == activity) return; 
    
    // Clean up existing subscriptions
    _ordersSubscription?.cancel();
    _pastOrdersSubscription?.cancel();
    for (var sub in _orderSubscriptions.values) {
      sub.cancel();
    }
    _orderSubscriptions.clear();
    
    _tenantId = tenantId;
    _auth = auth;
    _activity = activity;
    _isLoading = true;
    _orders = [];
    notifyListeners();
    
    _fetchTenantSettings();
    _listenToOrders();
    _listenToPastOrders();
  }

  Future<void> _fetchTenantSettings() async {
    if (_tenantId == null) return;
    try {
      final doc = await _firestore.collection('tenants').doc(_tenantId).get();
      if (doc.exists) {
        _tenantSettings = doc.data()?['settings'] ?? {};
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching tenant settings: $e');
    }
  }

  void _listenToPastOrders() {
    if (_tenantId == null) return;
    print('🔥 OrdersProvider: STARTING PAST ORDERS LISTENER for tenant: $_tenantId');
    
    final query = _tenantOrdersCollection
        .where('status', whereIn: ['completed', 'cancelled'])
        .orderBy('createdAt', descending: true)
        .limit(100);

    _pastOrdersSubscription = query.snapshots().listen((snapshot) {
      _pastOrdersList = snapshot.docs.map((doc) => model.Order.fromFirestore(doc)).toList();
      _hasPastOrdersIndexError = false;
      notifyListeners();
      print('📊 OrdersProvider: Past Orders Updated! Count: ${_pastOrdersList.length}');
    }, onError: (e) {
      if (e.toString().contains('failed-precondition') || e.toString().contains('index')) {
        _hasPastOrdersIndexError = true;
      }
      debugPrint('❌ Past Orders Listener Error: $e');
    });
  }

  void _listenToOrders() {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      if (_tenantId == null || _tenantId!.isEmpty) {
        _handleError('No tenant ID provided');
        return;
      }
      
      print('🔥 OrdersProvider: STARTING LISTENER for tenant: $_tenantId');

      final Query query;
      if (_tenantId == 'global') {
        print('🌍 OrdersProvider: Using GLOBAL CollectionGroup orders');
        query = _firestore.collectionGroup('orders')
            .where('status', whereNotIn: ['completed', 'cancelled'])
            .limit(200);
      } else {
        print('🏢 OrdersProvider: Using TENANT collection: tenants/$_tenantId/orders');
        query = _tenantOrdersCollection
            .where('status', whereNotIn: ['completed', 'cancelled'])
            .limit(100);
      }

      _ordersSubscription = query
          .snapshots()
          .listen(
        (snapshot) async {
          _isSynced = true;
          print('📊 OrdersProvider: Snapshot Received! Docs count: ${snapshot.docs.length}');
          try {
            final orders = <model.Order>[];
            final Set<String> seenIds = {};
            bool shouldAlert = false;

            for (var doc in snapshot.docs) {
              if (seenIds.contains(doc.id)) continue;
              seenIds.add(doc.id);

              try {
                // debugPrint('  - Processing order doc: ${doc.id}');
                final order = model.Order.fromFirestore(doc);
                orders.add(order);

                // Find if we already track this order for notifications
                final existingOrder = _orders.firstWhere(
                  (o) => o.id == order.id, 
                  orElse: () => model.Order(id: '', tenantId: '', items: [], subtotal: 0, tax: 0, total: 0, status: model.OrderStatus.pending, createdAt: DateTime.now())
                );
                
                if (!_isFirstLoad) {
                  if (existingOrder.id.isEmpty) {
                    shouldAlert = true;
                    _latestNewOrder = order;
                    print('🔔 New Order Alert: ${order.id}');
                    // Trigger Auto-Print for New Order
                    _printService.printKOT(order, isAddon: false);
                  } else {
                    // REQUIREMENT 4: Detect quantity increases or new items
                    final int existingTotalQuantity = existingOrder.items.fold(0, (sum, i) => sum + i.quantity);
                    final int newTotalQuantity = order.items.fold(0, (sum, i) => sum + i.quantity);
                    
                    if (newTotalQuantity > existingTotalQuantity) {
                      shouldAlert = true;
                      _latestNewOrder = order;
                      print('🔔 Add-on Alert for Order: ${order.id} (Quantity increased)');
                      _printService.printKOT(order, isAddon: true);
                    } else if (order.chefNote != existingOrder.chefNote && order.chefNote != null && order.chefNote!.isNotEmpty) {
                      shouldAlert = true;
                      _latestNewOrder = order;
                      print('🔔 Chef Note Alert for Order: ${order.id}');
                      _printService.printKOT(order, isAddon: true);
                    }
                  }
                }
              } catch (e) {
                debugPrint('❌ Error parsing order ${doc.id}: $e');
              }
            }

            orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (shouldAlert) {
              _playNotificationSound();
            }

            _isFirstLoad = false;
            _orders = orders;
            _isLoading = false;
            _error = null;
            debugPrint('📊 OrdersProvider: Successfully sync ${orders.length} active orders');
            notifyListeners();
            _handleAutoTransitions(orders);
          } catch (e) {
            _handleError('Error processing orders: $e');
          }
        },
        onError: (e) {
          _isSynced = false;
          debugPrint('❌ OrdersProvider Stream Error: $e');
          _handleError(e.toString());
        },
        cancelOnError: false,
      );
    } catch (e) {
      _handleError('Error setting up orders listener: $e');
    }
  }

  Future<void> loadPastOrders({DateTime? start, DateTime? end}) async {
    // Manual load for specific date ranges if needed
    if (_tenantId == null) return;
    
    try {
      Query query = _tenantOrdersCollection
          .where('status', whereIn: ['completed', 'cancelled']);

      if (start != null) query = query.where('createdAt', isGreaterThanOrEqualTo: start);
      if (end != null) query = query.where('createdAt', isLessThanOrEqualTo: end);

      query = query.orderBy('createdAt', descending: true).limit(100);

      final snapshot = await query.get();
      _pastOrdersList = snapshot.docs.map((doc) => model.Order.fromFirestore(doc)).toList();
      _hasPastOrdersIndexError = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading past orders: $e');
    }
  }

  void _handleAutoTransitions(List<model.Order> orders) {
    for (final order in orders) {
      // Automatic Preparing -> Ready transition after prep time
      if (order.status == model.OrderStatus.preparing) {
        _scheduleReadyTransition(order);
      } else {
        // Cancel existing timer if status changed away from preparing
        _prepTimers[order.id]?.cancel();
        _prepTimers.remove(order.id);
      }
    }
  }

  void _scheduleReadyTransition(model.Order order) {
    if (_prepTimers.containsKey(order.id)) return;

    final now = DateTime.now();
    final readyAt = order.createdAt.add(Duration(minutes: order.estimatedWaitTime));
    final remainingMillis = readyAt.difference(now).inMilliseconds;

    if (remainingMillis <= 0) {
      updateOrderStatus(order.id, model.OrderStatus.ready, isSystemAction: true);
    } else {
      _prepTimers[order.id] = Timer(Duration(milliseconds: remainingMillis), () {
        updateOrderStatus(order.id, model.OrderStatus.ready, isSystemAction: true);
        _prepTimers.remove(order.id);
      });
    }
  }

  Future<void> _loadSoundSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool('isSoundEnabled') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading sound setting: $e');
    }
  }

  void _handleError(String message) {
    debugPrint(message);
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

  void _checkPermission(List<String> allowedRoles, {String? action}) {
    if (_auth == null) return; // Fallback for system actions if auth is not yet injected
    if (!allowedRoles.contains(_auth!.role)) {
      throw Exception('Unauthorized: ${action ?? "This action"} requires ${allowedRoles.join(" or ")} role. Current role: ${_auth!.role}');
    }
  }

  Future<void> _playNotificationSound() async {
    if (!_isSoundEnabled) return;
    try {
      // For web support: ensure we use lowLatency and resume/play
      await _audioPlayer.stop(); // Reset if already playing
      await _audioPlayer.play(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, model.OrderStatus newStatus, {bool isSystemAction = false}) async {
    // 1. Role Validations
    if (!isSystemAction) {
      if (newStatus == model.OrderStatus.preparing || newStatus == model.OrderStatus.ready) {
        _checkPermission(['admin', 'superadmin', 'kitchen'], action: 'Kitchen preparation');
      }
      if (newStatus == model.OrderStatus.served) {
        _checkPermission(['admin', 'superadmin', 'captain'], action: 'Serving orders');
      }
    }
    
    try {
      if (_tenantId == null) throw Exception('Tenant ID not set');

      // 2. Fetch current order to validate transition
      final doc = await _tenantOrdersCollection.doc(orderId).get();
      if (!doc.exists) throw Exception('Order not found');
      final currentOrder = model.Order.fromFirestore(doc);
      
      // 3. Strict State Machine Enforcement
      if (!isSystemAction) {
        bool isValid = false;
        switch (newStatus) {
          case model.OrderStatus.preparing:
            isValid = currentOrder.status == model.OrderStatus.pending;
            break;
          case model.OrderStatus.ready:
            isValid = currentOrder.status == model.OrderStatus.preparing;
            break;
          case model.OrderStatus.served:
            isValid = currentOrder.status == model.OrderStatus.ready;
            break;
          case model.OrderStatus.completed:
            isValid = currentOrder.status == model.OrderStatus.served;
            break;
          default:
            isValid = true; // For other statuses like cancellations
        }
        
        if (!isValid) {
          throw Exception('Invalid status transition: ${currentOrder.status.name} -> ${newStatus.name}');
        }
      }

      // 1. COMPLETED status can only be set via payment callback or Mark as Paid (Cash)
      if (newStatus == model.OrderStatus.completed && !isSystemAction) {
        throw Exception('COMPLETED status is system-driven and cannot be set manually.');
      }

      // 1. Update status and items if necessary
      final Map<String, dynamic> updateData = {
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // REQUIREMENT: If marking entire order as SERVED, ensure all items are also marked served
      if (newStatus == model.OrderStatus.served) {
         final data = doc.data() as Map<String, dynamic>?;
         final items = List<Map<String, dynamic>>.from(data?['items'] ?? []);
         for (var item in items) {
            item['status'] = model.OrderItemStatus.served.name;
            item['servedAt'] = FieldValue.serverTimestamp();
         }
         updateData['items'] = items;
      }

      await _tenantOrdersCollection.doc(orderId).update(updateData);

      debugPrint('Order $orderId status updated to $newStatus');

      // 2. Auto-release table if status becomes COMPLETED
      if (newStatus == model.OrderStatus.completed) {
        await _checkAndReleaseTable(orderId);
      }

      // 3. Auto-deduct inventory if status becomes SERVED
      if (newStatus == model.OrderStatus.served) {
        _deductInventoryForOrder(orderId);
      }

      // 4. Update payment method if marking as completed manually
      if (newStatus == model.OrderStatus.completed && !isSystemAction) {
         // This block shouldn't be reached due to check above, but for consistency:
         await _tenantOrdersCollection.doc(orderId).update({
           'paymentMethod': 'Cash',
         });
      }

      // Log activity
      if (_auth != null && _activity != null) {
        final order = _orders.firstWhere((o) => o.id == orderId);
        _activity!.logAction(
          action: 'Order Status Updated',
          description: 'Order #${orderId.substring(0, 8)} status changed to ${newStatus.displayName} for ${order.tableName ?? 'Unknown table'}',
          actorId: _auth!.user?.uid ?? 'demo',
          actorName: _auth!.role == 'kitchen' ? 'Kitchen Staff' : 'Admin User',
          actorRole: _auth!.role ?? 'admin',
          type: ActivityType.orderStatusUpdate,
          tenantId: _tenantId!,
          metadata: {
            'orderId': orderId,
            'status': newStatus.name,
            'table': order.tableName,
          },
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating order status: $e');
      _handleError('Failed to update order status: $e');
      rethrow;
    }
  }

  Future<void> _deductInventoryForOrder(String orderId) async {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);
      if (_tenantId == null) return;

      final menuService = MenuService();
      final inventoryService = InventoryService();
      
      final menuItems = await menuService.getMenuItems(_tenantId!);
      
      await inventoryService.deductStockForOrder(
        tenantId: _tenantId!,
        orderId: orderId,
        orderItems: order.items,
        menuDefinitions: menuItems,
        performedBy: _auth?.userName ?? 'System',
      );
      
      debugPrint('✅ Inventory deducted for order $orderId');
    } catch (e) {
      debugPrint('❌ Failed to deduct inventory for order $orderId: $e');
    }
  }

  Future<void> markTableAsPaid(String tableId, {
    double? finalAmount,
    double? correctionAmount,
    String? correctionReason,
  }) async {
    _checkPermission(['admin', 'superadmin'], action: 'Settling tables');
    if (_tenantId == null) return;
    
    try {
      _isLoading = true;
      notifyListeners();

      // Implement atomic settlement logic
      await _firestore.runTransaction((transaction) async {
        final ordersQuery = await _firestore
            .collection('tenants')
            .doc(_tenantId)
            .collection('orders')
            .where('tableId', isEqualTo: tableId)
            .get();

        for (var doc in ordersQuery.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final statusStr = data['status'];
          final status = model.OrderStatus.fromString(statusStr);
          
          if (status == model.OrderStatus.completed || status == model.OrderStatus.cancelled) continue;

          // REQUIREMENT: Admin should NOT be able to mark paid if Order is not SERVED
          if (status != model.OrderStatus.served) {
            throw Exception('Cannot settle table: Order #${doc.id.substring(0,8)} is in ${status.displayName} state. All orders must be SERVED before payment.');
          }

          transaction.update(doc.reference, {
              'status': model.OrderStatus.completed.name,
              'paymentStatus': model.PaymentStatus.paid.name,
              'paymentMethod': 'Cash',
              'paidBy': _auth?.userName ?? _auth?.user?.email ?? 'Admin',
              'paidAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'closedAt': FieldValue.serverTimestamp(),
              if (finalAmount != null) 'finalSettledAmount': finalAmount,
              if (correctionAmount != null) 'correctionAmount': correctionAmount,
              if (correctionReason != null) 'correctionReason': correctionReason,
            });
          }

          final tableRef = _firestore
            .collection('tenants')
            .doc(_tenantId)
            .collection('tables')
            .doc(tableId);
        
        transaction.update(tableRef, {
          'status': 'available',
          'isAvailable': true,
          'isOccupied': false,
          'currentSessionId': null,
          'occupiedAt': null,
          'lastReleasedAt': FieldValue.serverTimestamp(),
        });
      });

      // Log activity
      if (_auth != null && _activity != null) {
        _activity!.logAction(
          action: 'Table Settled',
          description: 'Table $tableId marked as Paid. ' + 
                       (correctionAmount != null ? 'Correction: ₹$correctionAmount (${correctionReason ?? "No reason"})' : ''),
          actorId: _auth!.user?.uid ?? 'demo',
          actorName: _auth!.user?.email ?? 'Unknown',
          actorRole: _auth!.role ?? 'admin',
          type: ActivityType.payment,
          tenantId: _tenantId!,
          metadata: {
            'tableId': tableId, 
            'finalAmount': finalAmount,
            'correction': correctionAmount,
            'reason': correctionReason
          },
        );
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _handleError('Failed to settle table: $e');
      rethrow;
    }
  }


  Future<void> markAsPaid(String orderId) async {
    _checkPermission(['admin', 'superadmin'], action: 'Marking orders as paid');
    
    final doc = await _tenantOrdersCollection.doc(orderId).get();
    if (!doc.exists) throw Exception('Order not found');
    final order = model.Order.fromFirestore(doc);
    
    if (order.status != model.OrderStatus.served) {
      throw Exception('Cannot mark as paid: Order is ${order.status.displayName}. It must be SERVED first.');
    }

    // Manual cash payment confirmation
    await _tenantOrdersCollection.doc(orderId).update({
      'status': model.OrderStatus.completed.name,
      'paymentStatus': model.PaymentStatus.paid.name,
      'paymentMethod': 'Cash',
      'paidBy': _auth?.userName ?? _auth?.user?.email ?? 'Admin',
      'paidAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'closedAt': FieldValue.serverTimestamp(),
    });
    
    await _checkAndReleaseTable(orderId);
    
    debugPrint('Order $orderId marked as PAID (Cash)');
    
    // Log activity
    if (_auth != null && _activity != null) {
       final order = _orders.firstWhere((o) => o.id == orderId);
       _activity!.logAction(
        action: 'Order Paid',
        description: 'Order #${orderId.substring(0, 8)} marked as Paid (Cash)',
        actorId: _auth!.user?.uid ?? 'demo',
        actorName: _auth!.user?.email ?? 'Unknown',
        actorRole: _auth!.role ?? 'admin',
        type: ActivityType.payment,
        tenantId: _tenantId!,
        metadata: {'orderId': orderId, 'total': order.total, 'method': 'Cash'},
      );
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    _checkPermission(['admin', 'superadmin', 'captain'], action: 'Cancelling orders');
    if (orderId.isEmpty) {
      throw ArgumentError('Order ID cannot be empty');
    }

    try {
      _isLoading = true;
      notifyListeners();

      await updateOrderStatus(orderId, model.OrderStatus.cancelled);
      
      // Update cancellation reason if provided
      if (reason.isNotEmpty) {
        final updateData = {
          'cancellationReason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Update in tenant collection only
        await _tenantOrdersCollection.doc(orderId).update(updateData);
        
        // Legacy root collection update removed
        // await Future.wait([
        //   _ordersCollection.doc(orderId).update(updateData),
        //   _tenantOrdersCollection.doc(orderId).update(updateData),
        // ]);
      }
      
      debugPrint('Order $orderId cancelled with reason: $reason');

      // Log activity
      if (_auth != null && _activity != null) {
        final order = _orders.firstWhere((o) => o.id == orderId);
        _activity!.logAction(
          action: 'Order Cancelled',
          description: 'Order #${orderId.substring(0, 8)} was cancelled${reason.isNotEmpty ? ' ($reason)' : ''}',
          actorId: _auth!.user?.uid ?? 'demo',
          actorName: _auth!.role == 'kitchen' ? 'Kitchen Staff' : 'Admin User',
          actorRole: _auth!.role ?? 'admin',
          type: ActivityType.orderCancel,
          tenantId: _tenantId!,
          metadata: {
            'orderId': orderId,
            'reason': reason,
            'table': order.tableName,
          },
        );
      }
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      _handleError('Failed to cancel order: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fireOrder(String orderId) async {
    _checkPermission(['admin', 'superadmin', 'captain'], action: 'Firing orders');
    await updateOrderStatus(orderId, model.OrderStatus.preparing);
    
    // Log activity
    if (_auth != null && _activity != null) {
      final order = _orders.firstWhere((o) => o.id == orderId);
      _activity!.logAction(
        action: 'Order Fired',
        description: 'Order #${orderId.substring(0, 8)} for ${order.tableName ?? 'Unknown'} was fired to the kitchen',
        actorId: _auth!.user?.uid ?? 'demo',
        actorName: _auth!.user?.email ?? 'Unknown',
        actorRole: _auth!.role ?? 'captain',
        type: ActivityType.orderStatusUpdate,
        tenantId: _tenantId!,
        metadata: {'orderId': orderId, 'table': order.tableName},
      );
    }
  }

  Future<void> addOrderItem(String orderId, model.OrderItem item) async {
    _checkPermission(['admin', 'superadmin', 'captain'], action: 'Adding items');
    await _updateOrderItemsAtomic(orderId, (currentItems) {
      return List<model.OrderItem>.from(currentItems)..add(item);
    });

    // Log activity
    _logItemAction('Item Added', 'Added ${item.quantity}x ${item.name}', orderId, ActivityType.orderItemAdd, {'item': item.name, 'qty': item.quantity});
  }

  Future<void> updateOrderItem(String orderId, model.OrderItem updatedItem) async {
    await _updateOrderItemsAtomic(orderId, (currentItems) {
      final index = currentItems.indexWhere((i) => i.id == updatedItem.id);
      if (index == -1) return currentItems;
      
      final newItems = List<model.OrderItem>.from(currentItems);
      newItems[index] = updatedItem;
      return newItems;
    });

    // Log activity
    _logItemAction('Item Updated', 'Updated ${updatedItem.name}', orderId, ActivityType.orderItemUpdate, {'item': updatedItem.name});
  }

  Future<void> removeOrderItem(String orderId, String itemId, {bool supervisorApproved = false}) async {
    _checkPermission(['admin', 'superadmin', 'captain'], action: 'Removing items');
    await _updateOrderItemsAtomic(orderId, (currentItems) {
      return currentItems.where((i) => i.id != itemId).toList();
    });

    // Log activity
    _logItemAction('Item Removed', 'Removed item from order', orderId, ActivityType.orderItemDelete, {'itemId': itemId, 'approved': supervisorApproved});
  }

  Future<void> addItemNote(String orderId, String itemId, String note) async {
    await _updateOrderItemsAtomic(orderId, (currentItems) {
      final index = currentItems.indexWhere((i) => i.id == itemId);
      if (index == -1) return currentItems;

      final updatedItem = currentItems[index].copyWith(notes: note);
      final newItems = List<model.OrderItem>.from(currentItems);
      newItems[index] = updatedItem;
      return newItems;
    });
  }

  /// 4️⃣ Item-level status control (P0)
  Future<void> updateOrderItemStatus(String orderId, String itemId, model.OrderItemStatus newStatus) async {
    if (newStatus == model.OrderItemStatus.preparing || newStatus == model.OrderItemStatus.ready) {
      _checkPermission(['admin', 'superadmin', 'kitchen'], action: 'Kitchen preparation');
    }
    if (newStatus == model.OrderItemStatus.served) {
      _checkPermission(['admin', 'superadmin', 'captain'], action: 'Serving items');
    }

    await _updateOrderItemsAtomic(orderId, (currentItems) {
      final index = currentItems.indexWhere((i) => i.id == itemId);
      if (index == -1) return currentItems; // Or throw

      final updatedItem = currentItems[index].copyWith(
        status: newStatus,
        servedAt: newStatus == model.OrderItemStatus.served ? DateTime.now() : currentItems[index].servedAt,
      );
      
      final newItems = List<model.OrderItem>.from(currentItems);
      newItems[index] = updatedItem;
      return newItems;
    });

    // Log activity (non-critical, can be done outside transaction)
    _logItemAction(
      'Item Status Updated', 
      'Marked item as ${newStatus.displayName}', 
      orderId, 
      ActivityType.orderItemStatusUpdate, 
      {'itemId': itemId, 'status': newStatus.name}
    );
  }

  Future<void> markItemAsServed(String orderId, String itemId) async {
    await updateOrderItemStatus(orderId, itemId, model.OrderItemStatus.served);
  }

  Future<void> _updateOrderItems(String orderId, List<model.OrderItem> items) async {
    await _updateOrderItemsAtomic(orderId, (current) => items);
  }

  void _logItemAction(String action, String description, String orderId, ActivityType type, Map<String, dynamic> metadata) {
    if (_auth != null && _activity != null) {
      _activity!.logAction(
        action: action,
        description: description,
        actorId: _auth!.user?.uid ?? 'demo',
        actorName: _auth!.user?.email ?? 'Unknown',
        actorRole: _auth!.role ?? 'captain',
        type: type,
        tenantId: _tenantId!,
        metadata: {...metadata, 'orderId': orderId},
      );
    }
  }

  /// 🛡️ Atomic Update Helper (Bug #7 fix)
  /// Uses Firestore Transactions to prevent race conditions
  Future<void> _updateOrderItemsAtomic(
    String orderId, 
    List<model.OrderItem> Function(List<model.OrderItem> current) updater
  ) async {
    if (_tenantId == null) return;
    
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _tenantOrdersCollection.doc(orderId);
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) return;
        
        final data = snapshot.data() as Map<String, dynamic>;
        final currentItemsData = (data['items'] as List? ?? []);
        final currentItems = currentItemsData
            .map((i) => model.OrderItem.fromMap(Map<String, dynamic>.from(i)))
            .toList();
            
        final updatedItems = updater(currentItems);
        
        // Recalculate totals based on latest snapshot
        final subtotal = updatedItems.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
        
        // Preserve existing tax rate or use default
        final currentSubtotal = (data['subtotal'] ?? 0).toDouble();
        final currentTax = (data['tax'] ?? 0).toDouble();
        final taxRate = currentSubtotal > 0 ? (currentTax / currentSubtotal) : 0.05;
        
        final tax = subtotal * taxRate;
        final total = subtotal + tax;
        
        // Derive top-level status
        final tempOrder = model.Order.fromFirestore(snapshot).copyWith(items: updatedItems);
        final newStatus = tempOrder.derivedStatus;

        transaction.update(docRef, {
          'items': updatedItems.map((i) => i.toMap()).toList(),
          'subtotal': subtotal,
          'tax': tax,
          'total': total,
          'status': newStatus.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      print('✅ Atomic update successful for order $orderId');
    } catch (e) {
      print('❌ Atomic update failed: $e');
      rethrow;
    }
  }

  Future<void> mergeTableOrders(String tableId) async {
    final activeOrders = _orders.where((o) => 
      o.tableId == tableId && 
      o.status != model.OrderStatus.completed && 
      o.status != model.OrderStatus.cancelled
    ).toList();

    if (activeOrders.length <= 1) return;

    print('🚑 Auto-Merging ${activeOrders.length} orders for table $tableId');
    
    // Sort so we merge into the OLDEST order to preserve history
    activeOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final baseOrder = activeOrders.first;
    final otherOrders = activeOrders.sublist(1);

    List<model.OrderItem> mergedItems = List.from(baseOrder.items);
    
    for (final other in otherOrders) {
      for (final newItem in other.items) {
        final existingItemIndex = mergedItems.indexWhere((i) => i.id == newItem.id);
        if (existingItemIndex != -1) {
          final oldItem = mergedItems[existingItemIndex];
          mergedItems[existingItemIndex] = oldItem.copyWith(
            quantity: oldItem.quantity + newItem.quantity,
          );
        } else {
          mergedItems.add(newItem);
        }
      }
    }

    // Recalculate totals
    final subtotal = mergedItems.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
    final taxRate = baseOrder.subtotal > 0 ? (baseOrder.tax / baseOrder.subtotal) : 0.05;
    final tax = subtotal * taxRate;
    final total = subtotal + tax;

    // Update base order
    await _tenantOrdersCollection.doc(baseOrder.id).update({
      'items': mergedItems.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Delete/Cancel other orders
    for (final other in otherOrders) {
      // Option 1: Delete
      await _tenantOrdersCollection.doc(other.id).delete();
      // Option 2: Mark as cancelled? No, delete is cleaner for merging.
    }
  }

  Future<String> createOrder(model.Order order) async {
    try {
      // FIRST: Ensure any existing mess is cleaned up
      if (order.tableId != null) {
        await mergeTableOrders(order.tableId!);
      }

      // NOW check for the (now singular) existing running order
      if (order.tableId != null) {
        final existingOrderIndex = _orders.indexWhere((o) => 
          o.tableId == order.tableId && 
          o.status != model.OrderStatus.completed && 
          o.status != model.OrderStatus.cancelled
        );

        if (existingOrderIndex != -1) {
          final existingOrder = _orders[existingOrderIndex];
          print('🔄 OrdersProvider: Appending to existing order: ${existingOrder.id} for table ${order.tableId}');

          // Merge items
          List<model.OrderItem> mergedItems = List.from(existingOrder.items);
          for (var newItem in order.items) {
            final existingItemIndex = mergedItems.indexWhere((i) => i.id == newItem.id);
            if (existingItemIndex != -1) {
              final oldItem = mergedItems[existingItemIndex];
              mergedItems[existingItemIndex] = oldItem.copyWith(
                quantity: oldItem.quantity + newItem.quantity,
              );
            } else {
              mergedItems.add(newItem);
            }
          }

          // Recalculate totals
          final subtotal = mergedItems.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
          final taxRate = existingOrder.subtotal > 0 ? (existingOrder.tax / existingOrder.subtotal) : 0.05;
          final tax = subtotal * taxRate;
          final total = subtotal + tax;

          await _tenantOrdersCollection.doc(existingOrder.id).update({
            'items': mergedItems.map((i) => i.toMap()).toList(),
            'subtotal': subtotal,
            'tax': tax,
            'total': total,
            'status': model.OrderStatus.pending.name, // Reset to pending
            'updatedAt': FieldValue.serverTimestamp(),
          });

          return existingOrder.id;
        }
      }

      // NO EXISTING ORDER FOUND: Create new doc
      final docRef = await _tenantOrdersCollection.add(order.toMap());
      // Log activity
      if (_auth != null && _activity != null) {
        _activity!.logAction(
          action: 'Order Created',
          description: 'New order created for ${order.tableName}',
          actorId: _auth!.user?.uid ?? 'demo',
          actorName: _auth!.user?.email ?? 'Unknown',
          actorRole: _auth!.role ?? 'captain',
          type: ActivityType.orderCreate,
          tenantId: _tenantId!,
          metadata: {'orderId': docRef.id, 'table': order.tableName},
        );
      }
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    // Cancel all timers
    for (var timer in _prepTimers.values) {
      timer.cancel();
    }
    _prepTimers.clear();
    super.dispose();
  }

  Future<void> _checkAndReleaseTable(String orderId) async {
    if (_tenantId == null) return;
    try {
      // Fetch the latest doc to ensure we have the correct tableId
      final doc = await _tenantOrdersCollection.doc(orderId).get();
      final data = doc.data() as Map<String, dynamic>?;
      final tableId = data?['tableId'];
      
      if (tableId != null) {
        // Check if there are ANY other active orders for this table before releasing
        final otherActiveOrders = await _tenantOrdersCollection
            .where('tableId', isEqualTo: tableId)
            .where('status', whereNotIn: [model.OrderStatus.completed.name, model.OrderStatus.cancelled.name])
            .get();
        
        final remainingOrders = otherActiveOrders.docs.where((d) => d.id != orderId).length;
        
        if (remainingOrders == 0) {
          debugPrint('🔓 Last order $orderId COMPLETED. Auto-releasing table $tableId');
          await _firestore.collection('tenants').doc(_tenantId!).collection('tables').doc(tableId).update({
            'status': 'available',
            'isAvailable': true,
            'isOccupied': false,
            'currentSessionId': null,
            'occupiedAt': null,
            'lastReleasedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error auto-releasing table: $e');
    }
  }
}
