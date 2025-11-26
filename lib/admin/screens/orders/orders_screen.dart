import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/orders_provider.dart';

class OrdersScreen extends StatefulWidget {
  final String tenantId;

  const OrdersScreen({super.key, required this.tenantId});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: OrderStatus.values.length,
      vsync: this,
    );

    // Initialize the orders provider with tenant ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersProvider>().initialize(widget.tenantId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Helper methods
  String _formatStatus(OrderStatus status) {
    return status.toString().split('.').last.toUpperCase();
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y • h:mm a').format(dateTime);
  }

  List<Order> _filterOrders(List<Order> orders, {OrderStatus? status}) {
    var filtered = orders;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (order) =>
                order.id.toLowerCase().contains(_searchQuery) ||
                (order.customerName ?? '').toLowerCase().contains(
                  _searchQuery,
                ) ||
                (order.tableName ?? '').toLowerCase().contains(_searchQuery),
          )
          .toList();
    }

    // Filter by status
    if (status != null) {
      filtered = filtered.where((order) => order.status == status).toList();
    }

    return filtered;
  }

  Widget _buildOrderItem(OrderItem item) {
    return ListTile(
      leading: const Icon(Icons.fastfood, size: 40),
      title: Text(item.name),
      subtitle: Text('Qty: ${item.quantity}'),
      trailing: Text('₹${(item.price * item.quantity).toStringAsFixed(2)}'),
    );
  }

  Widget _buildOrderSummary(Order order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:'),
              Text('₹${order.subtotal.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax:'),
              Text('₹${(order.subtotal * order.tax).toStringAsFixed(2)}'),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${order.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderActions(Order order, OrdersProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (order.status == OrderStatus.pending)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(
                  provider,
                  order.id,
                  OrderStatus.preparing,
                ),
                child: const Text('Start Preparing'),
              ),
            ),
          if (order.status == OrderStatus.preparing)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton(
                onPressed: () =>
                    _updateOrderStatus(provider, order.id, OrderStatus.ready),
                child: const Text('Mark as Ready'),
              ),
            ),
          if (order.status == OrderStatus.ready)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(
                  provider,
                  order.id,
                  OrderStatus.completed,
                ),
                child: const Text('Mark as Completed'),
              ),
            ),
          if (order.status != OrderStatus.completed &&
              order.status != OrderStatus.cancelled)
            TextButton(
              onPressed: () => _showCancelDialog(order, provider),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(
    OrdersProvider provider,
    String orderId,
    OrderStatus newStatus,
  ) async {
    try {
      await provider.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order status updated to ${_formatStatus(newStatus)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update order status')),
        );
      }
    }
  }

  Future<void> _showCancelDialog(Order order, OrdersProvider provider) async {
    final reasonController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this order?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for cancellation (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await provider.cancelOrder(order.id, reasonController.text);
                if (mounted) {
                  Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order has been cancelled')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to cancel order: $e')),
                  );
                }
              }
            },
            child: const Text(
              'YES, CANCEL',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.grey;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, provider, _) {
        final orders = provider.orders;

        return Column(
          children: [
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                tabs: OrderStatus.values
                    .map((status) => Tab(text: _formatStatus(status)))
                    .toList(),
              ),
            ),
            
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search orders...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),

            // Orders list
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : orders.isEmpty
                  ? const Center(child: Text('No orders found'))
                  : TabBarView(
                      controller: _tabController,
                      children: OrderStatus.values.map((status) {
                        final filteredOrders = _filterOrders(
                          orders,
                          status: status,
                        );
                        if (filteredOrders.isEmpty) {
                          return const Center(
                            child: Text('No orders in this status'),
                          );
                        }
                        return ListView.builder(
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                title: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Order #${order.id.substring(0, 8)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    _formatDateTime(order.createdAt),
                                  ),
                                  trailing: Chip(
                                    label: Text(
                                      _formatStatus(order.status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: _getStatusColor(
                                      order.status,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                children: [
                                  const Divider(),
                                  ...order.items
                                      .map(_buildOrderItem)
                                      .toList(),
                                  const Divider(),
                                  _buildOrderSummary(order),
                                  _buildOrderActions(order, provider),
                                ],
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}
