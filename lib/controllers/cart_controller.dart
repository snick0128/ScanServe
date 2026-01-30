import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tenant_model.dart'; // Make sure MenuItem is accessible
import '../utils/session_validator.dart';
import '../utils/order_confirmation_tracker.dart';

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
  String? _tenantId;
  String? _tableId;
  bool _isParcelOrder = false;

  List<CartItem> get items => _items.values.toList();

  double get totalAmount =>
      _items.values.fold(0, (total, item) => total + item.totalPrice);

  int get itemCount =>
      _items.values.fold(0, (total, item) => total + item.quantity);

  // Session getters
  String? get tenantId => _tenantId;
  String? get tableId => _tableId;
  bool get isParcelOrder => _isParcelOrder;
  bool get hasValidSession => _tenantId != null && (_isParcelOrder || _tableId != null);

  // Initialize and load cart for specific session context
  Future<void> initialize(String tenantId, String? tableId, {bool isParcel = false}) async {
    _tenantId = tenantId;
    _tableId = tableId;
    _isParcelOrder = isParcel;
    _storageKey = 'cart_${tenantId}_${tableId ?? 'parcel'}';
    
    // CRITICAL: Check if order was confirmed (prevents duplicate orders on refresh)
    final shouldClear = await OrderConfirmationTracker.shouldClearCart(
      tenantId: tenantId,
      tableId: tableId,
    );
    
    if (shouldClear) {
      print('🔄 Order was confirmed - clearing cart to prevent duplicates');
      _items.clear();
      await _saveCart(); // Persist the empty cart
    } else {
      await _loadCart();
    }
    
    // Cleanup old confirmations periodically
    OrderConfirmationTracker.cleanupOldConfirmations();
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
    // CRITICAL: Validate session before adding items
    final validation = SessionValidator.validateForCart(
      tenantId: _tenantId,
      tableId: _tableId,
      isParcelOrder: _isParcelOrder,
    );

    if (!validation.isValid) {
      throw Exception(validation.errorMessage ?? 'Invalid session');
    }

    final key = _generateKey(item.id, variant);
    if (_items.containsKey(key)) {
      _items[key]!.quantity++;
    } else {
      _items[key] = CartItem(item: item, selectedVariant: variant);
    }
    _saveCart();
    notifyListeners();
  }

  void removeItem(String cartKey) {
    _items.remove(cartKey);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String cartKey, int quantity) {
    if (_items.containsKey(cartKey)) {
      if (quantity > 0) {
        _items[cartKey]!.quantity = quantity;
      } else {
        _items.remove(cartKey);
      }
      _saveCart();
      notifyListeners();
    }
  }

  void updateNote(String cartKey, String? note) {
    if (_items.containsKey(cartKey)) {
      _items[cartKey]!.note = note;
      _saveCart();
      notifyListeners();
    }
  }

  bool isItemInCart(String itemId) => _items.values.any((i) => i.item.id == itemId);

  int getItemQuantity(String itemId) {
    // Return total quantity of an item (sum of all variants)
    return _items.values
        .where((i) => i.item.id == itemId)
        .fold(0, (sum, i) => sum + i.quantity);
  }

  String getCartKey(String itemId, [Variant? variant]) {
    return _generateKey(itemId, variant);
  }

  void clear() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }
}
