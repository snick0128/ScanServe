import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../../../models/order.dart' as model;
import '../../providers/orders_provider.dart';
import '../../widgets/staff_order_dialog.dart';
import '../../widgets/table_orders_dialog.dart';
import '../../widgets/order_details_dialog.dart';
import '../../theme/admin_theme.dart';

class OrdersScreen extends StatefulWidget {
  final String tenantId;
  const OrdersScreen({super.key, required this.tenantId});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTableId;
  model.OrderStatus? _selectedStatus;
  bool _filterUrgentOnly = false;
  
  // Strict today boundaries
  late DateTimeRange _dateRange;
  String _dateFilterType = 'Today'; // ALL, Today, Range

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<OrdersProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider),
              _buildTabSection(provider),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrderList(provider, provider.currentOrders),
                    _buildOrderList(provider, provider.pastOrders),
                    _buildOrderList(provider, provider.pendingPaymentOrders),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(OrdersProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Management',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage and track ${provider.currentOrdersCount} active table orders',
                style: const TextStyle(color: AdminTheme.secondaryText, fontSize: 16),
              ),
            ],
          ),
          Row(
            children: [
              _buildActionCircle(Ionicons.refresh_outline, 'Refresh Feed', () => provider.initialize(widget.tenantId)),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => StaffOrderDialog(tenantId: widget.tenantId),
                ),
                icon: const Icon(Ionicons.add_outline, size: 20),
                label: const Text('New Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminTheme.primaryText,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        side: BorderSide(color: Colors.grey[200]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTabSection(OrdersProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AdminTheme.primaryColor,
            unselectedLabelColor: AdminTheme.secondaryText,
            indicatorColor: AdminTheme.primaryColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            dividerColor: Colors.grey[100],
            tabs: [
              Tab(text: 'Current Orders (${provider.currentOrdersCount})'),
              Tab(text: 'Past Orders (${provider.pastOrdersCount})'),
              Tab(text: 'Pending Payment (${provider.pendingPaymentOrdersCount})'),
            ],
          ),
          const SizedBox(height: 24),
          IntrinsicHeight(
            child: _buildFilters(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Search by table, ID or item...',
                  prefixIcon: Icon(Ionicons.search_outline, size: 18, color: AdminTheme.secondaryText),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildFilterChip(Ionicons.restaurant_outline, 'All Tables', _selectedTableId != null, () {}),
          const SizedBox(width: 12),
          _buildFilterChip(Ionicons.time_outline, 'Preparing', _selectedStatus == model.OrderStatus.preparing, () {
            setState(() => _selectedStatus = _selectedStatus == model.OrderStatus.preparing ? null : model.OrderStatus.preparing);
          }),
          const SizedBox(width: 12),
          _buildFilterChip(Ionicons.checkmark_done_outline, 'Ready', _selectedStatus == model.OrderStatus.ready, () {
            setState(() => _selectedStatus = _selectedStatus == model.OrderStatus.ready ? null : model.OrderStatus.ready);
          }),
          if (_tabController.index == 1 || _tabController.index == 2) ...[
            const SizedBox(width: 24),
            const SizedBox(height: 44, child: VerticalDivider(width: 1, color: Color(0xFFE0E0E0))),
            const SizedBox(width: 24),
            _buildDateChip('ALL', _dateFilterType == 'ALL'),
            const SizedBox(width: 12),
            _buildDateChip('Today', _dateFilterType == 'Today'),
            const SizedBox(width: 12),
            _buildDateChip(
              _dateFilterType != 'Range' ? 'Date range' : '${DateFormat('MMM dd').format(_dateRange.start)} - ${DateFormat('MMM dd').format(_dateRange.end)}',
              _dateFilterType == 'Range',
              isRange: true,
            ),
          ],
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Widget _buildDateChip(String label, bool isActive, {bool isRange = false}) {
    return GestureDetector(
      onTap: () {
        if (isRange) {
          _selectDateRange();
        } else if (label == 'ALL') {
          setState(() {
            _dateFilterType = 'ALL';
          });
        } else {
          setState(() {
            _dateFilterType = 'Today';
            final now = DateTime.now();
            _dateRange = DateTimeRange(
              start: DateTime(now.year, now.month, now.day),
              end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
            );
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AdminTheme.primaryColor : Colors.white,
          border: Border.all(color: isActive ? AdminTheme.primaryColor : Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isRange ? Ionicons.calendar_outline : Ionicons.today_outline, size: 16, color: isActive ? Colors.white : AdminTheme.secondaryText),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AdminTheme.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    // For a "small popup", let's use a standard DatePicker first.
    // If they want a range, we can show two pickers or a compact custom dialog.
    final DateTime? start = await showDatePicker(
      context: context,
      initialDate: _dateRange.start,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      helpText: 'SELECT START DATE',
    );

    if (start != null) {
      final DateTime? end = await showDatePicker(
        context: context,
        initialDate: start,
        firstDate: start,
        lastDate: DateTime.now(),
        helpText: 'SELECT END DATE',
      );

      if (end != null) {
        setState(() {
          _dateFilterType = 'Range';
          _dateRange = DateTimeRange(
            start: DateTime(start.year, start.month, start.day),
            end: DateTime(end.year, end.month, end.day, 23, 59, 59, 999),
          );
        });
      }
    }
  }

  Widget _buildFilterChip(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AdminTheme.primaryColor.withOpacity(0.1) : Colors.white,
          border: Border.all(color: isActive ? AdminTheme.primaryColor : Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? AdminTheme.primaryColor : AdminTheme.secondaryText),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isActive ? AdminTheme.primaryColor : AdminTheme.primaryText)),
            const SizedBox(width: 4),
            const Icon(Ionicons.chevron_down, size: 12, color: AdminTheme.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(OrdersProvider provider, List<model.Order> orders) {
    // Apply local filters/search (Requirement says must query backend, but provider manages the state)
    var list = _searchQuery.isEmpty ? orders : provider.searchOrders(_searchQuery).where((o) => orders.contains(o)).toList();
    
    // Apply Status Filter (for Current Orders)
    if (_tabController.index == 0) {
      if (_selectedStatus != null) {
        list = list.where((o) => o.status == _selectedStatus).toList();
      }
      if (_filterUrgentOnly) {
        list = list.where((o) => o.isUrgent).toList();
      }
    }

    // Apply Date Filter for Past Orders and Pending Payments
    if (_tabController.index == 1 || _tabController.index == 2) {
      if (_dateFilterType != 'ALL') {
        list = list.where((o) {
          // Explicit boundary check
          final time = o.createdAt;
          return time.isAfter(_dateRange.start.subtract(const Duration(milliseconds: 1))) && 
                 time.isBefore(_dateRange.end.add(const Duration(milliseconds: 1)));
        }).toList();
      }
    }

    // Comprehensive Sorting Logic
    list.sort((a, b) {
      // 1. If tracking Current Orders, prioritize Urgent
      if (_tabController.index == 0) {
        if (a.isUrgent && !b.isUrgent) return -1;
        if (!a.isUrgent && b.isUrgent) return 1;
      }
      
      // 2. Default to Newest First (Chronological)
      return b.createdAt.compareTo(a.createdAt);
    });

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.receipt_outline, size: 64, color: Colors.grey[200]),
            const SizedBox(height: 16),
            const Text('No orders found for this view', style: TextStyle(color: AdminTheme.secondaryText)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 340,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) => _OrderCard(order: list[index]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final model.Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final isUrgent = order.isUrgent;

    return InkWell(
      onTap: () {
        final isPast = order.status == model.OrderStatus.completed || 
                       order.status == model.OrderStatus.cancelled;
        
        showDialog(
          context: context,
          builder: (context) => isPast 
            ? OrderDetailsDialog(order: order)
            : TableOrdersDialog(
                tenantId: order.tenantId, 
                tableId: order.tableId ?? '', 
                tableName: order.tableName ?? 'Table'
              ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isUrgent ? AdminTheme.critical : Colors.grey[100]!, width: isUrgent ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: isUrgent ? AdminTheme.critical.withOpacity(0.05) : Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.tableName ?? 'Table',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Ionicons.time_outline, size: 12, color: isUrgent ? AdminTheme.critical : AdminTheme.secondaryText),
                          const SizedBox(width: 4),
                          Text(
                            order.elapsedText,
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold, 
                              color: isUrgent ? AdminTheme.critical : AdminTheme.secondaryText
                            ),
                          ),
                          if (isUrgent) ...[
                            const SizedBox(width: 8),
                            const Text('• URGENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AdminTheme.critical, letterSpacing: 0.5)),
                          ],
                        ],
                      ),
                    ],
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
            ),
            const Divider(height: 1),
            // Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: order.items.length,
                itemBuilder: (context, idx) {
                  final item = order.items[idx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                          child: Text('${item.quantity}x', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AdminTheme.primaryText)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildActionButton(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () {
                        final isPast = order.status == model.OrderStatus.completed || 
                                       order.status == model.OrderStatus.cancelled;
                        
                        showDialog(
                          context: context,
                          builder: (context) => isPast 
                            ? OrderDetailsDialog(order: order)
                            : TableOrdersDialog(
                                tenantId: order.tenantId, 
                                tableId: order.tableId ?? '', 
                                tableName: order.tableName ?? 'Table'
                              ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminTheme.secondaryText,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[200]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final provider = context.read<OrdersProvider>();
    String label = 'Mark Served';
    Color color = AdminTheme.primaryColor;
    VoidCallback? action;

    if (order.status == model.OrderStatus.pending) {
      label = 'Accept Order';
      color = AdminTheme.info;
      action = () => provider.updateOrderStatus(order.id, model.OrderStatus.preparing);
    } else if (order.status == model.OrderStatus.preparing) {
      label = 'Ready to Serve';
      color = AdminTheme.warning;
      action = () => provider.updateOrderStatus(order.id, model.OrderStatus.ready);
    } else if (order.status == model.OrderStatus.ready) {
      label = 'Mark Served';
      color = AdminTheme.success;
      action = () => _handleMarkServed(context, provider);
    } else if (order.status == model.OrderStatus.served) {
      if (order.paymentStatus == model.PaymentStatus.pending) {
        label = 'Mark as Paid';
        color = AdminTheme.success;
        action = () => provider.markAsPaid(order.id);
      } else {
        label = 'Already Served';
        color = AdminTheme.secondaryText;
        action = null;
      }
    }

    return ElevatedButton(
      onPressed: action,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _handleMarkServed(BuildContext context, OrdersProvider provider) async {
    await provider.updateOrderStatus(order.id, model.OrderStatus.served);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Table ${order.tableName} served. Inventory updated.'),
          backgroundColor: AdminTheme.success,
        ),
      );
    }
  }

  Widget _buildStatusBadge(model.OrderStatus status) {
    Color color;
    String label;
    switch (status) {
      case model.OrderStatus.pending:
        color = AdminTheme.info;
        label = 'NEW';
        break;
      case model.OrderStatus.preparing:
        color = AdminTheme.warning;
        label = 'PREPARING';
        break;
      case model.OrderStatus.ready:
        color = AdminTheme.success;
        label = 'READY';
        break;
      case model.OrderStatus.served:
        color = Colors.blue;
        label = 'SERVED';
        break;
      default:
        color = AdminTheme.secondaryText;
        label = status.name.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Color _getStatusColor(model.OrderStatus status) {
    switch (status) {
      case model.OrderStatus.pending: return AdminTheme.info;
      case model.OrderStatus.preparing: return AdminTheme.warning;
      case model.OrderStatus.ready: return AdminTheme.success;
      case model.OrderStatus.served: return Colors.blue;
      default: return AdminTheme.secondaryText;
    }
  }
}
