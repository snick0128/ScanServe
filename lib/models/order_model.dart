import 'order_enums.dart';

export 'order_enums.dart';

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
  final String sessionId; // Added for Bug #6

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
    required this.sessionId,
  });

  factory OrderSession.create({
    required String guestId,
    required String tenantId,
    required OrderType type,
    String? tableId,
    String paymentStatus = 'pending',
    String paymentMethod = 'Cash',
  }) {
    final now = DateTime.now();
    return OrderSession(
      orderId: now.millisecondsSinceEpoch.toString(),
      tableId: tableId,
      tenantId: tenantId,
      type: type,
      timestamp: now,
      guestId: guestId,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      sessionId: 'session_${now.millisecondsSinceEpoch}_$guestId', // Unique session ID
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
      'sessionId': sessionId,
    };
  }
}
