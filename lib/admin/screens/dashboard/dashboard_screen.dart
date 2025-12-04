import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/admin_sidebar.dart';
import '../inventory/inventory_screen.dart';
import '../orders/orders_screen.dart';
import '../menu/menu_items_screen.dart';
import '../tables/tables_screen.dart';
import '../analytics/analytics_screen.dart';
import '../settings/settings_screen.dart';
import '../help/help_screen.dart';
import '../bills/bills_screen.dart';

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
    // Initialize OrdersProvider with the correct tenant ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
      print('🔥 Dashboard: Initializing OrdersProvider with tenantId: ${widget.tenantId}');
      ordersProvider.initialize(widget.tenantId);
    });
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
      default: return 'ScanServe Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AdminSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemTapped,
            isCollapsed: _isSidebarCollapsed,
            onToggleCollapse: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Ionicons.menu_outline),
                        onPressed: () {
                          setState(() {
                            _isSidebarCollapsed = !_isSidebarCollapsed;
                          });
                        },
                      ),
                      Text(
                        _getTitle(_selectedIndex),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // User profile and notifications would go here
                      IconButton(
                        icon: const Icon(Ionicons.notifications_outline),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
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
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue,
                          child: Icon(Ionicons.person, size: 20, color: Colors.white),
                        ),
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
  }

  Widget _buildContent() {
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

        final orders = ordersProvider.orders;
        final totalOrders = orders.length;
        
        // Calculate today's revenue
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final todaysOrders = orders.where((order) {
          return order.createdAt.isAfter(today) && 
                 order.status != OrderStatus.cancelled;
        });
        
        final todaysRevenue = todaysOrders.fold<double>(
          0, (sum, order) => sum + order.total
        );

        // Active tables (unique table IDs from active orders)
        // Active = pending or preparing (not served or cancelled)
        final activeOrders = orders.where((order) => 
          order.status != OrderStatus.served && 
          order.status != OrderStatus.cancelled &&
          order.tableId != null
        );
        final activeTables = activeOrders.map((o) => o.tableId).toSet().length;

        // Active users (unique guest IDs from active orders)
        // Note: This is an approximation based on orders
        final activeOrdersCount = activeOrders.length; 

        print('🔥 Dashboard Stats: Total=$totalOrders, Revenue=$todaysRevenue, Tables=$activeTables, Active=$activeOrdersCount');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Chips
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
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
                    selected: true,
                    onSelected: (selected) {
                      // Filter logic can be added here
                    },
                    selectedColor: Colors.blue.withOpacity(0.3),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('This Week'),
                    selected: false,
                    onSelected: (selected) {
                      // Filter logic can be added here
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('This Month'),
                    selected: false,
                    onSelected: (selected) {
                      // Filter logic can be added here
                    },
                  ),
                ],
              ),
            ),

            // Metrics Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    title: 'Total Orders',
                    value: totalOrders.toString(),
                    icon: Ionicons.cart_outline,
                    color: Colors.blue,
                  ),
                  _buildStatCard(
                    title: 'Active Tables',
                    value: activeTables.toString(),
                    icon: Ionicons.restaurant_outline,
                    color: Colors.green,
                  ),
                  _buildStatCard(
                    title: 'Today\'s Revenue',
                    value: '₹${todaysRevenue.toStringAsFixed(0)}',
                    icon: Ionicons.cash_outline,
                    color: Colors.orange,
                  ),
                  _buildStatCard(
                    title: 'Active Orders',
                    value: activeOrdersCount.toString(),
                    icon: Ionicons.receipt_outline,
                    color: Colors.purple,
                  ),
                ],
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
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
