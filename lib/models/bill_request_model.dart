import 'package:cloud_firestore/cloud_firestore.dart';

/// Bill Request Status
enum BillRequestStatus {
  pending,
  processing,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case BillRequestStatus.pending:
        return 'Pending';
      case BillRequestStatus.processing:
        return 'Processing';
      case BillRequestStatus.completed:
        return 'Completed';
      case BillRequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Bill Request Model
/// 
/// Represents a customer's request for a bill from the admin.
/// Used to notify staff that a customer wants to pay and leave.
class BillRequest {
  final String requestId;
  final String tenantId;
  final String? tableId;
  final String? tableName;
  final String guestId;
  final String customerName;
  final String? customerPhone;
  final DateTime requestedAt;
  final BillRequestStatus status;
  final List<String> orderIds;
  final String? notes;

  BillRequest({
    required this.requestId,
    required this.tenantId,
    this.tableId,
    this.tableName,
    required this.guestId,
    required this.customerName,
    this.customerPhone,
    required this.requestedAt,
    this.status = BillRequestStatus.pending,
    this.orderIds = const [],
    this.notes,
  });

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'tenantId': tenantId,
      'tableId': tableId,
      'tableName': tableName,
      'guestId': guestId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': status.name,
      'orderIds': orderIds,
      'notes': notes,
    };
  }

  /// Create from Firestore map
  factory BillRequest.fromMap(Map<String, dynamic> map) {
    return BillRequest(
      requestId: map['requestId'] as String,
      tenantId: map['tenantId'] as String,
      tableId: map['tableId'] as String?,
      tableName: map['tableName'] as String?,
      guestId: map['guestId'] as String,
      customerName: map['customerName'] as String,
      customerPhone: map['customerPhone'] as String?,
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      status: BillRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BillRequestStatus.pending,
      ),
      orderIds: List<String>.from(map['orderIds'] ?? []),
      notes: map['notes'] as String?,
    );
  }

  /// Create a copy with updated fields
  BillRequest copyWith({
    String? requestId,
    String? tenantId,
    String? tableId,
    String? tableName,
    String? guestId,
    String? customerName,
    String? customerPhone,
    DateTime? requestedAt,
    BillRequestStatus? status,
    List<String>? orderIds,
    String? notes,
  }) {
    return BillRequest(
      requestId: requestId ?? this.requestId,
      tenantId: tenantId ?? this.tenantId,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      guestId: guestId ?? this.guestId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      orderIds: orderIds ?? this.orderIds,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'BillRequest(requestId: $requestId, customerName: $customerName, table: $tableName, status: ${status.displayName})';
  }
}
