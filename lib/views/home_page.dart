import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/menu_controller.dart' as app_controller;
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../services/offline_service.dart';
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
  @override
  void initState() {
    super.initState();
    // Load menu items when the home content is initialized
    final menuController = context.read<app_controller.MenuController>();
    menuController.loadMenuItems(widget.tenantId);

    // Listen for offline status changes
    final offlineService = context.read<OfflineService>();
    offlineService.connectionStatus.listen((isOnline) {
      if (mounted) {
        if (isOnline) {
          offlineService.showOnlineSnackbar(context);
        } else {
          offlineService.showOfflineSnackbar(context);
        }
      }
    });
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
          'Menu',
          style: TextStyle(
            fontSize: screenWidth < 600 ? 20 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: appBarElevation,
        actions: [
          // Offline status indicator
          Consumer<OfflineService>(
            builder: (context, offlineService, child) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: offlineService.getOfflineStatusColor().withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: offlineService.getOfflineStatusColor().withAlpha(50),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      offlineService.isOnline ? Icons.wifi : Icons.wifi_off,
                      size: iconSize - 4,
                      color: offlineService.getOfflineStatusColor(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      offlineService.getOfflineStatusMessage(),
                      style: TextStyle(
                        fontSize: screenWidth < 600 ? 10 : 12,
                        fontWeight: FontWeight.bold,
                        color: offlineService.getOfflineStatusColor(),
                      ),
                    ),
                  ],
                ),
              );
            },
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
                child: custom_search.SearchBar(
                  maxWidth: searchBarMaxWidth,
                ),
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
        ],
      ),
    );
  }
}
