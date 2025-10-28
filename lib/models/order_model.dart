enum OrderType {
  dineIn,
  parcel;

  String get displayName {
    switch (this) {
      case OrderType.dineIn:
        return 'Dine-in';
      case OrderType.parcel:
        return 'Parcel';
    }
  }
}

class OrderSession {
  final String orderId;
  final String? tableId;
  final String tenantId;
  final OrderType type;
  final DateTime timestamp;
  final String guestId;
  final int estimatedWaitTime; // in minutes
  final String status;
  final String paymentStatus; // 'paid' or 'pending'
  final String paymentMethod; // 'UPI' or 'Cash'

  OrderSession({
    required this.orderId,
    this.tableId,
    required this.tenantId,
    required this.type,
    required this.timestamp,
    required this.guestId,
    this.estimatedWaitTime = 30,
    this.status = 'Pending',
    this.paymentStatus = 'pending',
    this.paymentMethod = 'Cash',
  });

  factory OrderSession.create({
    required String guestId,
    required String tenantId,
    required OrderType type,
    String? tableId,
    String paymentStatus = 'pending',
    String paymentMethod = 'Cash',
  }) {
    return OrderSession(
      orderId: DateTime.now().millisecondsSinceEpoch.toString(),
      tableId: tableId,
      tenantId: tenantId,
      type: type,
      timestamp: DateTime.now(),
      guestId: guestId,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'tableId': tableId,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'guestId': guestId,
      'estimatedWaitTime': estimatedWaitTime,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
    };
  }
}
