import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/cart_controller.dart';
import 'order_enums.dart';

export 'order_enums.dart';

class OrderDetails {
  final String orderId;
  final String guestId;
  final String? tableId;
  final String? tableName;
  final String tenantId;
  final OrderType type;
  final List<OrderItem> items;
  final DateTime timestamp;
  final OrderStatus status;
  final int estimatedWaitTime;
  final double subtotal;
  final double tax;
  final double total;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String customerName;
  final String? customerPhone;
  final String? paymentId;
  final DateTime? paymentTimestamp;
  final String? chefNote;
  final String? cancellationReason;
  final String? sessionId;

  OrderDetails({
    required this.orderId,
    required this.guestId,
    this.tableId,
    this.tableName,
    required this.tenantId,
    required this.type,
    required this.items,
    required this.timestamp,
    this.status = OrderStatus.pending,
    required this.estimatedWaitTime,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentMethod = PaymentMethod.upi,
    this.customerName = '',
    this.customerPhone,
    this.paymentId,
    this.paymentTimestamp,
    this.chefNote,
    this.cancellationReason,
    this.sessionId,
  });

  factory OrderDetails.fromCart({
    required String orderId,
    required String guestId,
    required String tenantId,
    required OrderType type,
    String? tableId,
    String? tableName,
    required List<CartItem> cartItems,
    required int avgPrepTime,
    required double taxRate,
    PaymentStatus paymentStatus = PaymentStatus.pending,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String customerName = '',
    String? customerPhone,
    String? chefNote,
  }) {
    final subtotal = cartItems.fold<double>(
      0,
      (sum, item) => sum + (item.item.price * item.quantity),
    );
    final tax = subtotal * taxRate;
    final total = subtotal + tax;

    return OrderDetails(
      orderId: orderId,
      guestId: guestId,
      tableId: tableId,
      tableName: tableName,
      tenantId: tenantId,
      type: type,
      items: cartItems.map((item) => OrderItem.fromCartItem(item)).toList(),
      timestamp: DateTime.now(),
      estimatedWaitTime: avgPrepTime,
      subtotal: subtotal,
      tax: tax,
      total: total,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      customerName: customerName,
      customerPhone: customerPhone,
      chefNote: chefNote,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'guestId': guestId,
      'tableId': tableId,
      'tableName': tableName,
      'tenantId': tenantId,
      'type': type.name,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': Timestamp.fromDate(timestamp),
      'status': status.name,
      'estimatedWaitTime': estimatedWaitTime,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'paymentStatus': paymentStatus.name,
      'paymentMethod': paymentMethod.name,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'paymentId': paymentId,
      'paymentTimestamp': paymentTimestamp != null
          ? Timestamp.fromDate(paymentTimestamp!)
          : null,
      'chefNote': chefNote,
      'cancellationReason': cancellationReason,
      'sessionId': sessionId,
    };
  }

  /// Parse order status from database with legacy migration support
  static OrderStatus _parseOrderStatus(dynamic status) {
    if (status == null) return OrderStatus.pending;
    return OrderStatus.fromString(status.toString());
  }

  factory OrderDetails.fromMap(Map<String, dynamic> map) {
    try {
      return OrderDetails(
        orderId: map['orderId']?.toString() ?? '',
        guestId: map['guestId']?.toString() ?? '',
        tableId: map['tableId']?.toString(),
        tableName: map['tableName']?.toString(),
        tenantId: map['tenantId']?.toString() ?? '',
        type: map['type'] != null
            ? OrderType.values.firstWhere(
                (e) => e.name == map['type'],
                orElse: () => OrderType.dineIn,
              )
            : OrderType.dineIn,
        items: map['items'] != null
            ? (map['items'] as List)
                  .map((item) => OrderItem.fromMap(item))
                  .toList()
            : [],
        timestamp: map['createdAt'] != null
            ? (map['createdAt'] is Timestamp
                  ? (map['createdAt'] as Timestamp).toDate()
                  : DateTime.parse(map['createdAt'].toString()))
            : (map['timestamp'] != null
                ? (map['timestamp'] is Timestamp
                      ? (map['timestamp'] as Timestamp).toDate()
                      : DateTime.parse(map['timestamp'].toString()))
                : DateTime.now()),
        status: map['status'] != null
            ? _parseOrderStatus(map['status'])
            : OrderStatus.pending,
        estimatedWaitTime: (map['estimatedWaitTime'] as num?)?.toInt() ?? 30,
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
        tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
        total: (map['total'] as num?)?.toDouble() ?? 0.0,
        paymentStatus: map['paymentStatus'] != null
            ? PaymentStatus.values.firstWhere(
                (e) => e.name == map['paymentStatus'],
                orElse: () => PaymentStatus.pending,
              )
            : PaymentStatus.pending,
        paymentMethod: map['paymentMethod'] != null
            ? PaymentMethod.values.firstWhere(
                (e) => e.name == map['paymentMethod'],
                orElse: () => PaymentMethod.upi,
              )
            : PaymentMethod.upi,
        customerName: map['customerName']?.toString() ?? '',
        customerPhone: map['customerPhone']?.toString(),
        paymentId: map['paymentId']?.toString(),
        paymentTimestamp: map['paymentTimestamp'] != null
            ? (map['paymentTimestamp'] is Timestamp
                  ? (map['paymentTimestamp'] as Timestamp).toDate()
                  : DateTime.parse(map['paymentTimestamp'].toString()))
            : null,
        chefNote: map['chefNote']?.toString(),
        cancellationReason: map['cancellationReason']?.toString(),
        sessionId: map['sessionId']?.toString(),
      );
    } catch (e) {
      print('Error parsing OrderDetails: $e');
      print('Map data: $map');
      rethrow;
    }
  }

  DateTime get estimatedReadyTime {
    return timestamp.add(Duration(minutes: estimatedWaitTime));
  }

  static OrderDetails empty() => OrderDetails(
    orderId: '',
    guestId: '',
    tableId: null,
    tableName: null,
    tenantId: '',
    type: OrderType.dineIn,
    items: [],
    timestamp: DateTime.now(),
    status: OrderStatus.pending,
    estimatedWaitTime: 30,
    subtotal: 0,
    tax: 0,
    total: 0,
    paymentStatus: PaymentStatus.pending,
    paymentMethod: PaymentMethod.upi,
    customerName: '',
    customerPhone: null,
    paymentId: null,
    paymentTimestamp: null,
    chefNote: null,
    cancellationReason: null,
    sessionId: null,
  );
}

class OrderItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? notes;

  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes,
  });

  factory OrderItem.fromCartItem(CartItem cartItem) {
    return OrderItem(
      id: cartItem.item.id,
      name: cartItem.item.name,
      price: cartItem.item.price,
      quantity: cartItem.quantity,
      notes: cartItem.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'notes': notes,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      notes: map['notes']?.toString(),
    );
  }

  double get total => price * quantity;
}
