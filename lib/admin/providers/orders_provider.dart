import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum OrderStatus {
  pending('Pending', '🕒'),
  preparing('Preparing', '👨‍🍳'),
  ready('Ready to Serve', '✅'),
  served('Served', '🍽️'),
  completed('Completed', '👍'),
  cancelled('Cancelled', '❌');

  final String displayName;
  final String emoji;
  const OrderStatus(this.displayName, this.emoji);

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (s) => s.toString().split('.').last == status,
      orElse: () => OrderStatus.pending,
    );
  }
}

class OrderItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? notes;
  final List<String>? addons;
  final String? imageUrl;

  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes,
    this.addons,
    this.imageUrl,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Unknown Item',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      notes: data['notes'],
      addons: data['addons'] != null ? List<String>.from(data['addons']) : null,
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      if (notes != null) 'notes': notes,
      if (addons != null) 'addons': addons,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

class Order {
  final String id;
  final String tenantId;
  final String? tableId;
  final String? tableName;
  final String? customerName;
  final String? customerPhone;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? notes;
  final String? cancellationReason;

  Order({
    required this.id,
    required this.tenantId,
    this.tableId,
    this.tableName,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.paymentMethod,
    this.paymentStatus,
    this.notes,
    this.cancellationReason,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      
      // Parse items
      final items = (data['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromMap(Map<String, dynamic>.from(item)))
          .toList();
      
      // Parse dates
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final updatedAt = data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null;
      
      // Parse status
      final status = data['status'] != null 
          ? OrderStatus.fromString(data['status']) 
          : OrderStatus.pending;
      
      return Order(
        id: doc.id,
        tenantId: data['tenantId']?.toString() ?? '',
        tableId: data['tableId']?.toString(),
        tableName: data['tableName']?.toString(),
        customerName: data['customerName']?.toString(),
        customerPhone: data['customerPhone']?.toString(),
        items: items,
        subtotal: (data['subtotal'] ?? 0).toDouble(),
        tax: (data['tax'] ?? 0).toDouble(),
        total: (data['total'] ?? 0).toDouble(),
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
        paymentMethod: data['paymentMethod']?.toString(),
        paymentStatus: data['paymentStatus']?.toString(),
        notes: data['notes']?.toString(),
        cancellationReason: data['cancellationReason']?.toString(),
      );
    } catch (e) {
      debugPrint('Error parsing order: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'tableId': tableId,
      'tableName': tableName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'notes': notes,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
    };
  }
}

class OrdersProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _tenantId;
  String? _error;
  StreamSubscription<QuerySnapshot>? _ordersSubscription;
  final Map<String, StreamSubscription> _orderSubscriptions = {};
  
  // Firestore collections
  CollectionReference get _ordersCollection => _firestore.collection('orders');
  CollectionReference get _tenantOrdersCollection {
    if (_tenantId == null) throw Exception('Tenant ID not set');
    return _firestore.collection('tenants').doc(_tenantId).collection('orders');
  }

  // Getters
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get tenantId => _tenantId;

  // Initialize with tenant ID
  void initialize(String tenantId) {
    if (_tenantId == tenantId) return; // Already initialized with this tenant
    
    // Clean up existing subscriptions
    _ordersSubscription?.cancel();
    for (var sub in _orderSubscriptions.values) {
      sub.cancel();
    }
    _orderSubscriptions.clear();
    
    _tenantId = tenantId;
    _isLoading = true;
    _orders = [];
    notifyListeners();
    
    _listenToOrders();
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
      
      debugPrint('🔥 OrdersProvider: Listening to orders for tenant $_tenantId');
      debugPrint('🔥 OrdersProvider: Collection path: ${_tenantOrdersCollection.path}');

      // Listen to tenant's orders subcollection
      _ordersSubscription = _tenantOrdersCollection
          .orderBy('createdAt', descending: true)
          .snapshots(includeMetadataChanges: true)
          .listen(
        (snapshot) async {
          try {
            if (snapshot.metadata.isFromCache) {
              debugPrint('Using cached orders data');
            }

            debugPrint('🔥 OrdersProvider: Received ${snapshot.docs.length} order documents');

            // Process new orders
            final orders = <Order>[];
            for (var doc in snapshot.docs) {
              try {
                final orderData = doc.data() as Map<String, dynamic>;
                debugPrint('🔥 OrdersProvider: Processing order ${doc.id}');
                final order = Order.fromFirestore(doc);
                orders.add(order);
              } catch (e) {
                debugPrint('Error parsing order ${doc.id}: $e');
              }
            }

            debugPrint('🔥 OrdersProvider: Parsed ${orders.length} orders successfully');
            _orders = orders;
            // _setupOrderSubscriptions(_orders); // Removed redundant subscriptions
            _isLoading = false;
            _error = null;
            notifyListeners();
          } catch (e) {
            _handleError('Error processing orders: $e');
          }
        },
        onError: (e) => _handleError(e.toString()), // Fixed error callback signature
        cancelOnError: false,
      );
    } catch (e) {
      _handleError('Error setting up orders listener: $e');
    }
  }
  
  // Removed _setupOrderSubscriptions method as it was causing issues and redundant reads

  void _handleError(String message) {
    debugPrint(message);
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      if (_tenantId == null) {
        throw Exception('Tenant ID not set');
      }

      // Update in tenant's orders subcollection
      await _tenantOrdersCollection.doc(orderId).update({
        'status': newStatus.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update in the main orders collection - REMOVED (Legacy)
      // await _ordersCollection.doc(orderId).update({
      //   'status': newStatus.toString().split('.').last,
      //   'updatedAt': FieldValue.serverTimestamp(),
      // });

      debugPrint('Order $orderId status updated to $newStatus');
    } catch (e) {
      debugPrint('Error updating order status: $e');
      _handleError('Failed to update order status: $e');
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    if (orderId.isEmpty) {
      throw ArgumentError('Order ID cannot be empty');
    }

    try {
      _isLoading = true;
      notifyListeners();

      await updateOrderStatus(orderId, OrderStatus.cancelled);
      
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
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      _handleError('Failed to cancel order: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    // Cancel all order subscriptions
    for (var subscription in _orderSubscriptions.values) {
      subscription.cancel();
    }
    _orderSubscriptions.clear();
    super.dispose();
  }
}
