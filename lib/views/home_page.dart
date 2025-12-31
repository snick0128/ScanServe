import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scan_serve/services/tenant_service.dart';
import '../controllers/menu_controller.dart' as app_controller;
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../services/session_service.dart';
import 'meal_time_tabs.dart';
import 'search_bar.dart' as custom_search;
import 'menu_grid.dart';
import 'menu_item_card.dart';
import 'view_order_bar.dart';
import 'order_list_screen.dart';
import '../utils/snackbar_helper.dart';

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
  final ScrollController _mostOrderedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _loadTenantInfo();

    // Initialize scroll controller
    // Initialize scroll controller

    // Load menu items when the home content is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuController = context.read<app_controller.MenuController>();
      menuController.loadMenuItems(widget.tenantId);
      // Set default filter to Veg
      menuController.setVegFilter(false);
    });
  }



  @override
  void dispose() {
    _mostOrderedScrollController.dispose();
    super.dispose();
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

    SnackbarHelper.showTopSnackBar(
      context,
      'Order type: ${currentOrderType.toString().split('.').last}${tableId != null ? ' - Table $tableId' : ''}',
      duration: const Duration(seconds: 2),
    );
  }

  /// Format table ID from 'Table_1' or 'table_1' to 'T1'
  String _formatTableId(String tableId) {
    // Remove 'table_' or 'Table_' prefix and convert to T{number}
    final cleaned = tableId.replaceAll(
      RegExp(r'[Tt]able[_-]?', caseSensitive: false),
      '',
    );
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

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[50], // Single source of background color
          extendBody: true, // This helps with bottom navigation bar spacing
          appBar: AppBar(
            backgroundColor: Colors.grey[50], // Match scaffold background
            surfaceTintColor: Colors.transparent, // No surface tint
            title: LayoutBuilder(
              builder: (context, constraints) {
                final orderController = context.watch<OrderController>();
                final tableId = orderController.currentSession?.tableId;

                return Container(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Tenant name with proper alignment
                        Padding(
                          padding: EdgeInsets.only(
                            left: searchPadding
                                .left, // Match search bar left padding
                          ),
                          child: Text(
                            _isLoadingTenant
                                ? 'Loading...'
                                : (_tenantName ?? 'Restaurant'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        // Table badge (only show if tableId exists)
                        if (tableId != null && tableId.isNotEmpty) ...[
                          const SizedBox(width: 10), // 10px spacing from name
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10, // Reduced from 14 to 10
                              vertical: 5, // Reduced from 7 to 5
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.deepPurple,
                                  Colors.deepPurpleAccent,
                                ],
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
                  margin: const EdgeInsets.only(
                    right: 4,
                  ), // Reduced right margin
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
                        horizontal: 10, // Reduced horizontal padding
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
                color: Colors.transparent, // Transparent background
                padding: searchPadding,
                child: custom_search.SearchBar(maxWidth: searchBarMaxWidth),
              ),

              // Removed separator for cleaner look

              // Scrollable Content
              Expanded(
                child: Container(
                  color: Colors.transparent, // Transparent to show Scaffold background
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
                          // No decoration (background/shadow) for section
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
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
                                        '🔥 Crowd Favorites',
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
                                    final items = menuController.filteredItems;
                                    final mostOrderedItems = items.isEmpty
                                        ? []
                                        : items.take(5).toList();

                                    if (mostOrderedItems.isEmpty) {
                                      return Container(
                                        width: double.infinity,
                                        height: 120,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ), // Consistent horizontal padding
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                              const SizedBox(height: 12),
                                              Center(
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: List<Widget>.generate(
                                                    mostOrderedItems.length,
                                                    (index) => Container(
                                                      width: 6,
                                                      height: 6,
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: index == 0
                                                            ? Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                            : Colors.grey[300],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
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

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Scroll hint indicator (only show on first load)
                                        if (_showSwipeHint)
                                          Container(
                                            padding: const EdgeInsets.only(
                                              left: 4,
                                              bottom: 8,
                                            ),
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Scrollable list
                                        SizedBox(
                                          height:
                                              240, // Increased height to accommodate the card
                                          child: ListView.builder(
                                            controller:
                                                _mostOrderedScrollController,
                                            scrollDirection: Axis.horizontal,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            itemCount: mostOrderedItems.length,
                                            shrinkWrap: true,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            clipBehavior: Clip.hardEdge,
                                            itemBuilder: (context, index) {
                                              final item =
                                                  mostOrderedItems[index];
                                              return Container(
                                                width: 160,
                                                margin: EdgeInsets.only(
                                                  right:
                                                      index ==
                                                          mostOrderedItems
                                                                  .length -
                                                              1
                                                      ? 0
                                                      : 16,
                                                ),
                                                child: MenuItemCard(
                                                  item: item,
                                                  onAddPressed: () {
                                                    context
                                                        .read<CartController>()
                                                        .addItem(item);
                                                    SnackbarHelper.showTopSnackBar(
                                                      context,
                                                      '${item.name} added to cart',
                                                      duration: const Duration(
                                                        seconds: 1,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
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
                          // No decoration (background/shadow) for section
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

                        // Bottom spacing to prevent overlap with floating UI
                        const SizedBox(height: 100),

                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: ViewOrderBar(tenantId: widget.tenantId),
        ),
        // Custom positioned FAB with tooltip
        Consumer2<CartController, OrderController>(
          builder: (context, cartController, orderController, child) {
            // Determine if ViewOrderBar is visible
            final hasPendingOrders = orderController.activeOrders.isNotEmpty;
            final cartIsEmpty = cartController.itemCount == 0;
            final isBarVisible = !cartIsEmpty || hasPendingOrders;

            return Positioned(
              right: 20,
              bottom: isBarVisible ? 85 : 30, // Adjust based on bar visibility
              child: Tooltip(
                message: 'Call Waiter',
                preferBelow: false,
                verticalOffset: 10,
            decoration: BoxDecoration(
              color: Colors.deepPurple[800],
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            child: GestureDetector(
              onTap: () {
                // Show call waiter dialog or snackbar
                SnackbarHelper.showTopSnackBar(
                  context,
                  'Waiter has been notified!',
                  duration: const Duration(seconds: 3),
                );
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
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
          ),
            );
          },
        ),
      ],
    );
  }
}
