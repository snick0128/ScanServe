import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/menu_controller.dart' as app_controller;

class MealTimeTabs extends StatefulWidget {
  const MealTimeTabs({Key? key}) : super(key: key);

  @override
  State<MealTimeTabs> createState() => _MealTimeTabsState();
}

class _MealTimeTabsState extends State<MealTimeTabs>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 0,
    ); // Changed from 3 to 2 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuController = context.watch<app_controller.MenuController>();
    final selectedMealTime = menuController.selectedMealTime;

    // Update tab controller when selected meal time changes
    final currentIndex = _tabController.index;
    final mealTimes = ['Breakfast', 'Meals']; // Changed from 3 to 2 meal times
    final targetIndex = selectedMealTime.isEmpty
        ? 0
        : mealTimes.indexOf(selectedMealTime);

    if (currentIndex != targetIndex && targetIndex >= 0) {
      _tabController.animateTo(targetIndex);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: TabBar(
        controller: _tabController,
        dividerHeight: 0, // Remove the divider height
        dividerColor: Colors.transparent, // Make the divider transparent
        onTap: (index) {
          final mealTime = [
            'Breakfast',
            'Meals',
          ][index]; // Changed from 3 to 2 meal times
          print('🍽️ TAB TAPPED: Switching to "$mealTime" (index: $index)');
          menuController.setMealTime(mealTime);
        },
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF914D), Color(0xFFFF6E40)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Breakfast'),
          Tab(
            text: 'Meals',
          ), // Changed from 'Lunch' and 'Dinner' to just 'Meals'
        ],
      ),
    );
  }
}
