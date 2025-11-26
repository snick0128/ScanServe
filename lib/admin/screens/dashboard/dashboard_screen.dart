import 'package:flutter/material.dart';
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
      case 4: return 'Analytics';
      case 5: return 'Inventory';
      case 6: return 'Settings';
      case 7: return 'Help & Support';
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
                        icon: const Icon(Icons.menu),
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
                        icon: const Icon(Icons.notifications_none),
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
                          child: Icon(Icons.person, size: 20, color: Colors.white),
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
      case 4: // Analytics
        return AnalyticsScreen(tenantId: widget.tenantId);
      case 5:
        return InventoryScreen(tenantId: widget.tenantId);
      case 6: // Settings
        return SettingsScreen(tenantId: widget.tenantId);
      case 7: // Help & Support
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
        final activeOrders = orders.where((order) => 
          order.status != OrderStatus.completed && 
          order.status != OrderStatus.cancelled &&
          order.tableId != null
        );
        final activeTables = activeOrders.map((o) => o.tableId).toSet().length;

        // Active users (unique guest IDs from active orders)
        // Note: This is an approximation based on orders
        final activeUsers = activeOrders.length; 

        print('🔥 Dashboard Stats: Total=$totalOrders, Revenue=$todaysRevenue, Tables=$activeTables, Active=$activeUsers');

        return GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              title: 'Total Orders',
              value: totalOrders.toString(),
              icon: Icons.shopping_cart_outlined,
              color: Colors.blue,
            ),
            _buildStatCard(
              title: 'Active Tables',
              value: activeTables.toString(),
              icon: Icons.table_restaurant_outlined,
              color: Colors.green,
            ),
            _buildStatCard(
              title: 'Today\'s Revenue',
              value: '₹${todaysRevenue.toStringAsFixed(0)}',
              icon: Icons.currency_rupee_outlined,
              color: Colors.orange,
            ),
            _buildStatCard(
              title: 'Active Orders',
              value: activeUsers.toString(),
              icon: Icons.receipt_long_outlined, // Changed icon to represent orders
              color: Colors.purple,
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
