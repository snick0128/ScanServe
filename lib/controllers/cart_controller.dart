import 'package:flutter/material.dart';
import '../models/tenant_model.dart';

class CartItem {
  final MenuItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  double get totalPrice => item.price * quantity;
}

class CartController extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  double get totalAmount =>
      _items.values.fold(0, (total, item) => total + item.totalPrice);

  int get itemCount =>
      _items.values.fold(0, (total, item) => total + item.quantity);

  void addItem(MenuItem item) {
    if (_items.containsKey(item.id)) {
      _items[item.id]!.quantity++;
    } else {
      _items[item.id] = CartItem(item: item);
    }
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.remove(itemId);
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    if (_items.containsKey(itemId)) {
      if (quantity > 0) {
        _items[itemId]!.quantity = quantity;
      } else {
        _items.remove(itemId);
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
