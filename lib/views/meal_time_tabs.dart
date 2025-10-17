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
    _tabController = TabController(length: 3, vsync: this);
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
    if (_tabController.index !=
        ['Breakfast', 'Lunch', 'Dinner'].indexOf(selectedMealTime)) {
      _tabController.animateTo(
        ['Breakfast', 'Lunch', 'Dinner'].indexOf(selectedMealTime),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          final mealTime = ['Breakfast', 'Lunch', 'Dinner'][index];
          menuController.setMealTime(mealTime);
        },
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF914D),
              Color(0xFFFF6E40),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Breakfast'),
          Tab(text: 'Lunch'),
          Tab(text: 'Dinner'),
        ],
      ),
    );
  }
}
