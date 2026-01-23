import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'ordered':
        return OrderStatus.pending;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
      case 'ready_to_serve':
        return OrderStatus.ready;
      case 'served':
        return OrderStatus.served;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        try {
          return OrderStatus.values.firstWhere(
            (s) => s.name == status || s.toString().split('.').last == status,
          );
        } catch (e) {
          return OrderStatus.pending;
        }
    }
  }
}

enum OrderItemStatus {
  pending('Pending', '🕒'),
  preparing('Cooking', '👨‍🍳'),
  ready('Ready', '✅'),
  served('Served', '🍽️'),
  cancelled('Cancelled', '❌');

  final String displayName;
  final String emoji;
  const OrderItemStatus(this.displayName, this.emoji);

  static OrderItemStatus fromString(String? status) {
    if (status == null) return OrderItemStatus.pending;
    return OrderItemStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase() || e.displayName.toLowerCase() == status.toLowerCase(),
      orElse: () => OrderItemStatus.pending,
    );
  }
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  cancelled,
  refunded;

  static PaymentStatus fromString(String? status) {
    if (status == null) return PaymentStatus.pending;
    return PaymentStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => PaymentStatus.pending,
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
  final OrderItemStatus status;
  final DateTime? servedAt;
  final DateTime timestamp;
  final bool isAddon;
  final String? chefNote;
  final String? captainName;

  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes,
    this.addons,
    this.imageUrl,
    this.status = OrderItemStatus.pending,
    this.servedAt,
    DateTime? timestamp,
    this.isAddon = false,
    this.chefNote,
    this.captainName,
  }) : this.timestamp = timestamp ?? DateTime.now();

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    DateTime parseTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return OrderItem(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Unknown Item',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      notes: data['notes'],
      addons: data['addons'] != null ? List<String>.from(data['addons']) : null,
      imageUrl: data['imageUrl'],
      status: OrderItemStatus.fromString(data['status']),
      servedAt: data['servedAt'] != null ? parseTime(data['servedAt']) : null,
      timestamp: parseTime(data['timestamp'] ?? data['createdAt']),
      isAddon: data['isAddon'] ?? false,
      chefNote: data['chefNote'],
      captainName: data['captainName'],
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
      'status': status.name,
      if (servedAt != null) 'servedAt': Timestamp.fromDate(servedAt!),
      'timestamp': Timestamp.fromDate(timestamp),
      'isAddon': isAddon,
      'chefNote': chefNote,
      'captainName': captainName,
    };
  }

  OrderItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? notes,
    List<String>? addons,
    String? imageUrl,
    OrderItemStatus? status,
    DateTime? servedAt,
    DateTime? timestamp,
    bool? isAddon,
    String? chefNote,
    String? captainName,
  }) {
    return OrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      addons: addons ?? this.addons,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      servedAt: servedAt ?? this.servedAt,
      timestamp: timestamp ?? this.timestamp,
      isAddon: isAddon ?? this.isAddon,
      chefNote: chefNote ?? this.chefNote,
      captainName: captainName ?? this.captainName,
    );
  }

  double get total => price * quantity;
}

class Order {
  final String id;
  final String tenantId;
  final String? tableId;
  final String? tableName;
  final String? customerName;
  final String? customerPhone;
  final List<OrderItem> items;
  final double subtotal; // Before discount and tax
  final double discountAmount;
  final double discountPercentage;
  final double tax;
  final double total;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? paymentMethod;
  final String? paymentId;
  final String? notes;
  final String? chefNote;
  final String? cancellationReason;
  final int estimatedWaitTime;
  final String? guestId;
  final String type; // 'dineIn' or 'parcel'
  final String? captainId;
  final String? captainName;

  Order({
    required this.id,
    required this.tenantId,
    this.tableId,
    this.tableName,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0,
    this.discountPercentage = 0,
    required this.tax,
    required this.total,
    required this.status,
    this.paymentStatus = PaymentStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.paymentMethod,
    this.paymentId,
    this.notes,
    this.chefNote,
    this.cancellationReason,
    this.estimatedWaitTime = 25,
    this.guestId,
    this.type = 'dineIn',
    this.captainId,
    this.captainName,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((item) => OrderItem.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }
    
    // Improved timestamp detection
    final createdAt = data['createdAt'] ?? data['timestamp'] ?? data['paymentTimestamp'] ?? data['updatedAt'];

    return Order(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      tableId: data['tableId'],
      tableName: data['tableName'],
      customerName: data['customerName'],
      customerPhone: data['customerPhone'],
      items: items,
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      discountAmount: (data['discountAmount'] ?? 0).toDouble(),
      discountPercentage: (data['discountPercentage'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      status: data['status'] != null
          ? OrderStatus.fromString(data['status'])
          : OrderStatus.pending,
      paymentStatus: PaymentStatus.fromString(data['paymentStatus']),
      createdAt: parseDateTime(createdAt),
      updatedAt: data['updatedAt'] != null ? parseDateTime(data['updatedAt']) : null,
      paymentMethod: data['paymentMethod'],
      paymentId: data['paymentId'],
      notes: data['notes'],
      chefNote: data['chefNote'],
      cancellationReason: data['cancellationReason'],
      estimatedWaitTime: (data['estimatedWaitTime'] as num?)?.toInt() ?? 25,
      guestId: data['guestId'],
      type: data['type'] ?? 'dineIn',
      captainId: data['captainId'],
      captainName: data['captainName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': id, // Some parts of the app expect 'orderId'
      'tenantId': tenantId,
      'tableId': tableId,
      'tableName': tableName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'discountPercentage': discountPercentage,
      'tax': tax,
      'total': total,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'notes': notes,
      'chefNote': chefNote,
      'cancellationReason': cancellationReason,
      'estimatedWaitTime': estimatedWaitTime,
      'guestId': guestId,
      'type': type,
      'captainId': captainId,
      'captainName': captainName,
    };
  }

  Order copyWith({
    String? id,
    String? tenantId,
    String? tableId,
    String? tableName,
    String? customerName,
    String? customerPhone,
    List<OrderItem>? items,
    double? subtotal,
    double? discountAmount,
    double? discountPercentage,
    double? tax,
    double? total,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? paymentMethod,
    String? paymentId,
    String? notes,
    String? chefNote,
    String? cancellationReason,
    int? estimatedWaitTime,
    String? guestId,
    String? type,
    String? captainId,
    String? captainName,
  }) {
    return Order(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      notes: notes ?? this.notes,
      chefNote: chefNote ?? this.chefNote,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      estimatedWaitTime: estimatedWaitTime ?? this.estimatedWaitTime,
      guestId: guestId ?? this.guestId,
      type: type ?? this.type,
      captainId: captainId ?? this.captainId,
      captainName: captainName ?? this.captainName,
    );
  }

  // REQUIREMENT 7: Sorting logic for Active Orders
  int get urgencyScore {
    switch (status) {
      case OrderStatus.preparing: return 100;
      case OrderStatus.ready: return 90;
      case OrderStatus.pending: return 80;
      case OrderStatus.served: return 70;
      case OrderStatus.completed: return 0;
      case OrderStatus.cancelled: return 0;
    }
  }

  bool get isUrgent {
    if (status == OrderStatus.completed || status == OrderStatus.cancelled || status == OrderStatus.served) return false;
    return DateTime.now().difference(createdAt).inMinutes >= 15;
  }

  // 2️⃣ Elapsed Time – Simple English (P0)
  String get elapsedText {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    // If completed/cancelled or older than today, show formatted date
    if (status == OrderStatus.completed || status == OrderStatus.cancelled || status == OrderStatus.served || diff.inHours > 12) {
      return DateFormat('MMM d, h:mm a').format(createdAt);
    }

    final mins = diff.inMinutes;
    if (mins < 1) return 'JUST NOW';
    return '$mins MINS AGO';
  }

  // Derived status from items
  OrderStatus get derivedStatus {
    if (status == OrderStatus.completed || status == OrderStatus.cancelled) return status;
    if (items.isEmpty) return status;

    if (items.any((i) => i.status == OrderItemStatus.preparing)) return OrderStatus.preparing;
    if (items.any((i) => i.status == OrderItemStatus.ready)) return OrderStatus.ready;
    if (items.every((i) => i.status == OrderItemStatus.served)) return OrderStatus.served;
    
    return OrderStatus.pending;
  }
}
