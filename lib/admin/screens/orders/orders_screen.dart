import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../../../models/order.dart' as model;
import '../../../models/tenant_model.dart';
import '../../providers/orders_provider.dart';
import '../../providers/tables_provider.dart';
import '../../widgets/staff_order_dialog.dart';
import '../../widgets/table_orders_dialog.dart';
import '../../widgets/order_details_dialog.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/bills_provider.dart';
import '../../theme/admin_theme.dart';
import '../../../services/bill_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  String _dateFilterType = 'ALL'; // ALL, Today, Range

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
      if (mounted) {
        setState(() {});
        // If tab is Past Orders (1) or Pending Payment (2), load past orders if needed
        if (_tabController.index > 0) {
          context.read<OrdersProvider>().loadPastOrders();
        }
      }
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
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(child: _buildHeader(provider)),
              SliverToBoxAdapter(child: _buildTabSection(provider)),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(provider, provider.currentOrders),
                _buildOrderList(provider, provider.pastOrders),
                _buildOrderList(provider, provider.pendingPaymentOrders),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(OrdersProvider provider) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 32, 24, isMobile ? 16 : 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orders',
                      style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.currentOrdersCount} active',
                      style: TextStyle(color: AdminTheme.secondaryText, fontSize: isMobile ? 14 : 16),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
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
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => StaffOrderDialog(tenantId: widget.tenantId),
                    ),
                    icon: const Icon(Ionicons.add_outline, size: 18),
                    label: const Text('New Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32, vertical: 16),
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
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 15),
            dividerColor: Colors.grey[100],
            tabs: [
              Tab(text: 'Current (${provider.currentOrdersCount})'),
              Tab(text: 'Past (${provider.pastOrdersCount})'),
              Tab(text: 'Unpaid (${provider.pendingPaymentOrdersCount})'),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilters(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    String getSelectedTableName(List<RestaurantTable> tables) {
      if (_selectedTableId == null) return 'All Tables';
      try {
        return tables.firstWhere((t) => t.id == _selectedTableId).name;
      } catch (e) {
        return 'Table $_selectedTableId';
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Consumer<TablesProvider>(
        builder: (context, tablesProvider, _) {
          final tables = tablesProvider.tables;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width < 900 ? 200 : 300,
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
                      hintText: 'Search...',
                      prefixIcon: Icon(Ionicons.search_outline, size: 18, color: AdminTheme.secondaryText),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildFilterChip(
                Ionicons.restaurant_outline, 
                getSelectedTableName(tables), 
                _selectedTableId != null, 
                () async {
                  final RenderBox button = context.findRenderObject() as RenderBox;
                  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                  final RelativeRect position = RelativeRect.fromRect(
                    Rect.fromPoints(
                      button.localToGlobal(Offset.zero, ancestor: overlay),
                      button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                    ),
                    Offset.zero & overlay.size,
                  );

                  final selected = await showMenu<String>(
                    context: context,
                    position: position,
                    items: [
                      const PopupMenuItem(value: 'CLEAR', child: Text('Show All Tables')),
                      const PopupMenuDivider(),
                      ...tables.map((t) => PopupMenuItem(value: t.id, child: Text(t.name))),
                    ],
                  );
                  
                  if (selected == 'CLEAR') {
                    setState(() => _selectedTableId = null);
                  } else if (selected != null) {
                    setState(() => _selectedTableId = selected);
                  }
                }
              ),
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
          );
        },
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

    // Apply Table Filter (Requirement fix)
    if (_selectedTableId != null) {
      list = list.where((o) => o.tableId == _selectedTableId).toList();
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
      final isPastTab = _tabController.index > 0;
      if (isPastTab && provider.hasPastOrdersIndexError) {
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Ionicons.alert_circle_outline, size: 64, color: AdminTheme.warning),
                const SizedBox(height: 24),
                const Text(
                  'History requires a Firestore Index',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
                ),
                const SizedBox(height: 12),
                const Text(
                  'To view past orders, you must create a composite index in the Firebase Console. This is a one-time setup.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AdminTheme.secondaryText, fontSize: 15),
                ),
                const SizedBox(height: 24),
                const SelectableText(
                  'Check your debug console logs for the auto-generated link to create the index.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryColor),
                ),
              ],
            ),
          ),
        );
      }
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

    final isMobile = MediaQuery.of(context).size.width < 900;

    return GridView.builder(
      padding: EdgeInsets.all(isMobile ? 12 : 32),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: isMobile ? 310 : 340,
        crossAxisSpacing: isMobile ? 12 : 24,
        mainAxisSpacing: isMobile ? 12 : 24,
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
                tableId: order.tableId ?? (order.type == 'parcel' ? 'PARCEL' : ''),
                tableName: order.tableName ?? (order.type == 'parcel' ? 'Parcel' : 'Table')
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Ionicons.time_outline, size: 12, color: isUrgent ? AdminTheme.critical : AdminTheme.secondaryText),
                          const SizedBox(width: 4),
                          Builder(builder: (context) {
                            final diff = DateTime.now().difference(order.createdAt);
                            final minutes = diff.inMinutes;
                            
                            String timeLabel;
                            Color timeColor = isUrgent ? AdminTheme.critical : AdminTheme.secondaryText;
                            
                            if (order.status == model.OrderStatus.served || order.status == model.OrderStatus.completed) {
                              timeLabel = 'Served at ${DateFormat('HH:mm').format(order.updatedAt ?? order.createdAt)}';
                              timeColor = AdminTheme.success;
                            } else if (minutes < 2) {
                              timeLabel = 'Just ordered';
                              timeColor = AdminTheme.info;
                            } else if (minutes > 20) {
                              timeLabel = 'Late – please check';
                              timeColor = AdminTheme.critical;
                            } else if (order.status == model.OrderStatus.preparing) {
                              timeLabel = 'Cooking for ${minutes} mins';
                              timeColor = AdminTheme.warning;
                            } else {
                              timeLabel = '${minutes}m ago';
                            }

                            return Text(
                              timeLabel,
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold, 
                                color: timeColor
                              ),
                            );
                          }),
                          if (isUrgent && order.status != model.OrderStatus.served) ...[
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
                                tableId: order.tableId ?? (order.type == 'parcel' ? 'PARCEL' : ''),
                                tableName: order.tableName ?? (order.type == 'parcel' ? 'Parcel' : 'Table')
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
    final auth = context.read<AdminAuthProvider>();
    
    String label = 'Mark Served';
    Color color = AdminTheme.primaryColor;
    VoidCallback? action;

    if (order.status == model.OrderStatus.pending) {
      if (!auth.isAdmin && !auth.isKitchen) return const SizedBox.shrink();
      label = 'Accept Order';
      color = AdminTheme.info;
      action = () => provider.updateOrderStatus(order.id, model.OrderStatus.preparing);
    } else if (order.status == model.OrderStatus.preparing) {
      if (!auth.isAdmin && !auth.isKitchen) return const SizedBox.shrink();
      label = 'Ready to Serve';
      color = AdminTheme.warning;
      action = () => provider.updateOrderStatus(order.id, model.OrderStatus.ready);
    } else if (order.status == model.OrderStatus.ready) {
      if (!auth.isAdmin && !auth.isCaptain) return const SizedBox.shrink();
      label = 'Mark Served';
      color = AdminTheme.success;
      action = () => _handleMarkServed(context, provider);
    } else if (order.status == model.OrderStatus.served) {
      if (order.paymentStatus == model.PaymentStatus.pending) {
        if (!auth.isAdmin) return const SizedBox.shrink();
        label = 'Mark as Paid';
        color = AdminTheme.success;
        action = () => _handleTableSettlement(context);
      } else {
        return const SizedBox.shrink();
      }
    } else {
      return const SizedBox.shrink();
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

  void _handleTableSettlement(BuildContext context) async {
    final provider = context.read<OrdersProvider>();
    final billsProvider = context.read<BillsProvider>();
    
    // Find all active orders for this table to settle together
    final sessionOrders = provider.allOrders.where((o) => 
      o.tableId == order.tableId && 
      o.status != model.OrderStatus.completed && 
      o.status != model.OrderStatus.cancelled
    ).toList();

    if (sessionOrders.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        final isCompact = size.width < 480;
        final maxWidth = (size.width - 24).clamp(300.0, 520.0);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Confirm Settlement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Marking table ${order.tableName} as PAID will settle ${sessionOrders.length} orders. Proceed?'),
                  const SizedBox(height: 20),
                  if (isCompact)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.success),
                          child: const Text('CONFIRM & RELEASE'),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.success),
                          child: const Text('CONFIRM & RELEASE'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      try {
        final orderIds = sessionOrders.map((o) => o.id).toList();
        final billId = await billsProvider.markAsPaid(order.tableId!, orderIds);
        
        if (context.mounted && billId != null) {
          _showSettlementSuccessDialog(context, billId);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Settlement failed: $e')));
        }
      }
    }
  }

  void _showSettlementSuccessDialog(BuildContext context, String billId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        final isCompact = size.width < 480;
        final maxWidth = (size.width - 24).clamp(300.0, 520.0);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Ionicons.checkmark_circle, color: AdminTheme.success),
                      SizedBox(width: 12),
                      Text('Success', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Session settled and table released. Print receipt?'),
                  const SizedBox(height: 20),
                  if (isCompact)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CLOSE'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            final billService = BillService();
                            final billData = await billService.getBill(order.tenantId, billId);
                            if (billData != null) {
                               _printBill(billData);
                            }
                          },
                          icon: const Icon(Ionicons.print_outline),
                          label: const Text('PRINT'),
                          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primaryColor),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            final billService = BillService();
                            final billData = await billService.getBill(order.tenantId, billId);
                            if (billData != null) {
                               _printBill(billData);
                            }
                          },
                          icon: const Icon(Ionicons.print_outline),
                          label: const Text('PRINT'),
                          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primaryColor),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _printBill(Map<String, dynamic> bill) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('SCAN & SERVE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
              pw.Divider(),
              pw.Text('Bill ID: ${bill['billId'].toString().substring(0, 8)}'),
              pw.Text('Table: ${bill['tableId']}'),
              pw.Divider(),
              pw.Table.fromTextArray(
                context: context,
                data: [
                  ['Item', 'Qty', 'Amt'],
                  ...(bill['orderDetails'] as List).expand((order) => (order['items'] as List).map((i) => [
                    i['name'],
                    i['quantity'].toString(),
                    i['total'].toString(),
                  ])),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs. ${bill['finalTotal']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
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
