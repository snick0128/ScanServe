import 'package:cloud_firestore/cloud_firestore.dart';

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
      'notes': notes,
      'addons': addons,
      'imageUrl': imageUrl,
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
    final data = doc.data() as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((item) => OrderItem.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    return Order(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      tableId: data['tableId'],
      tableName: data['tableName'],
      customerName: data['customerName'],
      customerPhone: data['customerPhone'],
      items: items,
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      status: data['status'] != null
          ? OrderStatus.fromString(data['status'])
          : OrderStatus.pending,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      paymentMethod: data['paymentMethod'],
      paymentStatus: data['paymentStatus'],
      notes: data['notes'],
      cancellationReason: data['cancellationReason'],
    );
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
      'cancellationReason': cancellationReason,
    };
  }
}
