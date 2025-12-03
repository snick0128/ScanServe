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
  
  // Badge tracking
  List<Order> _previousOrders = [];
  final Map<OrderStatus, Set<String>> _unseenOrderIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: OrderStatus.values.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabSelection);

    // Initialize the orders provider with tenant ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrdersProvider>();
      provider.initialize(widget.tenantId);
      provider.addListener(_onOrdersChanged);
    });
  }

  @override
  void dispose() {
    context.read<OrdersProvider>().removeListener(_onOrdersChanged);
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    
    // When tab settles, clear badges for that tab
    final currentStatus = OrderStatus.values[_tabController.index];
    if (_unseenOrderIds.containsKey(currentStatus) && _unseenOrderIds[currentStatus]!.isNotEmpty) {
      setState(() {
        _unseenOrderIds[currentStatus]!.clear();
      });
    }
  }

  void _onOrdersChanged() {
    if (!mounted) return;
    final provider = context.read<OrdersProvider>();
    final newOrders = provider.orders;
    
    // Initial load - don't mark as unseen
    if (_previousOrders.isEmpty && newOrders.isNotEmpty) {
      _previousOrders = List.from(newOrders);
      return;
    }

    bool changed = false;
    final currentTabStatus = OrderStatus.values[_tabController.index];

    for (final order in newOrders) {
      final previousOrderIndex = _previousOrders.indexWhere((o) => o.id == order.id);
      
      if (previousOrderIndex == -1) {
        // New order
        if (order.status != currentTabStatus) {
          _unseenOrderIds.putIfAbsent(order.status, () => {}).add(order.id);
          changed = true;
        }
      } else {
        // Existing order
        final previousOrder = _previousOrders[previousOrderIndex];
        if (previousOrder.status != order.status) {
          // Status changed
          if (order.status != currentTabStatus) {
             _unseenOrderIds.putIfAbsent(order.status, () => {}).add(order.id);
             changed = true;
          }
        }
      }
    }
    
    _previousOrders = List.from(newOrders);
    
    if (changed) {
      setState(() {});
    }
  }

  // Helper methods
  String _formatStatus(OrderStatus status) {
    return status.toString().split('.').last.toUpperCase();
  }



  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }

  String _getPrimaryActionText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Start Preparing';
      case OrderStatus.preparing:
        return 'Mark Ready';
      case OrderStatus.ready:
        return 'Mark Completed';
      default:
        return '';
    }
  }

  OrderStatus? _getNextStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.completed;
      default:
        return null;
    }
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.fastfood, size: 50),
              ),
            )
          else
            const Icon(Icons.fastfood, size: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${(item.price * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Order order) {
    // Calculate tax amount (assuming tax is stored as decimal like 0.18 for 18%)
    final taxAmount = order.tax < 1 ? order.subtotal * order.tax : order.tax;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(fontSize: 14)),
              Text('₹${order.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax (${order.tax < 1 ? "${(order.tax * 100).toStringAsFixed(0)}%" : "GST"}):',
                style: const TextStyle(fontSize: 14),
              ),
              Text('₹${taxAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '₹${order.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactOrderCard(Order order, OrdersProvider provider) {
    final itemCount = order.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final nextStatus = _getNextStatus(order.status);
    final actionText = _getPrimaryActionText(order.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(order.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${order.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatStatus(order.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.table_restaurant, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        order.tableName ?? 'No Table',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _getTimeAgo(order.createdAt),
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '$itemCount item${itemCount > 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₹${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (nextStatus != null)
              ElevatedButton(
                onPressed: () => _updateOrderStatus(provider, order.id, nextStatus),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getStatusColor(nextStatus),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  actionText,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Order Items',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          ...order.items.map(_buildOrderItem).toList(),
          const SizedBox(height: 8),
          const Divider(height: 1),
          _buildOrderSummary(order),
          if (order.status != OrderStatus.completed &&
              order.status != OrderStatus.cancelled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showCancelDialog(order, provider),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel Order'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
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
            backgroundColor: _getStatusColor(newStatus),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update order status'),
            backgroundColor: Colors.red,
          ),
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
                      const SnackBar(
                        content: Text('Order has been cancelled'),
                        backgroundColor: Colors.red,
                      ),
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
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
      case OrderStatus.served:
        return Colors.grey;
      case OrderStatus.completed:
        return Colors.grey;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, provider, _) {
        final orders = provider.orders;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  toolbarHeight: 0,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          final currentIndex = _tabController.index;
                          final currentStatus = OrderStatus.values[currentIndex];
                          final activeColor = _getStatusColor(currentStatus);

                          return TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelColor: activeColor,
                            unselectedLabelColor: Colors.grey[600],
                            indicatorColor: activeColor,
                            indicatorWeight: 3,
                            indicatorSize: TabBarIndicatorSize.label,
                            indicator: UnderlineTabIndicator(
                              borderSide: BorderSide(width: 3, color: activeColor),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                            tabs: OrderStatus.values.map((status) {
                              final unseenCount = _unseenOrderIds[status]?.length ?? 0;
                              
                              return Tab(
                                height: 56,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_formatStatus(status)),
                                    if (unseenCount > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          unseenCount > 9 ? '9+' : unseenCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ];
            },

            body: Column(
              children: [
                // Search bar with reduced margin
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search orders...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.grey[50],
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
                          ? _buildEmptyState('No orders found')
                          : TabBarView(
                              controller: _tabController,
                              children: OrderStatus.values.map((status) {
                                final filteredOrders = _filterOrders(
                                  orders,
                                  status: status,
                                );
                                
                                if (filteredOrders.isEmpty) {
                                  return _buildEmptyState(
                                    'No ${_formatStatus(status).toLowerCase()} orders',
                                  );
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: filteredOrders.length,
                                  itemBuilder: (context, index) {
                                    final order = filteredOrders[index];
                                    // Use a key to ensure proper recycling and animation
                                    return AnimatedOrderCard(
                                      key: ValueKey(order.id),
                                      child: _buildCompactOrderCard(order, provider),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class AnimatedOrderCard extends StatefulWidget {
  final Widget child;

  const AnimatedOrderCard({super.key, required this.child});

  @override
  State<AnimatedOrderCard> createState() => _AnimatedOrderCardState();
}

class _AnimatedOrderCardState extends State<AnimatedOrderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.05), // Slide down slightly
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
