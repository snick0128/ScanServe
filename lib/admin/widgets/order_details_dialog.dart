import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../../models/order.dart';
import '../theme/admin_theme.dart';

class OrderDetailsDialog extends StatelessWidget {
  final Order order;

  const OrderDetailsDialog({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.tableName ?? 'Table Order',
                      style: const TextStyle(fontSize: 16, color: AdminTheme.secondaryText, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            const Text('ORDER ITEMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 1)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: order.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                        child: Text('${item.quantity}x', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            if (item.notes != null && item.notes!.isNotEmpty)
                              Text(item.notes!, style: const TextStyle(fontSize: 13, color: AdminTheme.warning, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      Text('₹${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(color: AdminTheme.secondaryText)),
                Text('₹${order.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tax (5%)', style: TextStyle(color: AdminTheme.secondaryText)),
                Text('₹${order.tax.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            if (order.discountAmount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount', style: TextStyle(color: AdminTheme.critical)),
                  Text('-₹${order.discountAmount.toStringAsFixed(2)}', style: const TextStyle(color: AdminTheme.critical, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('GRAND TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
                Text('₹${order.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AdminTheme.primaryColor)),
              ],
            ),
            if (order.paymentNote != null && order.paymentNote!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('SETTLEMENT NOTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                child: Text(order.paymentNote ?? '', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.blue)),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DATE & TIME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText)),
                      const SizedBox(height: 4),
                      Text(DateFormat('MMM dd, y • hh:mm a').format(order.createdAt), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PAYMENT DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText)),
                      const SizedBox(height: 4),
                      Text(
                        '${order.paymentMethod?.toUpperCase() ?? 'PENDING'}${order.status == OrderStatus.completed ? ' • OK' : ''}', 
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: order.status == OrderStatus.completed ? AdminTheme.success : AdminTheme.secondaryText)
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.completed: color = AdminTheme.success; break;
      case OrderStatus.cancelled: color = AdminTheme.critical; break;
      case OrderStatus.pending: color = AdminTheme.info; break;
      case OrderStatus.preparing: color = AdminTheme.warning; break;
      default: color = AdminTheme.secondaryText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
