import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../providers/admin_auth_provider.dart';
import '../../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/admin_sidebar.dart';
import '../../providers/tables_provider.dart';
import '../inventory/inventory_screen.dart';
import '../orders/orders_screen.dart';
import '../menu/menu_items_screen.dart';
import '../tables/tables_screen.dart';
import '../analytics/analytics_screen.dart';
import '../settings/settings_screen.dart';
import '../help/help_screen.dart';
import '../bills/bills_screen.dart';
import '../activity/activity_logs_screen.dart';
import '../super_admin/tenant_management_screen.dart';

import 'package:intl/intl.dart';

enum DashboardFilter { today, thisWeek, thisMonth }

class DashboardScreen extends StatefulWidget {
  final String tenantId;
  
  const DashboardScreen({super.key, required this.tenantId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  DashboardFilter _currentFilter = DashboardFilter.today;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().addListener(_onNotificationReceived);
    });
  }

  int _lastBillRequestCount = 0;
  void _onNotificationReceived() {
    final notifications = context.read<NotificationsProvider>();
    if (notifications.billRequests.length > _lastBillRequestCount) {
      final latest = notifications.billRequests.last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 Bill Requested: ${latest.tableName ?? 'New Table'}'),
          backgroundColor: Colors.orange[800],
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () => _onItemTapped(0), // Go to Dashboard
          ),
        ),
      );
    }
    _lastBillRequestCount = notifications.billRequests.length;
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AdminAuthProvider>(context);
    if (authProvider.role == 'kitchen' && _selectedIndex == 0) {
      _selectedIndex = 3; // Default to Orders for kitchen staff
    } else if (authProvider.role == 'superadmin' && _selectedIndex == 0) {
      _selectedIndex = 10; // Default to Tenant Management for super admin
    } else if (authProvider.role == 'captain' && _selectedIndex == 0) {
      _selectedIndex = 2; // Default to Tables for captains
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTitle(int index) {
    switch (index) {
      case 0: return 'Dashboard';
      case 1: return 'Menu Items';
      case 2: return 'Tables';
      case 3: return 'Orders';
      case 4: return 'Bills';
      case 5: return 'Analytics';
      case 6: return 'Inventory';
      case 7: return 'Settings';
      case 8: return 'Help & Support';
      case 9: return 'Activity Logs';
      case 10: return 'Manage Restaurants';
      default: return 'ScanServe Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Scaffold(
          drawer: isMobile
              ? AdminSidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index) {
                    _onItemTapped(index);
                    Navigator.pop(context); // Close drawer
                  },
                  isCollapsed: false, // Always expanded in drawer
                  role: context.read<AdminAuthProvider>().role,
                  onToggleCollapse: () {}, // No collapse in drawer
                )
              : null,
          body: Row(
            children: [
              // Persistent Sidebar for Desktop
              if (!isMobile)
                Consumer<AdminAuthProvider>(
                  builder: (context, auth, _) => AdminSidebar(
                    selectedIndex: _selectedIndex,
                    onItemSelected: _onItemTapped,
                    isCollapsed: _isSidebarCollapsed,
                    role: auth.role,
                    onToggleCollapse: () {
                      setState(() {
                        _isSidebarCollapsed = !_isSidebarCollapsed;
                      });
                    },
                  ),
                ),

              // Main Content
              Expanded(
                child: Column(
                  children: [
                    // App Bar
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Toggle Button (Hamburger)
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Ionicons.menu_outline),
                              onPressed: () {
                                if (isMobile) {
                                  Scaffold.of(context).openDrawer();
                                } else {
                                  setState(() {
                                    _isSidebarCollapsed = !_isSidebarCollapsed;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _getTitle(_selectedIndex),
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 20,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Consumer<NotificationsProvider>(
                                builder: (context, notificationsProvider, _) {
                                  final count = notificationsProvider.totalNotificationsCount;
                                  return Stack(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Ionicons.notifications_outline),
                                        iconSize: isMobile ? 20 : 24,
                                        onPressed: () {
                                          _showNotificationsBottomSheet(context, notificationsProvider);
                                        },
                                      ),
                                      if (count > 0)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            child: Text(
                                              count > 9 ? '9+' : count.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'profile',
                                    child: Text('Profile'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'settings',
                                    child: Text('Settings'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'logout',
                                    child: Text('Logout'),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'logout') {
                                    context.read<AdminAuthProvider>().signOut();
                                  }
                                },
                                child: CircleAvatar(
                                  radius: isMobile ? 14 : 16,
                                  backgroundColor: Colors.blue,
                                  child: Icon(Ionicons.person, size: isMobile ? 16 : 20, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Main Content Area
                    Expanded(
                      child: Container(
                        color: colorScheme.background,
                        padding: const EdgeInsets.all(16),
                        child: _buildContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    final role = context.read<AdminAuthProvider>().role;
    
    // Role-based restrictions
    if (role == 'kitchen' && _selectedIndex != 3 && _selectedIndex != 8) {
      return const Center(child: Text('Access Restricted'));
    }
    
    if (role == 'captain' && _selectedIndex != 2 && _selectedIndex != 3 && _selectedIndex != 8) {
      return const Center(child: Text('Access Restricted'));
    }
    
    // Super Admin check
    if (_selectedIndex == 10 && role != 'superadmin') {
      return const Center(child: Text('Super Admin Access Required'));
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1: // Menu Items
        return MenuItemsScreen(tenantId: widget.tenantId);
      case 2: // Tables
        return TablesScreen(tenantId: widget.tenantId);
      case 3:
        return OrdersScreen(tenantId: widget.tenantId);
      case 4: // Bills
        return BillsScreen(tenantId: widget.tenantId);
      case 5: // Analytics
        return AnalyticsScreen(tenantId: widget.tenantId);
      case 6:
        return InventoryScreen(tenantId: widget.tenantId);
      case 7: // Settings
        return SettingsScreen(tenantId: widget.tenantId);
      case 8: // Help & Support
        return const HelpScreen();
      case 9: // Activity Logs
        return ActivityLogsScreen(tenantId: widget.tenantId);
      case 10: // Manage Tenants
        return const TenantManagementScreen();
      default:
        return const Center(
          child: Text(
            'Coming Soon',
            style: TextStyle(fontSize: 24, color: Colors.grey),
          ),
        );
    }
  }

  Widget _buildDashboardContent() {
    return Consumer<OrdersProvider>(
      builder: (context, ordersProvider, _) {
        print('🔥 Dashboard: Building with ${ordersProvider.orders.length} orders');
        print('🔥 Dashboard: Loading state: ${ordersProvider.isLoading}');
        print('🔥 Dashboard: Error: ${ordersProvider.error}');
        
        if (ordersProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allOrders = ordersProvider.allOrders;
        final activeOrders = ordersProvider.orders;
        
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        // Calculate filter start date
        DateTime filterStartDate;
        switch (_currentFilter) {
          case DashboardFilter.today:
            filterStartDate = today;
            break;
          case DashboardFilter.thisWeek:
            // Start of week (Monday)
            filterStartDate = today.subtract(Duration(days: today.weekday - 1));
            break;
          case DashboardFilter.thisMonth:
            // Start of month
            filterStartDate = DateTime(now.year, now.month, 1);
            break;
        }

        // Filter allOrders for revenue and count based on selected range
        final filteredOrders = allOrders.where((order) {
          return order.createdAt.isAfter(filterStartDate) && 
                 order.status != OrderStatus.cancelled;
        }).toList();
        
        final filteredRevenue = allOrders.where((order) {
          return order.createdAt.isAfter(filterStartDate) && 
                 order.status == OrderStatus.completed;
        }).fold<double>(0, (sum, order) => sum + order.total);
        
        final filteredOrdersCount = filteredOrders.length;

        // Active tables (unique table IDs from active orders)
        // Active = pending, preparing, or served (not completed or cancelled)
        // This is always based on "Current" state, not the date filter
        
        // Robust calculation using TablesProvider
        final activeTablesCount = context.watch<TablesProvider>().activeTablesCount;
        final activeOrdersCount = activeOrders.length; 

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Chips
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'Quick Filters:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('Today'),
                      selected: _currentFilter == DashboardFilter.today,
                      onSelected: (selected) {
                        if (selected) setState(() => _currentFilter = DashboardFilter.today);
                      },
                      selectedColor: Colors.blue.withOpacity(0.3),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('This Week'),
                      selected: _currentFilter == DashboardFilter.thisWeek,
                      onSelected: (selected) {
                        if (selected) setState(() => _currentFilter = DashboardFilter.thisWeek);
                      },
                      selectedColor: Colors.blue.withOpacity(0.3),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('This Month'),
                      selected: _currentFilter == DashboardFilter.thisMonth,
                      onSelected: (selected) {
                        if (selected) setState(() => _currentFilter = DashboardFilter.thisMonth);
                      },
                      selectedColor: Colors.blue.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GridView(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 350,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 160, // Increased for larger typography
                    ),
                    children: [
                       _buildStatCard(
                        title: _currentFilter == DashboardFilter.today ? 'Today\'s Orders' : 
                               _currentFilter == DashboardFilter.thisWeek ? 'This Week\'s Orders' : 'This Month\'s Orders',
                        value: filteredOrdersCount.toString(),
                        icon: Ionicons.cart_outline,
                        color: Colors.blue,
                        isMobile: constraints.maxWidth < 600,
                      ),
                      _buildStatCard(
                        title: 'Active Tables',
                        value: activeTablesCount.toString(),
                        icon: Ionicons.restaurant_outline,
                        color: Colors.green,
                        isMobile: constraints.maxWidth < 600,
                      ),
                      if (!context.read<AdminAuthProvider>().isCaptain)
                        _buildStatCard(
                          title: _currentFilter == DashboardFilter.today ? 'Today\'s Revenue' : 
                                 _currentFilter == DashboardFilter.thisWeek ? 'This Week\'s Revenue' : 'This Month\'s Revenue',
                          value: '₹${NumberFormat('#,##,###').format(filteredRevenue)}',
                          icon: Ionicons.cash_outline,
                          color: Colors.orange,
                          isMobile: constraints.maxWidth < 600,
                        ),
                      _buildStatCard(
                        title: 'Active Orders',
                        value: activeOrdersCount.toString(),
                        icon: Ionicons.receipt_outline,
                        color: Colors.purple,
                        isMobile: constraints.maxWidth < 600,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isMobile = false,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 42, // Increased from 28
                    fontWeight: FontWeight.w900, // Extra bold for impact
                    letterSpacing: -1.0,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context, NotificationsProvider notificationsProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Ionicons.notifications, color: Colors.deepPurple),
                    const SizedBox(width: 12),
                    const Text(
                      'Notifications',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Bill Requests Section
                    if (notificationsProvider.billRequests.isNotEmpty) ...[
                      const Text(
                        'Bill Requests',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...notificationsProvider.billRequests.map((request) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.receipt_long, color: Colors.white),
                          ),
                          title: Text(request.tableName ?? 'Parcel Order'),
                          subtitle: Text('${request.customerName}\n${request.requestedAt.toString().substring(11, 16)}'),
                          isThreeLine: true,
                          trailing: ElevatedButton(
                            onPressed: () async {
                              await notificationsProvider.acknowledgeBillRequest(request.requestId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Bill request acknowledged')),
                                );
                              }
                            },
                            child: const Text('View'),
                          ),
                        ),
                      )),
                      const SizedBox(height: 24),
                    ],
                    // Waiter Calls Section
                    if (notificationsProvider.waiterCalls.isNotEmpty) ...[
                      const Text(
                        'Waiter Calls',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...notificationsProvider.waiterCalls.map((call) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Icon(Icons.notifications_active, color: Colors.white),
                          ),
                          title: Text(call.tableName ?? 'Customer'),
                          subtitle: Text('${call.customerName ?? 'Guest'}\n${call.requestedAt.toString().substring(11, 16)}'),
                          isThreeLine: true,
                          trailing: ElevatedButton(
                            onPressed: () async {
                              await notificationsProvider.completeWaiterCall(call.callId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Waiter call completed')),
                                );
                              }
                            },
                            child: const Text('Done'),
                          ),
                        ),
                      )),
                    ],
                    // Empty State
                    if (notificationsProvider.billRequests.isEmpty && 
                        notificationsProvider.waiterCalls.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: Column(
                            children: [
                              Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No notifications',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
