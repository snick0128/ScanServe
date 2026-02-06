import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending('Pending', '🕒'),
  preparing('Preparing', '👨‍🍳'),
  ready('Ready to Serve', '✅'),
  served('Served', '🍽️'),
  billRequested('Bill Requested', '🧾'),
  paymentPending('Payment Pending', '💰'),
  completed('Completed', '👍'),
  cancelled('Cancelled', '❌');

  final String displayName;
  final String emoji;
  const OrderStatus(this.displayName, this.emoji);

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'new':
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
      case 'billrequested':
      case 'bill_requested':
        return OrderStatus.billRequested;
      case 'paymentpending':
      case 'payment_pending':
        return OrderStatus.paymentPending;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        try {
          return OrderStatus.values.firstWhere(
            (s) => s.name == status.toLowerCase() || s.toString().split('.').last == status,
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
  pending('Pending'),
  paymentPending('Payment Pending'),
  paid('Paid'),
  failed('Failed'),
  cancelled('Cancelled'),
  refunded('Refunded');

  final String displayName;
  const PaymentStatus(this.displayName);

  static PaymentStatus fromString(String? status) {
    if (status == null) return PaymentStatus.pending;
    switch (status.toLowerCase()) {
      case 'pending': return PaymentStatus.pending;
      case 'paymentpending':
      case 'payment_pending': return PaymentStatus.paymentPending;
      case 'paid': return PaymentStatus.paid;
      case 'failed': return PaymentStatus.failed;
      case 'cancelled': return PaymentStatus.cancelled;
      case 'refunded': return PaymentStatus.refunded;
      default: return PaymentStatus.pending;
    }
  }
}

enum PaymentMethod {
  upi('UPI'),
  cash('Cash');

  final String displayName;
  const PaymentMethod(this.displayName);

  static PaymentMethod fromString(String? method) {
    if (method == null) return PaymentMethod.cash;
    switch (method.toLowerCase()) {
      case 'upi': return PaymentMethod.upi;
      case 'cash': return PaymentMethod.cash;
      default: return PaymentMethod.cash;
    }
  }
}

enum OrderType {
  dineIn('Dine-in'),
  parcel('Parcel');

  final String displayName;
  const OrderType(this.displayName);

  static OrderType fromString(String? type) {
    if (type == null) return OrderType.dineIn;
    switch (type.toLowerCase()) {
      case 'dinein':
      case 'dine_in': return OrderType.dineIn;
      case 'parcel': return OrderType.parcel;
      default: return OrderType.dineIn;
    }
  }
}
