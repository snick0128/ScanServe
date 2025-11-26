import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/order_controller.dart';
import '../models/order_details.dart';

class OrderStatusCard extends StatelessWidget {
  final String orderId;
  final String tenantId;

  const OrderStatusCard({
    super.key,
    required this.orderId,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderController>(
      builder: (context, orderController, _) {
        final order = orderController.activeOrders.firstWhere(
          (o) => o.orderId == orderId,
          orElse: () => OrderDetails.empty(),
        );

        if (order.orderId.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.orderId.substring(0, 8)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildStatusChip(order.status),
                  ],
                ),
                const SizedBox(height: 8),
                _buildStatusLine(order.status),
                const SizedBox(height: 8),
                Text(
                  _getStatusMessage(order.status),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color statusColor;
    switch (status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        break;
      case OrderStatus.confirmed:
        statusColor = Colors.blue.shade300;
        break;
      case OrderStatus.preparing:
        statusColor = Colors.blue;
        break;
      case OrderStatus.ready:
        statusColor = Colors.green;
        break;
      case OrderStatus.served:
        statusColor = Colors.green.shade700;
        break;
      case OrderStatus.completed:
        statusColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        status.toString().split('.').last.toUpperCase(),
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusLine(OrderStatus status) {
    final double progress;
    switch (status) {
      case OrderStatus.pending:
        progress = 0.2;
        break;
      case OrderStatus.confirmed:
        progress = 0.35;
        break;
      case OrderStatus.preparing:
        progress = 0.5;
        break;
      case OrderStatus.ready:
        progress = 0.8;
        break;
      case OrderStatus.served:
        progress = 0.9;
        break;
      case OrderStatus.completed:
        progress = 1.0;
        break;
    }

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(status)),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatusDot(OrderStatus.pending, status),
            _buildStatusDot(OrderStatus.preparing, status),
            _buildStatusDot(OrderStatus.ready, status),
            _buildStatusDot(OrderStatus.completed, status),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusDot(OrderStatus dotStatus, OrderStatus currentStatus) {
    final bool isActive =
        _getStatusIndex(dotStatus) <= _getStatusIndex(currentStatus);
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? _getStatusColor(dotStatus) : Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }

  int _getStatusIndex(OrderStatus status) {
    return OrderStatus.values.indexOf(status);
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue.shade300;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.served:
        return Colors.green.shade700;
      case OrderStatus.completed:
        return Colors.grey;
    }
  }

  String _getStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Your order has been received and is waiting to be processed.';
      case OrderStatus.confirmed:
        return 'Your order has been confirmed and will be prepared soon.';
      case OrderStatus.preparing:
        return 'Your order is being prepared. It will be ready soon!';
      case OrderStatus.ready:
        return 'Your order is ready for pickup/delivery!';
      case OrderStatus.served:
        return 'Your order has been served. Enjoy your meal!';
      case OrderStatus.completed:
        return 'Order completed. Thank you for your purchase!';
    }
  }
}
