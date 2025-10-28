import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scan_serve/services/tenant_service.dart';
import '../controllers/menu_controller.dart' as app_controller;
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../services/session_service.dart';
import '../models/order_model.dart';
import 'meal_time_tabs.dart';
import 'search_bar.dart' as custom_search;
import 'menu_grid.dart';
import 'menu_item_card.dart';
import 'view_order_bar.dart';
import 'order_list_screen.dart';

class HomePage extends StatelessWidget {
  final String tenantId;

  const HomePage({Key? key, required this.tenantId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HomeContent(tenantId: tenantId);
  }
}

class HomeContent extends StatefulWidget {
  final String tenantId;

  const HomeContent({Key? key, required this.tenantId}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String? _tenantName;
  bool _isLoadingTenant = true;
  bool? _isVegOnly;
  bool _showNonVeg = false;
  String? _guestId;

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _loadTenantInfo();
    // Load menu items when the home content is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuController = context.read<app_controller.MenuController>();
      menuController.loadMenuItems(widget.tenantId);
      // Set default filter to Veg
      menuController.setVegFilter(false);

      // Test Firebase connection and category filtering
      Future.delayed(const Duration(seconds: 2), () {
        print('🧪 TESTING CATEGORY FILTERING...');
        menuController.testFirebaseConnection();
      });
    });
  }

  Future<void> _initializeSession() async {
    try {
      final sessionService = SessionService();
      final orderController = context.read<OrderController>();

      // Create or get guest session
      if (_guestId == null) {
        _guestId = await sessionService.createGuestSession(widget.tenantId);
        // Order type is already set by app.dart based on URL parameters
        final currentOrderType = orderController.currentOrderType;
        final currentTableId = orderController.currentSession?.tableId;
        await sessionService.updateGuestSession(
          _guestId!,
          currentOrderType,
          tableId: currentTableId,
        );
      }

      // Show snackbar notification
      _showOrderTypeNotification();
    } catch (e) {
      print('Error initializing session: $e');
    }
  }

  void _showOrderTypeNotification() {
    final orderController = context.read<OrderController>();
    final currentOrderType = orderController.currentOrderType;
    final tableId = orderController.currentSession?.tableId;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              currentOrderType == OrderType.dineIn
                  ? Icons.restaurant
                  : Icons.takeout_dining,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                currentOrderType == OrderType.dineIn
                    ? 'Dine-in order${tableId != null ? " - Table $tableId" : ""}'
                    : 'Parcel order',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        backgroundColor: currentOrderType == OrderType.dineIn
            ? Colors.orange.shade700
            : Colors.green.shade700,
      ),
    );
  }

  // Order type selection removed - now determined by URL parameters

  /// Format table ID from 'Table_1' or 'table_1' to 'T1'
  String _formatTableId(String tableId) {
    // Remove 'table_' or 'Table_' prefix and convert to T{number}
    final cleaned = tableId.replaceAll(RegExp(r'[Tt]able[_-]?', caseSensitive: false), '');
    return 'T$cleaned';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TODO: Re-enable offline service when properly configured
    // final offlineService = Provider.of<OfflineService>(context);
    // offlineService.connectionStatus.listen((isOnline) {
    //   if (mounted) {
    //     if (isOnline) {
    //       offlineService.showOnlineSnackbar(context);
    //     } else {
    //       offlineService.showOfflineSnackbar(context);
    //     }
    //   }
    // });
  }

  Future<void> _loadTenantInfo() async {
    try {
      final tenantService = TenantService();
      final tenant = await tenantService.getTenantInfo(widget.tenantId);
      if (mounted) {
        setState(() {
          _tenantName = tenant?.name ?? 'Restaurant';
          _isVegOnly = tenant?.isVegOnly ?? false;
          _isLoadingTenant = false;
        });
      }
    } catch (e) {
      print('Error loading tenant info: $e');
      if (mounted) {
        setState(() {
          _tenantName = 'Restaurant';
          _isVegOnly = false;
          _isLoadingTenant = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Enhanced responsive breakpoints for better UX with Material 3
    double searchBarMaxWidth;
    EdgeInsets searchPadding;
    double appBarElevation;
    double iconSize;

    if (screenWidth < 480) {
      // Very small mobile
      searchBarMaxWidth = double.infinity;
      searchPadding = const EdgeInsets.fromLTRB(12, 12, 12, 20);
      appBarElevation = 2;
      iconSize = 22;
    } else if (screenWidth < 600) {
      // Mobile
      searchBarMaxWidth = double.infinity;
      searchPadding = const EdgeInsets.fromLTRB(16, 12, 16, 20);
      appBarElevation = 2;
      iconSize = 24;
    } else if (screenWidth < 900) {
      // Tablet portrait
      searchBarMaxWidth = 450;
      searchPadding = const EdgeInsets.fromLTRB(20, 16, 20, 24);
      appBarElevation = 3;
      iconSize = 26;
    } else if (screenWidth < 1200) {
      // Tablet landscape
      searchBarMaxWidth = 500;
      searchPadding = const EdgeInsets.fromLTRB(24, 20, 24, 28);
      appBarElevation = 4;
      iconSize = 28;
    } else {
      // Desktop
      searchBarMaxWidth = 550;
      searchPadding = const EdgeInsets.fromLTRB(28, 24, 28, 32);
      appBarElevation = 4;
      iconSize = 30;
    }

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            final orderController = context.watch<OrderController>();
            final tableId = orderController.currentSession?.tableId;
            
            return Container(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.7),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tenant name
                    Flexible(
                      child: Text(
                        _isLoadingTenant
                            ? 'Loading...'
                            : (_tenantName ?? 'Restaurant'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Table badge (only show if tableId exists)
                    if (tableId != null && tableId.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _formatTableId(tableId),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        elevation: appBarElevation,
        actions: [
          // Veg/Non-Veg single dot indicator
          if (!_isLoadingTenant)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: (_isVegOnly == true)
                    ? null
                    : () {
                        setState(() {
                          _showNonVeg = !_showNonVeg;
                        });
                        // Update veg filter in menu controller
                        final menuController = context
                            .read<app_controller.MenuController>();
                        menuController.setVegFilter(_showNonVeg);
                      },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _showNonVeg
                        ? Colors.red.withAlpha(15)
                        : Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _showNonVeg
                          ? Colors.red.withAlpha(50)
                          : Colors.green.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Single dot indicator
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _showNonVeg ? Colors.red : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _showNonVeg ? 'Non-Veg' : 'Veg',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _showNonVeg ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          IconButton(
            iconSize: iconSize,
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderListScreen(),
                ),
              );
            },
            tooltip: 'View Orders',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(screenWidth < 600 ? 48 : 52),
          child: const MealTimeTabs(),
        ),
      ),
      body: Column(
        children: [
          // Fixed Search Bar Section
          Container(
            color: Colors.white,
            padding: searchPadding,
            child: custom_search.SearchBar(maxWidth: searchBarMaxWidth),
          ),

          // Subtle separator
          Container(height: 1, color: Colors.grey[200]),

          // Scrollable Content
          Expanded(
            child: Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.fromLTRB(
                4,
                0,
                4,
                0,
              ), // Fixed 4px leading and trailing
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Most Ordered Items Section
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16, // Align with 4px parent padding
                          20,
                          20,
                          20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF914D),
                                        Color(0xFFFF6E40),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Most Ordered',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Consumer<app_controller.MenuController>(
                              builder: (context, menuController, child) {
                                // For now, show first 5 items as "most ordered"
                                // In a real app, this would come from analytics data
                                final mostOrderedItems = menuController
                                    .filteredItems
                                    .take(5)
                                    .toList();

                                if (mostOrderedItems.isEmpty) {
                                  return Container(
                                    width: double.infinity,
                                    height: 120,
                                    margin: const EdgeInsets.fromLTRB(
                                      16, // Match card padding alignment
                                      0,
                                      20,
                                      0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.star_outline,
                                            size: 32,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No popular items yet',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return Container(
                                  height: 220,
                                  margin: const EdgeInsets.fromLTRB(
                                    16, // Match card padding alignment
                                    0,
                                    20,
                                    0,
                                  ),
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: mostOrderedItems.length,
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final item = mostOrderedItems[index];
                                      return Container(
                                        width: 160,
                                        margin: EdgeInsets.only(right: 12),
                                        child: MenuItemCard(
                                          item: item,
                                          onAddPressed: () {
                                            context
                                                .read<CartController>()
                                                .addItem(item);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${item.name} added to cart',
                                                ),
                                                duration: const Duration(
                                                  seconds: 1,
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                margin:
                                                    const EdgeInsets.fromLTRB(
                                                      8,
                                                      20,
                                                      8,
                                                      0,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Menu Grid with responsive spacing
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16, // Align with 4px parent padding
                          20,
                          20,
                          20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Browse Menu',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const MenuGrid(),
                          ],
                        ),
                      ),
                    ),

                    // Bottom spacing
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ViewOrderBar(tenantId: widget.tenantId),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show call waiter dialog or snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Waiter has been notified!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(8, 20, 8, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              backgroundColor: Colors.deepPurple.shade700,
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 8,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.deepPurpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
