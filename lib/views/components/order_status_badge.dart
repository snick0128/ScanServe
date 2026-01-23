import 'package:flutter/material.dart';
import 'package:scan_serve/models/order_details.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  final Color? backgroundColor;
  final Color? textColor;

  const OrderStatusBadge({
    Key? key,
    required this.status,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _OrderStatusStyle style = _OrderStatusStyle.fromStatus(status);

    final Color bg = backgroundColor ?? style.background;
    final Color fg = textColor ?? style.foreground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        style.label.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _OrderStatusStyle {
  final String label;
  final Color background;
  final Color foreground;

  _OrderStatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  static _OrderStatusStyle fromStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return _OrderStatusStyle(
          label: "Pending",
          background: Colors.grey.withOpacity(0.1),
          foreground: Colors.grey[400]!,
        );
      case OrderStatus.preparing:
        return _OrderStatusStyle(
          label: "Preparing",
          background: Colors.orange.withOpacity(0.1),
          foreground: Colors.orange[400]!,
        );
      case OrderStatus.served:
        return _OrderStatusStyle(
          label: "Served",
          background: Colors.green.withOpacity(0.1),
          foreground: Colors.green[400]!,
        );
      case OrderStatus.cancelled:
        return _OrderStatusStyle(
          label: "Cancelled",
          background: Colors.red.withOpacity(0.1),
          foreground: Colors.red[400]!,
        );
      default:
        return _OrderStatusStyle(
          label: status.displayName,
          background: Colors.blue.withOpacity(0.1),
          foreground: Colors.blue[400]!,
        );
    }
  }
}
