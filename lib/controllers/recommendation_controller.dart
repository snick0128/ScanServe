import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tenant_model.dart';
import '../models/order_details.dart';
import 'cart_controller.dart';
import 'menu_controller.dart' as app_controller;
import 'order_controller.dart';

class RecommendationController extends ChangeNotifier {
  final CartController cartController;
  final app_controller.MenuController menuController;
  final OrderController orderController;
  
  Timer? _rotiReminderTimer;
  bool _rotiReminderTriggered = false;
  String? _lastRotiOrderId;

  RecommendationController({
    required this.cartController,
    required this.menuController,
    required this.orderController,
  }) {
    // Listen for order updates for time-based suggestions
    orderController.addListener(_checkRotiReminder);
  }

  void _checkRotiReminder() {
    final lastRoti = lastOrderedRotiInfo;
    if (lastRoti == null) return;

    // Feature 4: Time-based reorder suggestion (8-10 mins)
    // We only trigger if not already triggered for this specific item/time
    final rotiOrderId = 'roti_${lastRoti.orderId}_${lastRoti.item.id}';
    if (_lastRotiOrderId == rotiOrderId && _rotiReminderTriggered) return;

    _lastRotiOrderId = rotiOrderId;
    _rotiReminderTriggered = false;
    _setupRotiTimer(lastRoti.timestamp);
  }

  void _setupRotiTimer(DateTime orderTimestamp) {
    _rotiReminderTimer?.cancel();
    
    final now = DateTime.now();
    final diff = now.difference(orderTimestamp);
    
    // We want to trigger when diff is between 8 and 10 mins
    // If it's already > 10 mins, skip.
    // If it's < 8 mins, set timer for the 8th min.
    if (diff.inMinutes >= 8 && diff.inMinutes <= 10) {
      _triggerRotiPopup();
    } else if (diff.inMinutes < 8) {
      final waitDuration = Duration(minutes: 8) - diff;
      _rotiReminderTimer = Timer(waitDuration, () {
        _triggerRotiPopup();
      });
    }
  }

  void _triggerRotiPopup() {
    if (_rotiReminderTriggered) return;
    _rotiReminderTriggered = true;
    notifyListeners();
  }

  void dismissRotiReminder() {
    _rotiReminderTriggered = false;
    notifyListeners();
  }

  bool get shouldShowRotiPopup => _rotiReminderTriggered;

  MenuItem? get rotiItemToSuggest {
    final info = lastOrderedRotiInfo;
    if (info == null) return null;
    
    final id = info.item.id;
    try {
      return menuController.items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  // Feature 1 & 4 helper: Get last ordered roti item info
  ({OrderItem item, String orderId, DateTime timestamp})? get lastOrderedRotiInfo {
    // Combine active and past orders for search
    final allOrders = [
      ...orderController.activeOrders,
      ...orderController.pastOrders,
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (allOrders.isEmpty) return null;

    for (var order in allOrders) {
      for (var item in order.items) {
        if (_isRoti(item.name)) {
          return (item: item, orderId: order.orderId, timestamp: order.timestamp);
        }
      }
    }
    return null;
  }

  MenuItem? get rotiItemFromCart {
    for (final cartItem in cartController.items) {
      if (_isRoti(cartItem.item.name)) return cartItem.item;
    }
    return null;
  }

  bool _isRoti(String name) {
    final n = name.toLowerCase();
    return n.contains('roti') || n.contains('naan') || n.contains('bread') || n.contains('chapati');
  }

  // Feature 2: Often ordered with
  List<MenuItem> getSuggestionsForItemsInCart() {
    final cartItemIds = cartController.items.map((i) => i.item.id).toSet();
    final suggestedIds = <String>{};
    
    for (var cartItem in cartController.items) {
      suggestedIds.addAll(cartItem.item.suggestedItemIds);
    }
    
    // Also check item details for Feature 2 requirement "When a user opens or adds a menu item"
    // We can just base it on cart content for now as it's the "Cart Area" focus
    
    suggestedIds.removeWhere((id) => cartItemIds.contains(id));
    
    return menuController.items
        .where((item) => suggestedIds.contains(item.id))
        .take(4)
        .toList();
  }

  List<MenuItem> getFallbackSuggestionsForItemsInCart() {
    final cartItems = cartController.items;
    if (cartItems.isEmpty) return [];

    final cartItemIds = cartItems.map((i) => i.item.id).toSet();
    final cartCategories = cartItems
        .map((i) => i.item.category?.toLowerCase().trim())
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet();

    final candidates = menuController.items.where((item) {
      if (cartItemIds.contains(item.id)) return false;
      final cat = item.category?.toLowerCase().trim() ?? '';
      return cat.isNotEmpty && cartCategories.contains(cat);
    }).toList();

    if (candidates.isEmpty) return [];

    candidates.sort((a, b) {
      if (a.isBestseller != b.isBestseller) {
        return a.isBestseller ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });

    return candidates.take(4).toList();
  }

  // Feature 3: Meal Completion
  List<MenuItem> getMealCompletionSuggestions() {
    final items = cartController.items;
    if (items.isEmpty) return [];

    bool hasMainCourse = items.any((i) {
      final cat = i.item.category?.toLowerCase().trim() ?? '';
      return cat == 'main course' || (cat.contains('main') && cat.contains('course'));
    });
    bool hasBreadOrRice = items.any((i) => 
      _isRoti(i.item.name) || 
      i.item.name.toLowerCase().contains('rice') ||
      i.item.category?.toLowerCase() == 'rice' ||
      i.item.category?.toLowerCase() == 'bread'
    );

    if (hasMainCourse && !hasBreadOrRice) {
      // Suggest common rotis or rice
      return menuController.items.where((item) => 
        _isRoti(item.name) || 
        item.name.toLowerCase().contains('jeera rice') ||
        item.name.toLowerCase().contains('steamed rice')
      ).take(3).toList();
    }
    return [];
  }

  // Feature 5: Drinks
  List<MenuItem> getDrinkSuggestions() {
    bool hasSpicy = cartController.items.any((i) => i.item.spicy);
    if (hasSpicy) {
      return menuController.items.where((item) => 
        item.category?.toLowerCase() == 'beverages' || 
        item.category?.toLowerCase() == 'drinks' ||
        item.name.toLowerCase().contains('lassi') ||
        item.name.toLowerCase().contains('cold drink') ||
        item.name.toLowerCase().contains('lemonade')
      ).take(3).toList();
    }
    return [];
  }

  // Feature 6: Desserts
  List<MenuItem> getDessertSuggestions() {
    final total = cartController.totalAmount;
    bool hasDessert = cartController.items.any((i) => 
      i.item.category?.toLowerCase() == 'dessert' ||
      i.item.category?.toLowerCase() == 'desserts'
    );

    if (total > 400 && !hasDessert) {
      return menuController.items.where((item) => 
        item.category?.toLowerCase() == 'dessert' ||
        item.category?.toLowerCase() == 'desserts' ||
        item.name.toLowerCase().contains('ice cream') ||
        item.name.toLowerCase().contains('gulab jamun') ||
        item.name.toLowerCase().contains('brownie')
      ).take(3).toList();
    }
    return [];
  }

  // Feature 1: 1 More Roti tap handler
  void repeatLastRoti() {
    final info = lastOrderedRotiInfo;
    if (info == null) return;
    
    try {
      final menuItem = menuController.items.firstWhere((i) => i.id == info.item.id);
      cartController.addItem(menuItem, null, true);
    } catch (_) {}
  }

  @override
  void dispose() {
    orderController.removeListener(_checkRotiReminder);
    _rotiReminderTimer?.cancel();
    super.dispose();
  }
}
