import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scan_serve/services/tenant_service.dart';
import 'package:scan_serve/models/order_model.dart';
import '../controllers/menu_controller.dart' as app_controller;
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../services/session_service.dart';
import '../services/waiter_call_service.dart';
import '../services/guest_session_service.dart';
import 'meal_time_tabs.dart';
import 'search_bar.dart' as custom_search;
import 'menu_grid.dart';
import 'menu_item_card.dart';
import 'view_order_bar.dart';
import 'order_list_screen.dart';
import '../utils/snackbar_helper.dart';
import '../services/offline_service.dart';
import 'cart_page.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_helper.dart';
import 'filter_bottom_sheet.dart';
import 'payment_page.dart';

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
  int _selectedIndex = 1; // Default to Menu

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _loadTenantInfo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuController = context.read<app_controller.MenuController>();
      menuController.loadMenuItems(widget.tenantId);
    });
  }

  Future<void> _initializeSession() async {
    try {
      final sessionService = SessionService();
      final guestId = await sessionService.createGuestSession(widget.tenantId);
    } catch (e) {
      print('Error initializing session: $e');
    }
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
          _isLoadingTenant = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _callWaiter() async {
    HapticHelper.medium();
    try {
      final waiterCallService = WaiterCallService();
      final guestSessionService = GuestSessionService();
      final guestId = await guestSessionService.getGuestId();
      final session = await guestSessionService.getCurrentSession();
      final profile = await guestSessionService.getGuestProfile();
      
      await waiterCallService.createWaiterCall(
        tenantId: widget.tenantId,
        guestId: guestId,
        tableId: session['tableId'],
        tableName: session['tableId'] != null ? 'Table ${session['tableId']}' : null,
        customerName: profile?.name,
      );
      
      if (mounted) {
        SnackbarHelper.showTopSnackBar(context, 'Waiter called! Someone will be with you shortly.');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showTopSnackBar(context, 'Failed to call waiter. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _selectedIndex == 2 ? null : _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_selectedIndex == 2) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isLoadingTenant ? 'Loading...' : (_tenantName ?? 'Restaurant'),
          style: GoogleFonts.outfit(
            color: AppTheme.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return AppBar(
      backgroundColor: AppTheme.backgroundColor,
      elevation: 0,
      centerTitle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      title: Row(
        children: [
          Text(
            _isLoadingTenant ? 'Loading...' : (_tenantName ?? 'Restaurant'),
            style: GoogleFonts.outfit(
              color: AppTheme.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.primaryColor, width: 1),
            ),
            child: const Text(
              'OPEN',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Consumer<OrderController>(
          builder: (context, orderController, child) {
            if (orderController.currentOrderType == OrderType.dineIn &&
                orderController.currentSession?.tableId != null) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.table_restaurant, size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Table ${orderController.currentSession!.tableId}',
                        style: GoogleFonts.outfit(
                          color: AppTheme.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 2) {
      return CartPage(
        tenantId: widget.tenantId,
        onBack: () => setState(() => _selectedIndex = 1),
        onOrderPlaced: () => setState(() => _selectedIndex = 0),
      );
    }
    if (_selectedIndex == 0) {
      return const OrderListScreen();
    }

    return Stack(
      children: [
        Column(
          children: [
            // Filter chips
            _buildFilterChips(),

            // Menu items (Scrollable area)
            Expanded(
              child: Consumer<app_controller.MenuController>(
                builder: (context, menuController, child) {
                  final items = menuController.filteredItems;
                  final isLoading = menuController.isLoading;

                  if (isLoading) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildSectionTitle('Loading Menu...'),
                          const MenuGrid(isLoading: true),
                        ],
                      ),
                    );
                  }

                  if (items.isEmpty) {
                    return const Center(child: MenuGrid());
                  }

                  // Group items by category
                  final groupedItems = <String, List<app_controller.MenuItem>>{};
                  for (var item in items) {
                    final cat = item.category ?? 'Others';
                    groupedItems.putIfAbsent(cat, () => []).add(item);
                  }

                  // Sort category names for consistent display
                  final sortedCategories = groupedItems.keys.toList()..sort();

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        ...sortedCategories.map((category) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(category),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: MenuGrid(items: groupedItems[category]),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                        // Padding at bottom for floating unit
                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // Floating Search & Menu Bar (Visually hovering above View Cart)
        Positioned(
          left: 16,
          right: 16,
          bottom: 12, // Gap of 12px from whatever is below (View Cart or Tabs)
          child: Row(
            children: [
              Expanded(
                child: custom_search.SearchBar(maxWidth: double.infinity),
              ),
              const SizedBox(width: 12),
              _buildCallWaiterButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCallWaiterButton() {
    return InkWell(
      onTap: _callWaiter,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E), // Black background
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Waiter',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip('Filter', Icons.tune),
          _buildChip('Veg', null, isVeg: true),
          _buildChip('Non-Veg', null, isNonVeg: true),
          _buildChip('Bestseller', null),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData? icon, {bool isVeg = false, bool isNonVeg = false}) {
    final menuController = context.watch<app_controller.MenuController>();
    bool isActive = false;
    
    if (isVeg) isActive = menuController.isVegOnly;
    if (isNonVeg) isActive = menuController.isNonVegOnly;
    if (label == 'Bestseller') isActive = menuController.isBestsellerOnly; 
    if (label == 'Filter') isActive = menuController.activeFiltersCount > 0;

    return GestureDetector(
      onTap: () {
        HapticHelper.light();
        if (label == 'Filter') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useRootNavigator: false, // Ensures it opens relative to this context
            backgroundColor: Colors.transparent,
            builder: (context) => const FilterBottomSheet(),
          );
        } else if (isVeg) {
          menuController.toggleVegOnly();
        } else if (isNonVeg) {
          menuController.toggleNonVegOnly();
        } else if (label == 'Bestseller') {
          menuController.toggleBestsellerOnly();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.lightGreen : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == 'Filter' && menuController.activeFiltersCount > 0) ...[
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${menuController.activeFiltersCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (isVeg || isNonVeg) ...[
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(color: isVeg ? Colors.green : Colors.red, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Icon(Icons.fiber_manual_record, size: 8, color: isVeg ? Colors.green : Colors.red),
              ),
              const SizedBox(width: 8),
            ],
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppTheme.primaryText),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                color: AppTheme.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.outfit(
            color: AppTheme.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    // REQUIREMENT 3: Hide Bottom Navigation Bar and View Cart bar in Cart context
    if (_selectedIndex == 2) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Grounded "View Cart" Bar
        Consumer2<CartController, OrderController>(
          builder: (context, cart, orderController, child) {
            final hasCartItems = cart.items.isNotEmpty;
            final hasActiveOrders = orderController.activeOrders.isNotEmpty;

            if (!hasCartItems && !hasActiveOrders) return const SizedBox.shrink();

            // REQUIREMENT 5: Cart CTA State Logic
            // Default "View Cart", "Pay" if cart empty but orders pending
            final bool showPay = !hasCartItems && hasActiveOrders;
            final String ctaText = showPay ? 'Pay' : 'View Cart';
            
            final String amountText = showPay
                ? 'Total Bill: ₹${orderController.activeOrders.fold<double>(0, (sum, order) => sum + order.total).toStringAsFixed(2)}'
                : '${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'items'} • ₹${cart.totalAmount.toStringAsFixed(2)}';
            
            return GestureDetector(
              onTap: () {
                if (showPay) {
                  HapticHelper.medium();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(tenantId: widget.tenantId),
                    ),
                  );
                } else {
                  HapticHelper.light();
                  setState(() {
                    _selectedIndex = 2; // Switch to Cart tab
                  });
                }
              },
              child: Container(
                height: 48, // Slightly taller for better touch target
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      amountText,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          ctaText,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        // 1px Top Divider (Mandatory visual stack cut)
        Container(
          height: 1,
          color: const Color(0xFFE5E5EA),
        ),
        
        // Navigation Tab Bar
        BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.secondaryText,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
          ],
        ),
      ],
    );
  }
}
