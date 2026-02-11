import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/menu_controller.dart' as app_controller;
import '../controllers/cart_controller.dart';
import 'menu_item_card.dart';
import 'shimmer_loading.dart';
import 'package:scan_serve/utils/snackbar_helper.dart';
import 'package:scan_serve/utils/session_validator.dart';
import 'package:scan_serve/app.dart';
import 'package:scan_serve/config/app_config.dart';
import '../models/tenant_model.dart';

class MenuGrid extends StatelessWidget {
  final List<MenuItem>? items;
  final bool? isLoading;

  const MenuGrid({Key? key, this.items, this.isLoading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final menuController = context.watch<app_controller.MenuController>();
    final actualItems = items ?? menuController.filteredItems;
    final actualIsLoading = isLoading ?? menuController.isLoading;

    // Enhanced responsive breakpoints
    int crossAxisCount;
    double childAspectRatio;
    double crossAxisSpacing;
    double mainAxisSpacing;

    if (screenWidth < 480) {
      // Mobile - very small screens
      crossAxisCount = 2;
      childAspectRatio = 0.62; // Updated for 250px height
      crossAxisSpacing = 12;
      mainAxisSpacing = 16;
    } else if (screenWidth < 600) {
      // Mobile
      crossAxisCount = 2;
      childAspectRatio = 0.62; 
      crossAxisSpacing = 16;
      mainAxisSpacing = 16;
    } else if (screenWidth < 900) {
      // Tablet - portrait
      crossAxisCount = 3;
      childAspectRatio = 0.62; 
      crossAxisSpacing = 20;
      mainAxisSpacing = 20;
    } else if (screenWidth < 1200) {
      // Tablet - landscape
      crossAxisCount = 4;
      childAspectRatio = 0.62; 
      crossAxisSpacing = 24;
      mainAxisSpacing = 24;
    } else if (screenWidth < 1600) {
      // Desktop - medium
      crossAxisCount = 5;
      childAspectRatio = 0.62; 
      crossAxisSpacing = 28;
      mainAxisSpacing = 28;
    } else {
      // Desktop - large
      crossAxisCount = 6;
      childAspectRatio = 0.62; 
      crossAxisSpacing = 32;
      mainAxisSpacing = 32;
    }

    if (actualIsLoading) {
      return ShimmerLoading.buildShimmerGrid(
        itemCount: 8, // Show more shimmer items for better loading experience
        crossAxisCount: crossAxisCount,
        itemBuilder: (index) => ShimmerLoading.menuItemCard(
          isMobile: screenWidth < 600,
          isTablet: screenWidth >= 600 && screenWidth < 1200,
        ),
        isMobile: screenWidth < 600,
        isTablet: screenWidth >= 600 && screenWidth < 1200,
      );
    }

    if (actualItems.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E5EA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                menuController.isSearching
                    ? Icons.search_off
                    : Icons.restaurant_menu,
                size: 48,
                color: const Color(0xFF8E8E93),
              ),
              const SizedBox(height: 12),
              Text(
                menuController.isSearching
                    ? 'No search results found'
                    : 'No items found',
                style: TextStyle(
                  color: const Color(0xFF1C1C1E),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (menuController.isSearching)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Try searching with different keywords',
                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(
        0,
      ), // Remove grid padding since parent handles spacing
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: actualItems.length,
      shrinkWrap: true, // Add this to prevent layout issues
      physics:
          const NeverScrollableScrollPhysics(), // Add this to prevent nested scrolling issues
      itemBuilder: (context, index) {
        final item = actualItems[index];
        return MenuItemCard(
          item: item,
          onAddPressed: () async {
            try {
              context.read<CartController>().addItem(item);
              SnackbarHelper.showTopSnackBar(
                context,
                '${item.name} added to cart',
                duration: const Duration(seconds: 1),
              );
            } catch (e) {
              final cart = context.read<CartController>();
              final validation = SessionValidator.validateForCart(
                tenantId: cart.tenantId,
                tableId: cart.tableId,
                isParcelOrder: cart.isParcelOrder,
              );
              
              if (!validation.isValid) {
                SessionValidator.showValidationDialog(
                  context: context,
                  result: validation,
                  onScanQR: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => Initializer(config: AppConfig.init())),
                    (route) => false,
                  ),
                );
              } else {
                SnackbarHelper.showTopSnackBar(context, 'Error: $e');
              }
            }
          },
        );
      },
    );
  }
}
