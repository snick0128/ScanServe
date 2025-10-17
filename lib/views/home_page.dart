import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scan_serve/services/tenant_service.dart';
import '../controllers/menu_controller.dart' as app_controller;
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../services/session_service.dart';
import '../models/order_model.dart';
import 'order_type_modal.dart';
import 'meal_time_tabs.dart';
import 'search_bar.dart' as custom_search;
import 'subcategory_chips.dart';
import 'menu_grid.dart';
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
  OrderType _currentOrderType = OrderType.parcel; // Default to parcel
  String? _currentTableId;
  String? _guestId;
  bool _showOrderTypeSnackbar = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _loadTenantInfo();
    // Load menu items when the home content is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuController = context.read<app_controller.MenuController>();
      menuController.loadMenuItems(widget.tenantId);
    });
  }

  Future<void> _initializeSession() async {
    try {
      final sessionService = SessionService();

      // Load last used order type
      final lastOrderType = await sessionService.getLastOrderType();
      if (lastOrderType != null) {
        setState(() {
          _currentOrderType = lastOrderType;
        });
      }

      // Load last used table ID
      final lastTableId = await sessionService.getLastTableId();
      if (lastTableId != null) {
        setState(() {
          _currentTableId = lastTableId;
        });
      }

      // Create or get guest session
      if (_guestId == null) {
        _guestId = await sessionService.createGuestSession(widget.tenantId);
        await sessionService.updateGuestSession(_guestId!, _currentOrderType, tableId: _currentTableId);
      }

      // Show snackbar notification
      _showOrderTypeNotification();

    } catch (e) {
      print('Error initializing session: $e');
    }
  }

  void _showOrderTypeNotification() {
    setState(() {
      _showOrderTypeSnackbar = true;
    });

    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showOrderTypeSnackbar = false;
        });
      }
    });
  }

  Future<void> _showOrderTypeSelectionModal() async {
    await context.showOrderTypeModal(
      tenantId: widget.tenantId,
      guestId: _guestId ?? '',
      onOrderTypeSelected: (orderType, tableId) async {
        setState(() {
          _currentOrderType = orderType;
          _currentTableId = tableId;
          _showNonVeg = false; // Reset to veg-only when changing order type
        });

        // Save to session
        final sessionService = SessionService();
        await sessionService.saveOrderType(orderType);
        if (tableId != null) {
          await sessionService.saveTableId(tableId);
        }

        // Update guest session
        if (_guestId != null) {
          await sessionService.updateGuestSession(_guestId!, orderType, tableId: tableId);
        }

        // Update order controller
        final orderController = context.read<OrderController>();
        orderController.setSession(widget.tenantId, tableId);

        // Show notification
        _showOrderTypeNotification();
      },
    );
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

    // Enhanced responsive breakpoints for better UX
    double searchBarMaxWidth;
    EdgeInsets searchPadding;
    double appBarElevation;
    double iconSize;

    if (screenWidth < 480) {
      // Very small mobile
      searchBarMaxWidth = double.infinity;
      searchPadding = const EdgeInsets.fromLTRB(8, 8, 8, 16);
      appBarElevation = 0;
      iconSize = 20;
    } else if (screenWidth < 600) {
      // Mobile
      searchBarMaxWidth = double.infinity;
      searchPadding = const EdgeInsets.fromLTRB(12, 8, 12, 16);
      appBarElevation = 0;
      iconSize = 22;
    } else if (screenWidth < 900) {
      // Tablet portrait
      searchBarMaxWidth = 400;
      searchPadding = const EdgeInsets.fromLTRB(16, 12, 16, 20);
      appBarElevation = 1;
      iconSize = 24;
    } else if (screenWidth < 1200) {
      // Tablet landscape
      searchBarMaxWidth = 450;
      searchPadding = const EdgeInsets.fromLTRB(20, 16, 20, 24);
      appBarElevation = 2;
      iconSize = 26;
    } else {
      // Desktop
      searchBarMaxWidth = 500;
      searchPadding = const EdgeInsets.fromLTRB(24, 20, 24, 28);
      appBarElevation = 2;
      iconSize = 28;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoadingTenant ? 'Loading...' : (_tenantName ?? 'Restaurant'),
          style: TextStyle(
            fontSize: screenWidth < 600 ? 20 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: appBarElevation,
        actions: [
          // Current Order Type Indicator
          if (!_isLoadingTenant)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: _showOrderTypeSelectionModal,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _currentOrderType == OrderType.dineIn
                        ? Colors.orange.withAlpha(25)
                        : Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _currentOrderType == OrderType.dineIn
                          ? Colors.orange.withAlpha(50)
                          : Colors.green.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentOrderType == OrderType.dineIn
                            ? Icons.restaurant
                            : Icons.takeout_dining,
                        size: 16,
                        color: _currentOrderType == OrderType.dineIn
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _currentOrderType.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _currentOrderType == OrderType.dineIn
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Veg/Non-Veg toggle
          if (!_isLoadingTenant)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Non-Veg',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _showNonVeg && (_isVegOnly != true),
                      onChanged: (_isVegOnly == true)
                          ? null
                          : (value) {
                              if (_isVegOnly == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('This restaurant serves only vegetarian dishes.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                setState(() {
                                  _showNonVeg = value;
                                });
                                // Update veg filter in menu controller
                                final menuController = context.read<app_controller.MenuController>();
                                menuController.setVegFilter(value);
                              }
                            },
                      activeColor: const Color(0xFFFF914D),
                      inactiveThumbColor: Colors.grey.shade400,
                    ),
                  ),
                ],
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
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar with responsive design
              Padding(
                padding: searchPadding,
                child: custom_search.SearchBar(maxWidth: searchBarMaxWidth),
              ),

              // Subcategories with responsive padding
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 600 ? 8 : 16,
                ),
                child: const SubcategoryChips(),
              ),

              // Menu Grid with responsive spacing
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: screenWidth < 600 ? 8 : 16,
                    right: screenWidth < 600 ? 8 : 16,
                    bottom: screenWidth < 600 ? 8 : 16,
                  ),
                  child: const MenuGrid(),
                ),
              ),
            ],
          ),
          // Floating cart button with responsive positioning
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ViewOrderBar(tenantId: widget.tenantId),
          ),

          // Order Type Snackbar
          if (_showOrderTypeSnackbar)
            Positioned(
              left: 16,
              right: 16,
              bottom: 100,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFFFF8F5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        _currentOrderType == OrderType.dineIn
                            ? Icons.restaurant
                            : Icons.takeout_dining,
                        color: _currentOrderType == OrderType.dineIn
                            ? Colors.orange
                            : Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You\'re ordering for ${_currentOrderType.displayName}.',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _showOrderTypeSelectionModal,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            color: Color(0xFFFF7043),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
