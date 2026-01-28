import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
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
  bool _isLoading = false;
  String? _tenantId;
  String? _error;
  Map<String, dynamic> _tenantSettings = {};
  AdminAuthProvider? _auth;
  ActivityProvider? _activity;
  StreamSubscription<QuerySnapshot>? _ordersSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PrintService _printService = PrintService();
  DateTime? _lastOrderTime;
  bool _isFirstLoad = true;
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
    o.status == model.OrderStatus.pending ||
    o.status == model.OrderStatus.preparing ||
    o.status == model.OrderStatus.ready
  ).toList();

  List<model.Order> get pastOrders => _orders.where((o) => 
    o.status == model.OrderStatus.served ||
    o.status == model.OrderStatus.completed ||
    o.status == model.OrderStatus.cancelled
  ).toList();

  List<model.Order> get pendingPaymentOrders => _orders.where((o) => 
    o.status == model.OrderStatus.served && o.paymentStatus == model.PaymentStatus.pending
  ).toList();

  int get currentOrdersCount => currentOrders.length;
  int get pastOrdersCount => pastOrders.length;
  int get pendingPaymentOrdersCount => pendingPaymentOrders.length; 

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
  String? get error => _error;
  String? get tenantId => _tenantId;
  Map<String, dynamic> get tenantSettings => _tenantSettings;

  // Initialize with tenant ID and optional logging
  void initialize(String tenantId, {AdminAuthProvider? auth, ActivityProvider? activity}) {
    if (_tenantId == tenantId && _auth == auth && _activity == activity) return; 
    
    // Clean up existing subscriptions
    _ordersSubscription?.cancel();
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
        query = _firestore.collectionGroup('orders').limit(500); // Increased limit
      } else {
        print('🏢 OrdersProvider: Using TENANT collection: tenants/$_tenantId/orders');
        query = _tenantOrdersCollection;
      }

      _ordersSubscription = query
          .snapshots()
          .listen(
        (snapshot) async {
          print('📊 OrdersProvider: Snapshot Received! Docs count: ${snapshot.docs.length}');
          try {
            final orders = <model.Order>[];
            bool shouldAlert = false;

            for (var doc in snapshot.docs) {
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
                    if (order.items.length > existingOrder.items.length) {
                      shouldAlert = true;
                      _latestNewOrder = order;
                      print('🔔 Add-on Item Alert for Order: ${order.id}');
                      // Trigger Auto-Print for Add-ons
                      _printService.printKOT(order, isAddon: true);
                    }
                    if (order.chefNote != existingOrder.chefNote && order.chefNote != null && order.chefNote!.isNotEmpty) {
                      shouldAlert = true;
                      _latestNewOrder = order;
                      print('🔔 Chef Note Alert for Order: ${order.id}');
                      // Optionally print chef notes too
                      _printService.printKOT(order, isAddon: true);
                    }
                  }
                }
              } catch (e) {
                debugPrint('❌ Error parsing order ${doc.id}: $e');
                // debugPrint('    Data: ${doc.data()}');
              }
            }

            // Sort by createdAt in memory
            orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (shouldAlert) {
              _playNotificationSound();
            }

            _isFirstLoad = false;
            _orders = orders;
            _isLoading = false;
            _error = null;
            debugPrint('📊 OrdersProvider: Successfully loaded ${orders.length} orders');
            notifyListeners();
          } catch (e) {
            _handleError('Error processing orders: $e');
          }
        },
        onError: (e) {
          debugPrint('❌ OrdersProvider Stream Error: $e');
          _handleError(e.toString());
        },
        cancelOnError: false,
      );
    } catch (e) {
      _handleError('Error setting up orders listener: $e');
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

  void _handleError(String message) {
    debugPrint(message);
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _playNotificationSound() async {
    // Disable sound on web to prevent LegacyJavaScriptObject Duration error
    if (kIsWeb) return;
    try {
      // Premium notification sound
      await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, model.OrderStatus newStatus, {bool isSystemAction = false}) async {
    try {
      if (_tenantId == null) {
        throw Exception('Tenant ID not set');
      }

      // 1. COMPLETED status can only be set via payment callback or Mark as Paid (Cash)
      if (newStatus == model.OrderStatus.completed && !isSystemAction) {
        throw Exception('COMPLETED status is system-driven and cannot be set manually.');
      }

      // Update in tenant's orders subcollection
      await _tenantOrdersCollection.doc(orderId).update({
        'status': newStatus.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Order $orderId status updated to $newStatus');

      // 2. Auto-release table if status becomes COMPLETED
      if (newStatus == model.OrderStatus.completed) {
        final order = _orders.firstWhere((o) => o.id == orderId);
        if (order.tableId != null) {
          debugPrint('🔓 Order $orderId COMPLETED. Auto-releasing table ${order.tableId}');
          await _firestore.collection('tenants').doc(_tenantId).collection('tables').doc(order.tableId).update({
            'status': 'available',
            'isAvailable': true,
            'isOccupied': false,
            'currentSessionId': null,
            'occupiedAt': null,
          });
        }
      }

      // 3. Auto-deduct inventory if status becomes SERVED
      if (newStatus == model.OrderStatus.served) {
        _deductInventoryForOrder(orderId);
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

  Future<void> markTableAsPaid(String tableId) async {
    if (_tenantId == null) return;
    
    try {
      _isLoading = true;
      notifyListeners();

      // Implement atomic settlement logic directly in provider to reuse _firestore and auth
      await _firestore.runTransaction((transaction) async {
        final ordersQuery = await _firestore
            .collection('tenants')
            .doc(_tenantId)
            .collection('orders')
            .where('tableId', isEqualTo: tableId)
            .get();

        for (var doc in ordersQuery.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'];
          
          if (status != model.OrderStatus.completed.name && 
              status != model.OrderStatus.cancelled.name) {
            transaction.update(doc.reference, {
              'status': model.OrderStatus.completed.name,
              'paymentStatus': model.PaymentStatus.paid.name,
              'updatedAt': FieldValue.serverTimestamp(),
              'closedAt': FieldValue.serverTimestamp(),
            });
          }
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
          description: 'All orders for Table $tableId marked as Paid & Table Vacated',
          actorId: _auth!.user?.uid ?? 'demo',
          actorName: _auth!.user?.email ?? 'Unknown',
          actorRole: _auth!.role ?? 'admin',
          type: ActivityType.payment,
          tenantId: _tenantId!,
          metadata: {'tableId': tableId, 'method': 'Cash'},
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
    // This is a system action (manual cash payment confirmation)
    await updateOrderStatus(orderId, model.OrderStatus.completed, isSystemAction: true);
    
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
    final order = _orders.firstWhere((o) => o.id == orderId);
    // Allow adding items at any stage (except cancelled/completed maybe? for now allow all active)
    if (order.status == model.OrderStatus.cancelled || order.status == model.OrderStatus.completed) {
       throw Exception('Cannot add items to completed/cancelled orders');
    }
    // if (order.status != OrderStatus.pending) {
    //   throw Exception('Cannot add items after kitchen acceptance');
    // }

    final newItems = List<model.OrderItem>.from(order.items)..add(item);
    await _updateOrderItems(orderId, newItems);

    // Log activity
    _logItemAction('Item Added', 'Added ${item.quantity}x ${item.name} to order #${orderId.substring(0, 8)}', orderId, ActivityType.orderItemAdd, {'item': item.name, 'qty': item.quantity});
  }

  Future<void> updateOrderItem(String orderId, model.OrderItem updatedItem) async {
    final order = _orders.firstWhere((o) => o.id == orderId);
    if (order.status != model.OrderStatus.pending) {
      throw Exception('Cannot update items after kitchen acceptance');
    }

    final index = order.items.indexWhere((i) => i.id == updatedItem.id);
    if (index == -1) throw Exception('Item not found');

    final newItems = List<model.OrderItem>.from(order.items);
    newItems[index] = updatedItem;
    await _updateOrderItems(orderId, newItems);

    // Log activity
    _logItemAction('Item Updated', 'Updated ${updatedItem.name} in order #${orderId.substring(0, 8)}', orderId, ActivityType.orderItemUpdate, {'item': updatedItem.name});
  }

  Future<void> removeOrderItem(String orderId, String itemId, {bool supervisorApproved = false}) async {
    final order = _orders.firstWhere((o) => o.id == orderId);
    if (order.status != model.OrderStatus.pending) {
      throw Exception('Cannot remove items after kitchen acceptance');
    }

    if (_auth?.isCaptain == true) {
      final captainPerms = _tenantSettings['captainPermissions'] ?? {};
      final canDelete = captainPerms['canDeleteItems'] ?? true;
      final requiresApproval = captainPerms['requiresApproval'] ?? false;

      if (!canDelete) {
        throw Exception('You do not have permission to delete items');
      }

      if (requiresApproval && !supervisorApproved) {
        throw Exception('Supervisor approval required for deletion');
      }
    }

    final item = order.items.firstWhere((i) => i.id == itemId);
    final newItems = order.items.where((i) => i.id != itemId).toList();
    
    await _updateOrderItems(orderId, newItems);

    // Log activity
    _logItemAction('Item Removed', 'Removed ${item.name} from order #${orderId.substring(0, 8)}${supervisorApproved ? ' (Supervisor Approved)' : ''}', orderId, ActivityType.orderItemDelete, {'item': item.name, 'approved': supervisorApproved});
  }

  Future<void> addItemNote(String orderId, String itemId, String note) async {
    final order = _orders.firstWhere((o) => o.id == orderId);
    final index = order.items.indexWhere((i) => i.id == itemId);
    if (index == -1) throw Exception('Item not found');

    final updatedItem = order.items[index].copyWith(notes: note);
    final newItems = List<model.OrderItem>.from(order.items);
    newItems[index] = updatedItem;

    await _updateOrderItems(orderId, newItems);
  }

  /// 4️⃣ Item-level status control (P0)
  Future<void> updateOrderItemStatus(String orderId, String itemId, model.OrderItemStatus newStatus) async {
    final order = _orders.firstWhere((o) => o.id == orderId);
    final index = order.items.indexWhere((i) => i.id == itemId);
    if (index == -1) throw Exception('Item not found');

    final updatedItem = order.items[index].copyWith(
      status: newStatus,
      servedAt: newStatus == model.OrderItemStatus.served ? DateTime.now() : order.items[index].servedAt,
    );
    final newItems = List<model.OrderItem>.from(order.items);
    newItems[index] = updatedItem;

    await _updateOrderItems(orderId, newItems);

    // Log activity
    _logItemAction(
      'Item Status Updated', 
      'Marked ${updatedItem.name} as ${newStatus.displayName} in order #${orderId.substring(0, 8)}', 
      orderId, 
      ActivityType.orderItemStatusUpdate, 
      {'item': updatedItem.name, 'status': newStatus.name}
    );
  }

  Future<void> markItemAsServed(String orderId, String itemId) async {
    await updateOrderItemStatus(orderId, itemId, model.OrderItemStatus.served);
  }

  Future<void> _updateOrderItems(String orderId, List<model.OrderItem> items) async {
    final subtotal = items.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
    final order = _orders.firstWhere((o) => o.id == orderId);
    final taxRate = (order.tax / order.subtotal);
    final tax = subtotal * taxRate;
    final total = subtotal + tax;

    // Derive top-level status
    final tempOrder = order.copyWith(items: items);
    final newStatus = tempOrder.derivedStatus;

    await _tenantOrdersCollection.doc(orderId).update({
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
}
