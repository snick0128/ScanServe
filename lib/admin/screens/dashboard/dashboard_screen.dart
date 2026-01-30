import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/admin_theme.dart';
import '../../providers/admin_auth_provider.dart';
import 'package:scan_serve/utils/screen_scale.dart';
import '../../../models/order.dart' as model;
import '../../../models/bill_request_model.dart';
import '../../../services/waiter_call_service.dart';
import '../../providers/orders_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/admin_sidebar.dart';
import '../../providers/tables_provider.dart';
import '../../providers/background_print_provider.dart';
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
      bottomNavigationBar: (isMobile && !context.read<AdminAuthProvider>().isKitchen) 
          ? BottomNavigationBar(
              currentIndex: _selectedIndex == 0 ? 0 : (_selectedIndex == 2 ? 1 : (_selectedIndex == 3 ? 2 : 0)), 
              onTap: (index) {
                if (index == 0) _onItemTapped(0);
                else if (index == 1) _onItemTapped(2);
                else if (index == 2) _onItemTapped(3);
                else {
                  Builder(builder: (context) {
                    Scaffold.of(context).openDrawer();
                    return const SizedBox.shrink();
                  });
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AdminTheme.primaryColor,
              unselectedItemColor: AdminTheme.secondaryText,
              items: const [
                BottomNavigationBarItem(icon: Icon(Ionicons.grid_outline), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Ionicons.restaurant_outline), label: 'Tables'),
                BottomNavigationBarItem(icon: Icon(Ionicons.list_outline), label: 'Orders'),
                BottomNavigationBarItem(icon: Icon(Ionicons.menu_outline), label: 'More'),
              ],
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
                _buildPrinterErrorBanner(),
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
      height: 70.h,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
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
          Expanded(
            child: Text(
              auth.isKitchen ? 'Kitchen Display' : (auth.isCaptain ? 'Service Portal' : 'Admin Dashboard'),
              style: TextStyle(
                fontSize: 18.sp, // Reduced for mobile
                fontWeight: FontWeight.bold,
                color: AdminTheme.primaryText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 12.w),
          Consumer<OrdersProvider>(
            builder: (context, provider, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (provider.isSynced ? AdminTheme.success : AdminTheme.warning).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (provider.isSynced ? AdminTheme.success : AdminTheme.warning).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: provider.isSynced ? AdminTheme.success : AdminTheme.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    provider.isSynced ? 'LIVE' : 'SYNCING',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: provider.isSynced ? AdminTheme.success : AdminTheme.warning,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Consumer<BackgroundPrintProvider>(
            builder: (context, printProvider, _) {
              final isReady = printProvider.isPrinterReady;
              final color = isReady ? AdminTheme.success : AdminTheme.critical;
              
              return PopupMenuButton(
                offset: const Offset(0, 50),
                tooltip: 'Printer Status',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Ionicons.print_outline, size: 16, color: color),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isReady ? 'PRINTER READY' : 'PRINTER ERROR',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isReady ? 'Printer is connected' : 'Printer Issue Detected', 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
                        if (!isReady && printProvider.lastFailureAt != null)
                          Text('Failed at: ${DateFormat('HH:mm:ss').format(printProvider.lastFailureAt!)}', 
                            style: const TextStyle(fontSize: 12, color: AdminTheme.secondaryText)),
                        if (!isReady && printProvider.lastError != null)
                          Text(printProvider.lastError!, 
                            style: const TextStyle(fontSize: 11, color: AdminTheme.critical)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    onTap: () => printProvider.checkPrinter(),
                    child: const Row(
                      children: [
                        Icon(Ionicons.refresh_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Test Print / Re-check'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(width: 16.w),
          CircleAvatar(
            radius: 18.r,
            backgroundColor: AdminTheme.dividerColor,
            child: Icon(Ionicons.person_outline, size: 18.w, color: AdminTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterErrorBanner() {
    return Consumer<BackgroundPrintProvider>(
      builder: (context, printProvider, _) {
        if (printProvider.isPrinterReady) return const SizedBox.shrink();
        
        return Container(
          width: double.infinity,
          color: AdminTheme.critical.withOpacity(0.9),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          child: Row(
            children: [
              const Icon(Ionicons.warning_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Printer not detected or printing failed. Automatic KOTs may be missed.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => printProvider.checkPrinter(),
                child: const Text('RETRY TEST PRINT', style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isTablet) {
    if (_selectedIndex != 0) {
      return Padding(
        padding: EdgeInsets.all(24.w),
        child: _buildModuleContent(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKPISection(),
                SizedBox(height: 24.h),
                _buildLiveOrdersSection(),
              ],
            ),
          ),
        ),
        if (!isTablet)
          Container(
            width: 320.w,
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

        int crossAxisCount = 5;
        double aspectRatio = 1.3;
        
        final width = MediaQuery.of(context).size.width;
        if (width < 600) {
          crossAxisCount = 2;
          aspectRatio = 0.85; // Taller cards for mobile to avoid overflow
        } else if (width < 1100) {
          crossAxisCount = 2;
          aspectRatio = 1.8;
        } else if (width < 1500) {
          crossAxisCount = 3;
          aspectRatio = 1.5;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: aspectRatio,
          children: [
            _buildKPICard(
              'Active Tables', 
              '${tablesProvider.activeSessionsCount}/${tablesProvider.totalTablesCount}', 
              'Live occupancy', 
              Ionicons.restaurant_outline, 
              AdminTheme.success,
              onTap: () => _onItemTapped(2),
            ),
            _buildKPICard(
              'Ongoing Orders', 
              ordersProvider.orders.length.toString(), 
              'Active and served', 
              Ionicons.cart_outline, 
              AdminTheme.info,
              onTap: () => _onItemTapped(3),
            ),
            _buildKPICard(
              'Active KOT', 
              activeKotCount.toString(), 
              'Being prepared', 
              Ionicons.flame_outline, 
              AdminTheme.warning,
              onTap: () => _onItemTapped(9), // Navigate to KDS for Active KOT
            ),
            _buildKPICard(
              'Pending Bills', 
              notificationsProvider.pendingBillRequestsCount.toString(), 
              'Ready to pay', 
              Ionicons.receipt_outline, 
              AdminTheme.critical,
              onTap: () => _onItemTapped(4),
            ),
            _buildKPICard(
              'Sales', 
              '₹${NumberFormat('#,##,###').format(revenue)}', 
              'Today\'s Total', 
              Ionicons.cash_outline, 
              AdminTheme.success,
              onTap: () => _onItemTapped(5), // Analytics/Revenue
            ),
          ],
        );
      },
    );
  }

  Widget _buildKPICard(String title, String value, String trend, IconData icon, Color color, {VoidCallback? onTap}) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12.w : 20.w),
        decoration: BoxDecoration(
          color: AdminTheme.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AdminTheme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: TextStyle(color: AdminTheme.secondaryText, fontSize: isMobile ? 12.sp : 15.sp, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Icon(icon, color: color, size: isMobile ? 20.w : 24.w),
              ],
            ),
            const Expanded(child: SizedBox()), // Use Expanded instead of Spacer or fixed gap
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: TextStyle(color: AdminTheme.primaryText, fontSize: isMobile ? 24.sp : 32.sp, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 4.h),
            Text(trend, style: TextStyle(color: (trend.contains('+') || trend.contains('Live')) ? AdminTheme.success : AdminTheme.critical, fontSize: isMobile ? 11.sp : 13.sp, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveOrdersSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Ionicons.flash_outline, color: AdminTheme.success, size: 24.w),
                  SizedBox(width: 8.w),
                  Flexible(child: Text('Live Orders', style: TextStyle(color: AdminTheme.primaryText, fontSize: 20.sp, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _onItemTapped(3),
              child: Text('VIEW ALL', style: TextStyle(color: AdminTheme.success, fontWeight: FontWeight.bold, fontSize: 12.sp)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: MediaQuery.of(context).size.width < 900 ? null : 500.h, 
          decoration: BoxDecoration(
            color: MediaQuery.of(context).size.width < 900 ? Colors.transparent : AdminTheme.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: MediaQuery.of(context).size.width < 900 ? null : Border.all(color: AdminTheme.dividerColor),
          ),
          child: Consumer<OrdersProvider>(
            builder: (context, provider, _) {
              final orders = provider.orders.take(10).toList();
              if (MediaQuery.of(context).size.width < 900) {
                // MOBILE CARD VIEW
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildMobileOrderCard(order);
                  },
                );
              }
              // DESKTOP TABLE VIEW
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(25.w, 0, 25.w, 10.w),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: 800.w),
                      child: DataTable(
                        headingRowHeight: 64.h,
                        dataRowHeight: 88.h,
                        horizontalMargin: 0, // Margin handled by padding
                        columnSpacing: 40.w,
                        showCheckboxColumn: false,
                        columns: [
                          DataColumn(label: Text('TABLE #', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText))),
                          DataColumn(label: Text('ORDER ITEMS', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText))),
                          DataColumn(label: Text('TIME', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText))),
                          DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText))),
                        ],
                        rows: orders.map((order) {
                          final diff = DateTime.now().difference(order.createdAt);
                          final minutes = diff.inMinutes;
                          
                          String timeLabel;
                          Color timeColor = AdminTheme.primaryText;
                          
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

                          return DataRow(
                            onSelectChanged: (_) => _showLiveOrderDetails(context, order),
                            cells: [
                              DataCell(Text(order.tableName ?? 'T-#', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryText, fontSize: 16.sp))),
                              DataCell(Text(order.items.map((i) => '${i.quantity}x ${i.name}').join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AdminTheme.primaryText, fontSize: 15.sp))),
                              DataCell(Text(timeLabel, style: TextStyle(color: timeColor, fontSize: 15.sp, fontWeight: minutes > 20 ? FontWeight.bold : FontWeight.normal))),
                              DataCell(_buildActionButton(order)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showLiveOrderDetails(BuildContext context, model.Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Details - ${order.tableName}',
                  style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Ionicons.close, size: 24.w)),
              ],
            ),
            const Divider(),
            ...order.items.map((item) => ListTile(
              title: Text('${item.quantity}x ${item.name}', style: TextStyle(fontSize: 16.sp)),
              trailing: Text('₹${item.price * item.quantity}', style: TextStyle(fontSize: 16.sp)),
            )).toList(),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
                   Text('₹${order.total}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.sp, color: Colors.green)),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileOrderCard(model.Order order) {
    final diff = DateTime.now().difference(order.createdAt);
    final minutes = diff.inMinutes;
    final timeColor = minutes > 20 ? AdminTheme.critical : AdminTheme.secondaryText;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AdminTheme.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AdminTheme.dividerColor),
      ),
      child: InkWell(
        onTap: () => _showLiveOrderDetails(context, order),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.tableName ?? 'T-#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                _buildStatusBadge(order.status),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              order.items.map((i) => '${i.quantity}x ${i.name}').join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AdminTheme.secondaryText, fontSize: 14.sp),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${minutes}m ago',
                  style: TextStyle(color: timeColor, fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
                _buildActionButton(order),
              ],
            ),
          ],
        ),
      ),
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label, 
          style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActionButton(model.Order order) {
    String label;
    Color color = AdminTheme.primaryColor;
    VoidCallback? onPressed;
    final auth = context.read<AdminAuthProvider>();
    
    if (order.status == model.OrderStatus.pending) {
      if (!auth.isAdmin && !auth.isKitchen) return const SizedBox.shrink();
      label = 'Accept';
      onPressed = () => context.read<OrdersProvider>().updateOrderStatus(order.id, model.OrderStatus.preparing);
    } else if (order.status == model.OrderStatus.preparing) {
      if (!auth.isAdmin && !auth.isKitchen) return const SizedBox.shrink();
      label = 'Complete';
      onPressed = () => context.read<OrdersProvider>().updateOrderStatus(order.id, model.OrderStatus.ready);
    } else if (order.status == model.OrderStatus.ready) {
      if (!auth.isAdmin && !auth.isCaptain) return const SizedBox.shrink();
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        minimumSize: Size(80.w, 32.h),
        side: BorderSide.none,
      ),
      child: Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStaffCallsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(24.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Ionicons.notifications, color: AdminTheme.critical, size: 24.w),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        'Staff Calls', 
                        style: TextStyle(color: AdminTheme.primaryText, fontSize: 20.sp, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(color: AdminTheme.critical, borderRadius: BorderRadius.circular(4.r)),
                child: Consumer<NotificationsProvider>(
                  builder: (context, provider, _) => Text(
                    '${provider.totalNotificationsCount} NEW', 
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.white)
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
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: calls.length,
                itemBuilder: (context, index) {
                  final call = calls[index];
                  bool isBill = call is BillRequest;
                  String tableName = isBill ? (call as BillRequest).tableName ?? 'Table' : (call as WaiterCall).tableName ?? 'Table';
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AdminTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AdminTheme.dividerColor),
                      boxShadow: [
                        BoxShadow(color: (isBill ? AdminTheme.warning : AdminTheme.critical).withOpacity(0.1), blurRadius: 10.w),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {
                        if (isBill) {
                          _onItemTapped(4); // Navigate to Billing
                        } else {
                          // Handle waiter call logic - maybe show table details
                        }
                      },
                      borderRadius: BorderRadius.circular(16.r),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: (isBill ? AdminTheme.warning : AdminTheme.critical).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(isBill ? Ionicons.receipt : Ionicons.person, 
                              color: isBill ? AdminTheme.warning : AdminTheme.critical, size: 20.w),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(tableName, style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryText, fontSize: 15.sp), overflow: TextOverflow.ellipsis)),
                                    SizedBox(width: 8.w),
                                    Text(
                                      DateFormat('h:mm a').format(isBill ? (call as BillRequest).requestedAt : (call as WaiterCall).requestedAt), 
                                      style: TextStyle(fontSize: 12.sp, color: AdminTheme.secondaryText)
                                    ),
                                  ],
                                ),
                                Text(isBill ? 'Requested: Final Bill' : 'Requested: Waiter Service', 
                                  style: TextStyle(fontSize: 14.sp, color: AdminTheme.secondaryText), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          IconButton(
                            icon: Icon(Ionicons.checkmark_circle_outline, color: AdminTheme.success, size: 24.w),
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
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(24.w),
          child: Center(
            child: TextButton(
              onPressed: () {},
              child: Text('VIEW RESOLVED REQUESTS', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText)),
            ),
          ),
        ),
      ],
    );
  }

}
