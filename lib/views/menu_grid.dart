import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/menu_controller.dart' as app_controller;
import '../controllers/cart_controller.dart';
import 'menu_item_card.dart';
import 'shimmer_loading.dart';

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
    EdgeInsets gridPadding;

    if (screenWidth < 480) {
      // Mobile - very small screens
      crossAxisCount = 1;
      childAspectRatio = 1.1;
      crossAxisSpacing = 8;
      mainAxisSpacing = 8;
      gridPadding = const EdgeInsets.all(8);
    } else if (screenWidth < 600) {
      // Mobile
      crossAxisCount = 1;
      childAspectRatio = 1.0;
      crossAxisSpacing = 12;
      mainAxisSpacing = 12;
      gridPadding = const EdgeInsets.all(12);
    } else if (screenWidth < 900) {
      // Tablet - portrait
      crossAxisCount = 2;
      childAspectRatio = 0.9;
      crossAxisSpacing = 16;
      mainAxisSpacing = 16;
      gridPadding = const EdgeInsets.all(16);
    } else if (screenWidth < 1200) {
      // Tablet - landscape
      crossAxisCount = 2;
      childAspectRatio = 0.85;
      crossAxisSpacing = 20;
      mainAxisSpacing = 20;
      gridPadding = const EdgeInsets.all(20);
    } else if (screenWidth < 1600) {
      // Desktop - medium
      crossAxisCount = 3;
      childAspectRatio = 0.8;
      crossAxisSpacing = 24;
      mainAxisSpacing = 24;
      gridPadding = const EdgeInsets.all(24);
    } else {
      // Desktop - large
      crossAxisCount = 4;
      childAspectRatio = 0.75;
      crossAxisSpacing = 28;
      mainAxisSpacing = 28;
      gridPadding = const EdgeInsets.all(28);
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

    return GridView.builder(
      padding: gridPadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MenuItemCard(
          item: item,
          onAddPressed: () {
            context.read<CartController>().addItem(item);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.name} added to cart'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(
                  bottom: 80,
                  left: screenWidth < 600 ? 16 : 24,
                  right: screenWidth < 600 ? 16 : 24,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
