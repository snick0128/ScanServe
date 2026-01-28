import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tenant_model.dart'; // Make sure MenuItem is accessible

class CartItem {
  final MenuItem item;
  final Variant? selectedVariant;
  int quantity;
  String? note;

  CartItem({required this.item, this.selectedVariant, this.quantity = 1, this.note});

  double get totalPrice => (selectedVariant?.price ?? item.price) * quantity;

  Map<String, dynamic> toJson() => {
    'item': item.toMap(),
    'selectedVariant': selectedVariant?.toMap(),
    'quantity': quantity,
    'note': note,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      item: MenuItem.fromMap(json['item']),
      selectedVariant: json['selectedVariant'] != null 
          ? Variant.fromMap(json['selectedVariant']) 
          : null,
      quantity: json['quantity'],
      note: json['note'],
    );
  }
}

class CartController extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String? _storageKey;

  List<CartItem> get items => _items.values.toList();

  double get totalAmount =>
      _items.values.fold(0, (total, item) => total + item.totalPrice);

  int get itemCount =>
      _items.values.fold(0, (total, item) => total + item.quantity);

  // Initialize and load cart for specific session context
  Future<void> initialize(String tenantId, String? tableId) async {
    _storageKey = 'cart_${tenantId}_${tableId ?? 'parcel'}';
    await _loadCart();
  }

  Future<void> _loadCart() async {
    if (_storageKey == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartJson = prefs.getString(_storageKey!);
      
      if (cartJson != null) {
        final List<dynamic> decoded = jsonDecode(cartJson);
        _items.clear();
        for (var itemJson in decoded) {
          final cartItem = CartItem.fromJson(itemJson);
          final key = _generateKey(cartItem.item.id, cartItem.selectedVariant);
          _items[key] = cartItem;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
      // On error, start with empty cart
      _items.clear();
    }
  }

  Future<void> _saveCart() async {
    if (_storageKey == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_items.values.toList());
      await prefs.setString(_storageKey!, encoded);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  String _generateKey(String itemId, Variant? variant) {
    if (variant == null) return itemId;
    return '${itemId}_${variant.name}';
  }

  void addItem(MenuItem item, [Variant? variant]) {
    final key = _generateKey(item.id, variant);
    if (_items.containsKey(key)) {
      _items[key]!.quantity++;
    } else {
      _items[key] = CartItem(item: item, selectedVariant: variant);
    }
    _saveCart();
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.remove(itemId);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    if (_items.containsKey(itemId)) {
      if (quantity > 0) {
        _items[itemId]!.quantity = quantity;
      } else {
        _items.remove(itemId);
      }
      _saveCart();
      notifyListeners();
    }
  }

  void updateNote(String itemId, String? note) {
    if (_items.containsKey(itemId)) {
      _items[itemId]!.note = note;
      _saveCart();
      notifyListeners();
    }
  }

  bool isItemInCart(String itemId) => _items.values.any((i) => i.item.id == itemId);

  int getItemQuantity(String itemId) {
    return _items.values
        .where((i) => i.item.id == itemId)
        .fold(0, (sum, i) => sum + i.quantity);
  }

  void clear() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }
}
