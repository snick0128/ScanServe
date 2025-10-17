import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/cart_controller.dart';
import 'order_model.dart';

enum OrderStatus {
  pending,
  preparing,
  ready,
  served,
  completed;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
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
    };
  }

  factory OrderDetails.fromMap(Map<String, dynamic> map) {
    return OrderDetails(
      orderId: map['orderId'],
      guestId: map['guestId'],
      tableId: map['tableId'],
      tenantId: map['tenantId'],
      type: OrderType.values.firstWhere((e) => e.name == map['type']),
      items: (map['items'] as List)
          .map((item) => OrderItem.fromMap(item))
          .toList(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      status: OrderStatus.values.firstWhere((e) => e.name == map['status']),
      estimatedWaitTime: map['estimatedWaitTime'],
      subtotal: map['subtotal'],
      tax: map['tax'],
      total: map['total'],
    );
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
