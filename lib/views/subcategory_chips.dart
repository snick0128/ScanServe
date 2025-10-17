import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/menu_controller.dart' as app_controller;

class SubcategoryChips extends StatelessWidget {
  const SubcategoryChips({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final menuController = context.watch<app_controller.MenuController>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: menuController.selectedSubcategory == null,
            onSelected: (_) => menuController.setSubcategory(null),
          ),
          const SizedBox(width: 8),
          // Add dynamic subcategories here based on your data
          ...['Starters', 'Main Course', 'Desserts'].map((subcategory) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(subcategory),
                selected: menuController.selectedSubcategory == subcategory,
                onSelected: (_) => menuController.setSubcategory(subcategory),
              ),
            );
          }),
        ],
      ),
    );
  }
}
