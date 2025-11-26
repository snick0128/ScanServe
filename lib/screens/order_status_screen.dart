import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scan_serve/models/order_details.dart';
import '../controllers/order_controller.dart';
import '../widgets/order_status_card.dart';

class OrderStatusScreen extends StatefulWidget {
  final String orderId;
  final String tenantId;

  const OrderStatusScreen({
    super.key,
    required this.orderId,
    required this.tenantId,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure order controller is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderController = context.read<OrderController>();
      if (orderController.currentSession == null) {
        // If no session exists, try to initialize with the provided tenant ID
        orderController.setSession(widget.tenantId, null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Status'), centerTitle: true),
      body: Consumer<OrderController>(
        builder: (context, orderController, _) {
          // Find the current order
          final order = orderController.activeOrders.firstWhere(
            (o) => o.orderId == widget.orderId,
            orElse: () => OrderDetails.empty(),
          );

          if (order.orderId.isEmpty) {
            return const Center(child: Text('Order not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OrderStatusCard(
                  orderId: order.orderId,
                  tenantId: widget.tenantId,
                ),
                const SizedBox(height: 24),
                _buildOrderItems(order),
                const SizedBox(height: 16),
                _buildOrderSummary(order),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderItems(OrderDetails order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Items', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            ...order.items.map(
              (item) => ListTile(
                leading: const Icon(Icons.fastfood),
                title: Text(item.name),
                trailing: Text('× ${item.quantity}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(OrderDetails order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _buildSummaryRow('Subtotal', order.subtotal),
            _buildSummaryRow('Tax', order.tax),
            const Divider(),
            _buildSummaryRow('Total', order.total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                : null,
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: isTotal
                ? Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                : null,
          ),
        ],
      ),
    );
  }
}
