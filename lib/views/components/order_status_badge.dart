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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final _OrderStatusStyle style = _OrderStatusStyle.fromStatus(
      status,
      colorScheme,
    );

    final Color bg = backgroundColor ?? style.background;
    final Color fg = textColor ?? style.foreground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        style.label,
        style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// Helper class for status color/label mapping
class _OrderStatusStyle {
  final String label;
  final Color background;
  final Color foreground;

  _OrderStatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  static _OrderStatusStyle fromStatus(
    OrderStatus status,
    ColorScheme colorScheme,
  ) {
    switch (status) {
      case OrderStatus.pending:
        return _OrderStatusStyle(
          label: "Pending",
          background: Colors.grey.shade300,
          foreground: Colors.grey.shade900,
        );
      case OrderStatus.confirmed:
        return _OrderStatusStyle(
          label: "Confirmed",
          background: colorScheme.primary.withOpacity(0.18),
          foreground: colorScheme.primary,
        );
      case OrderStatus.preparing:
        return _OrderStatusStyle(
          label: "Preparing",
          background: Colors.orange.shade100,
          foreground: Colors.orange.shade800,
        );
      case OrderStatus.ready:
        return _OrderStatusStyle(
          label: "Ready",
          background: Colors.green.shade100,
          foreground: Colors.green.shade800,
        );
      case OrderStatus.served:
        return _OrderStatusStyle(
          label: "Served",
          background: Colors.purple.shade100,
          foreground: Colors.purple.shade800,
        );
      case OrderStatus.completed:
        return _OrderStatusStyle(
          label: "Completed",
          background: Colors.teal.shade100,
          foreground: Colors.teal.shade800,
        );
      default:
        return _OrderStatusStyle(
          label: status.toString(),
          background: Colors.grey.shade200,
          foreground: Colors.grey.shade800,
        );
    }
  }
}
