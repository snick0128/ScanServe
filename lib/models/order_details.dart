import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/cart_controller.dart';
import 'order_model.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  served,
  completed;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.served:
        return 'Served';
      case OrderStatus.completed:
        return 'Completed';
    }
  }
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  cancelled,
  refunded;

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.cancelled:
        return 'Payment Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

enum PaymentMethod {
  upi,
  cash;

  String get displayName {
    switch (this) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }
}

class OrderDetails {
  final String orderId;
  final String guestId;
  final String? tableId;
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

  OrderDetails({
    required this.orderId,
    required this.guestId,
    this.tableId,
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
  });

  factory OrderDetails.fromCart({
    required String orderId,
    required String guestId,
    required String tenantId,
    required OrderType type,
    String? tableId,
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
      'tenantId': tenantId,
      'type': type.name,
      'items': items.map((item) => item.toMap()).toList(),
      'timestamp': Timestamp.fromDate(timestamp),
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
      'paymentTimestamp': paymentTimestamp != null ? Timestamp.fromDate(paymentTimestamp!) : null,
      'chefNote': chefNote,
    };
  }

  factory OrderDetails.fromMap(Map<String, dynamic> map) {
    try {
      return OrderDetails(
        orderId: map['orderId']?.toString() ?? '',
        guestId: map['guestId']?.toString() ?? '',
        tableId: map['tableId']?.toString(),
        tenantId: map['tenantId']?.toString() ?? '',
        type: map['type'] != null 
            ? OrderType.values.firstWhere(
                (e) => e.name == map['type'],
                orElse: () => OrderType.dineIn,
              )
            : OrderType.dineIn,
        items: map['items'] != null
            ? (map['items'] as List).map((item) => OrderItem.fromMap(item)).toList()
            : [],
        timestamp: map['timestamp'] != null
            ? (map['timestamp'] is Timestamp 
                ? (map['timestamp'] as Timestamp).toDate() 
                : DateTime.parse(map['timestamp'].toString()))
            : DateTime.now(),
        status: map['status'] != null
            ? OrderStatus.values.firstWhere(
                (e) => e.name == map['status'],
                orElse: () => OrderStatus.pending,
              )
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
}

class OrderItem {
  final String id;
  final String name;
  final double price;
  final int quantity;

  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromCartItem(CartItem cartItem) {
    return OrderItem(
      id: cartItem.item.id,
      name: cartItem.item.name,
      price: cartItem.item.price,
      quantity: cartItem.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'price': price, 'quantity': quantity};
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      quantity: map['quantity'],
    );
  }

  double get total => price * quantity;
}
