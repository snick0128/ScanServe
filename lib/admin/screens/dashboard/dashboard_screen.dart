import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/admin_theme.dart';
import '../../providers/admin_auth_provider.dart';
import '../../../models/order.dart' as model;
import '../../../models/bill_request_model.dart';
import '../../../services/waiter_call_service.dart';
import '../../providers/orders_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/admin_sidebar.dart';
import '../../providers/tables_provider.dart';
import '../inventory/inventory_screen.dart';
import '../orders/orders_screen.dart';
import '../menu/menu_items_screen.dart';
import '../tables/tables_screen.dart';
import '../analytics/analytics_screen.dart';
import '../../widgets/order_details_dialog.dart';
import '../../widgets/table_orders_dialog.dart';
import '../settings/settings_screen.dart';
import '../help/help_screen.dart';
import '../bills/bills_screen.dart';
import '../activity/activity_logs_screen.dart';
import '../kitchen/kds_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String tenantId;
  
  const DashboardScreen({super.key, required this.tenantId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    // Kitchen staff only gets KDS
    final auth = context.read<AdminAuthProvider>();
    if (auth.isKitchen) {
      _selectedIndex = 9;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isTablet = MediaQuery.of(context).size.width < 1200;

    return Scaffold(
      backgroundColor: AdminTheme.scaffoldBackground,
      drawer: isMobile
          ? AdminSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                _onItemTapped(index);
                Navigator.pop(context);
              },
              isCollapsed: false,
              role: context.read<AdminAuthProvider>().role,
              onToggleCollapse: () {},
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            AdminSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemTapped,
              isCollapsed: _isSidebarCollapsed,
              role: context.watch<AdminAuthProvider>().role,
              onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isMobile),
                Expanded(
                  child: _buildContent(isTablet),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isMobile) {
    final auth = context.read<AdminAuthProvider>();
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AdminTheme.topBarBackground,
        border: Border(bottom: BorderSide(color: AdminTheme.dividerColor)),
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Ionicons.menu_outline),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          Text(
            auth.isKitchen ? 'Kitchen Display System' : (_selectedIndex == 0 ? 'Dashboard Overview' : 'System Console'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AdminTheme.primaryText,
            ),
          ),
          const SizedBox(width: 48),
          if (!isMobile && !auth.isKitchen)
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                height: 40,
                decoration: BoxDecoration(
                  color: AdminTheme.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AdminTheme.dividerColor),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search orders, tables, items...',
                    hintStyle: TextStyle(color: AdminTheme.secondaryText, fontSize: 13),
                    prefixIcon: Icon(Ionicons.search_outline, size: 18, color: AdminTheme.secondaryText),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AdminTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AdminTheme.success.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AdminTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Live System',
                  style: TextStyle(
                    color: AdminTheme.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const Icon(Ionicons.notifications_outline, color: AdminTheme.secondaryText),
          const SizedBox(width: 20),
          const Icon(Ionicons.help_circle_outline, color: AdminTheme.secondaryText),
        ],
      ),
    );
  }

  Widget _buildContent(bool isTablet) {
    if (_selectedIndex != 0) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: _buildModuleContent(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKPISection(),
                const SizedBox(height: 32),
                _buildLiveOrdersSection(),
              ],
            ),
          ),
        ),
        if (!isTablet)
          Container(
            width: 320,
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AdminTheme.dividerColor)),
              color: AdminTheme.sidebarBackground,
            ),
            child: _buildStaffCallsPanel(),
          ),
      ],
    );
  }

  Widget _buildModuleContent() {
    switch (_selectedIndex) {
      case 1: return MenuItemsScreen(tenantId: widget.tenantId);
      case 2: return TablesScreen(tenantId: widget.tenantId);
      case 3: return OrdersScreen(tenantId: widget.tenantId);
      case 4: return BillsScreen(tenantId: widget.tenantId);
      case 5: return AnalyticsScreen(tenantId: widget.tenantId);
      case 6: return const Center(child: Text('Staff Management'));
      case 7: return SettingsScreen(tenantId: widget.tenantId);
      case 8: return InventoryScreen(tenantId: widget.tenantId);
      case 9: return KDSScreen(tenantId: widget.tenantId);
      default: return const Center(child: Text('Coming Soon'));
    }
  }

  Widget _buildKPISection() {
    return Consumer<OrdersProvider>(
      builder: (context, ordersProvider, _) {
        final tablesProvider = context.watch<TablesProvider>();
        final notificationsProvider = context.watch<NotificationsProvider>();
        
        final revenue = ordersProvider.allOrders
            .where((o) => o.status == model.OrderStatus.completed)
            .fold<double>(0, (sum, o) => sum + o.total);

        final activeKotCount = ordersProvider.orders
            .where((o) => o.status == model.OrderStatus.preparing)
            .length;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width < 1400 ? 2 : 5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _buildKPICard('Active Tables', '${tablesProvider.activeSessionsCount}/${tablesProvider.totalTablesCount}', 'Live occupancy', Ionicons.restaurant_outline, AdminTheme.success),
            _buildKPICard('Ongoing Orders', ordersProvider.orders.length.toString(), 'Active and served', Ionicons.cart_outline, AdminTheme.info),
            _buildKPICard('Active KOT', activeKotCount.toString(), 'Being prepared', Ionicons.flame_outline, AdminTheme.warning),
            _buildKPICard('Pending Bills', notificationsProvider.pendingBillRequestsCount.toString(), 'Ready to pay', Ionicons.receipt_outline, AdminTheme.critical),
            _buildKPICard('Daily Revenue', '₹${NumberFormat('#,##,###').format(revenue)}', 'Gross today', Ionicons.cash_outline, AdminTheme.success),
          ],
        );
      },
    );
  }

  Widget _buildKPICard(String title, String value, String trend, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AdminTheme.secondaryText, fontSize: 13, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(color: AdminTheme.primaryText, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(trend, style: TextStyle(color: trend.contains('+') ? AdminTheme.success : AdminTheme.critical, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLiveOrdersSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Ionicons.flash_outline, color: AdminTheme.success, size: 20),
                SizedBox(width: 8),
                Text('Live Orders', style: TextStyle(color: AdminTheme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            TextButton(
              onPressed: () => _onItemTapped(3),
              child: const Text('View All Orders', style: TextStyle(color: AdminTheme.success, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AdminTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminTheme.dividerColor),
          ),
          child: Consumer<OrdersProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
              
              final orders = provider.orders.take(5).toList();
              
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 50,
                  dataRowHeight: 70,
                  horizontalMargin: 24,
                  columnSpacing: 20,
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('TABLE #', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText))),
                    DataColumn(label: Text('ORDER ITEMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText))),
                    DataColumn(label: Text('TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText))),
                    DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText))),
                    DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText))),
                  ],
                  rows: orders.map((order) => DataRow(
                  onSelectChanged: (_) {
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
                  cells: [
                    DataCell(Text(order.tableName ?? 'T-#', style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryText))),
                    DataCell(Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.items.map((i) => '${i.quantity}x ${i.name}').join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AdminTheme.primaryText)),
                        if (order.chefNote != null && order.chefNote!.isNotEmpty)
                          Text(order.chefNote!, style: const TextStyle(fontSize: 11, color: AdminTheme.warning)),
                      ],
                    )),
                    DataCell(Text('${DateTime.now().difference(order.createdAt).inMinutes} mins', style: const TextStyle(color: AdminTheme.primaryText))),
                    DataCell(_buildStatusBadge(order.status)),
                    DataCell(_buildActionButton(order)),
                  ],
                )).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(model.OrderStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case model.OrderStatus.pending: color = AdminTheme.info; label = 'NEW ORDER'; break;
      case model.OrderStatus.preparing: color = AdminTheme.warning; label = 'PREPARING'; break;
      case model.OrderStatus.ready: color = AdminTheme.success; label = 'READY'; break;
      default: color = AdminTheme.secondaryText; label = status.name.toUpperCase();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label, 
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActionButton(model.Order order) {
    String label;
    Color color = AdminTheme.primaryColor;
    VoidCallback? onPressed;

    if (order.status == model.OrderStatus.pending) {
      label = 'Accept';
      onPressed = () => context.read<OrdersProvider>().updateOrderStatus(order.id, model.OrderStatus.preparing);
    } else if (order.status == model.OrderStatus.preparing) {
      label = 'Complete';
      onPressed = () => context.read<OrdersProvider>().updateOrderStatus(order.id, model.OrderStatus.ready);
    } else if (order.status == model.OrderStatus.ready) {
      label = 'Served';
      onPressed = () => context.read<OrdersProvider>().updateOrderStatus(order.id, model.OrderStatus.served);
    } else {
      return const SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(80, 32),
        side: BorderSide.none,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStaffCallsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Ionicons.notifications, color: AdminTheme.critical, size: 20),
                  SizedBox(width: 8),
                  Text('Staff Calls', style: TextStyle(color: AdminTheme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AdminTheme.critical, borderRadius: BorderRadius.circular(4)),
                child: Consumer<NotificationsProvider>(
                  builder: (context, provider, _) => Text(
                    '${provider.totalNotificationsCount} NEW', 
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<NotificationsProvider>(
            builder: (context, provider, _) {
              final calls = <dynamic>[...provider.billRequests, ...provider.waiterCalls];
              if (calls.isEmpty) return const Center(child: Text('No active calls', style: TextStyle(color: AdminTheme.secondaryText)));
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: calls.length,
                itemBuilder: (context, index) {
                  final call = calls[index];
                  bool isBill = call is BillRequest;
                  String tableName = isBill ? (call as BillRequest).tableName ?? 'Table' : (call as WaiterCall).tableName ?? 'Table';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AdminTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AdminTheme.dividerColor),
                      boxShadow: [
                        BoxShadow(color: (isBill ? AdminTheme.warning : AdminTheme.critical).withOpacity(0.1), blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isBill ? AdminTheme.warning : AdminTheme.critical).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(isBill ? Ionicons.receipt : Ionicons.person, 
                            color: isBill ? AdminTheme.warning : AdminTheme.critical, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(tableName, style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
                                  const Spacer(),
                                  Text(
                                    DateFormat('h:mm a').format(isBill ? (call as BillRequest).requestedAt : (call as WaiterCall).requestedAt), 
                                    style: const TextStyle(fontSize: 10, color: AdminTheme.secondaryText)
                                  ),
                                ],
                              ),
                              Text(isBill ? 'Requested: Final Bill' : 'Requested: Waiter Service', 
                                style: const TextStyle(fontSize: 12, color: AdminTheme.secondaryText)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Ionicons.checkmark_circle_outline, color: AdminTheme.success),
                          onPressed: () {
                            if (isBill) {
                              provider.acknowledgeBillRequest((call as BillRequest).requestId);
                            } else {
                              provider.completeWaiterCall((call as WaiterCall).callId);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('VIEW RESOLVED REQUESTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText)),
            ),
          ),
        ),
      ],
    );
  }
}


