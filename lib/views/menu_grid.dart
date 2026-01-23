import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/menu_controller.dart' as app_controller;
import '../controllers/cart_controller.dart';
import 'menu_item_card.dart';
import 'shimmer_loading.dart';
import 'package:scan_serve/utils/snackbar_helper.dart';

class MenuGrid extends StatelessWidget {
  const MenuGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final menuController = context.watch<app_controller.MenuController>();
    final items = menuController.filteredItems;
    final isLoading = menuController.isLoading;

    // Enhanced responsive breakpoints
    int crossAxisCount;
    double childAspectRatio;
    double crossAxisSpacing;
    double mainAxisSpacing;

    if (screenWidth < 480) {
      // Mobile - very small screens
      crossAxisCount = 2;
      childAspectRatio = 0.66; // Updated for 250px height
      crossAxisSpacing = 12;
      mainAxisSpacing = 16;
    } else if (screenWidth < 600) {
      // Mobile
      crossAxisCount = 2;
      childAspectRatio = 0.66; 
      crossAxisSpacing = 16;
      mainAxisSpacing = 16;
    } else if (screenWidth < 900) {
      // Tablet - portrait
      crossAxisCount = 3;
      childAspectRatio = 0.66; 
      crossAxisSpacing = 20;
      mainAxisSpacing = 20;
    } else if (screenWidth < 1200) {
      // Tablet - landscape
      crossAxisCount = 4;
      childAspectRatio = 0.66; 
      crossAxisSpacing = 24;
      mainAxisSpacing = 24;
    } else if (screenWidth < 1600) {
      // Desktop - medium
      crossAxisCount = 5;
      childAspectRatio = 0.66; 
      crossAxisSpacing = 28;
      mainAxisSpacing = 28;
    } else {
      // Desktop - large
      crossAxisCount = 6;
      childAspectRatio = 0.66; 
      crossAxisSpacing = 32;
      mainAxisSpacing = 32;
    }

    if (isLoading) {
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

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
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
                color: Colors.grey[700],
              ),
              const SizedBox(height: 12),
              Text(
                menuController.isSearching
                    ? 'No search results found'
                    : 'No items found',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (menuController.isSearching)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Try searching with different keywords',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
      itemCount: items.length,
      shrinkWrap: true, // Add this to prevent layout issues
      physics:
          const NeverScrollableScrollPhysics(), // Add this to prevent nested scrolling issues
      itemBuilder: (context, index) {
        final item = items[index];
        return MenuItemCard(
          item: item,
          onAddPressed: () {
            context.read<CartController>().addItem(item);
            SnackbarHelper.showTopSnackBar(
              context,
              '${item.name} added to cart',
              duration: const Duration(seconds: 1),
            );
          },
        );
      },
    );
  }
}
