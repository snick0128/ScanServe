import 'package:cloud_firestore/cloud_firestore.dart';
import 'inventory_item.dart';
import 'table_status.dart';

class Tenant {
  final String id;
  final String name;
  final String description;
  final List<Category> categories;
  final bool isVegOnly;
  final Map<String, dynamic> settings;

  Tenant({
    required this.id,
    required this.name,
    required this.description,
    required this.categories,
    this.isVegOnly = false,
    this.settings = const {},
  });

  factory Tenant.fromFirestore(Map<String, dynamic> data, String id) {
    return Tenant(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      categories:
          (data['categories'] as List?)
              ?.map((category) => Category.fromMap(category))
              .toList() ??
          [],
      isVegOnly: data['isVegOnly'] ?? false,
      settings: data['settings'] ?? {},
    );
  }
}

class Category {
  final String id;
  final String name;
  final List<MenuItem> items;

  Category({required this.id, required this.name, required this.items});

  factory Category.fromMap(Map<String, dynamic> data) {
    return Category(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      items:
          (data['menu_items'] as List?)
              ?.map((item) => MenuItem.fromMap(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'menu_items': items.map((x) => x.toMap()).toList(),
    };
  }
}

enum InventoryTrackingType {
  none,
  simple,
  recipe
}

class Variant {
  final String name;
  final double price;
  final bool isAvailable;

  Variant({
    required this.name,
    required this.price,
    this.isAvailable = true,
  });

  factory Variant.fromMap(Map<String, dynamic> map) {
    return Variant(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'isAvailable': isAvailable,
    };
  }
}

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String? category; // Breakfast, Lunch, Dinner
  final String? subcategory; // Veg, Non-Veg, Beverages, etc.
  late final String? itemType; // veg or nonveg
  final int stockCount;
  final bool isTracked;
  
  // NEW: Inventory Linkage
  final InventoryTrackingType inventoryTrackingType;
  final Map<String, double> inventoryIngredients; // Map of itemId to quantity per sale

  final bool isBestseller;
  
  final bool hasVariants;
  final List<Variant> variants;
  
  bool get isVeg {
    if (itemType == null) return true; // Default to veg if not specified
    final type = itemType!.toLowerCase().replaceAll('-', '').replaceAll(' ', '').trim();
    return type != 'nonveg';
  }
  
  final bool isManualAvailable;
  
  bool get isOutOfStock => !isManualAvailable || (isTracked && stockCount <= 0);

  /// Checks if the item is available based on linked inventory
  bool isAvailable(List<InventoryItem> inventory) {
    // If manually marked out of stock, return false
    if (isOutOfStock) return false;
    
    // If not tracking inventory, it's available
    if (inventoryTrackingType == InventoryTrackingType.none) return true;

    // Check each linked ingredient
    for (var entry in inventoryIngredients.entries) {
      final itemId = entry.key;
      final qtyNeeded = entry.value;
      
      try {
        final invItem = inventory.firstWhere((i) => i.id == itemId);
        // If any key ingredient is completely out (or below needed qty), item is unavailable
        if (invItem.currentStock < qtyNeeded) return false;
      } catch (_) {
        // If a linked item is missing from inventory list, assume unavailable for safety
        return false;
      }
    }
    
    return true;
  }

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.category,
    this.subcategory,
    String? itemType,
    this.stockCount = 0,
    this.isTracked = false,
    this.isManualAvailable = true,
    this.inventoryTrackingType = InventoryTrackingType.none,
    this.inventoryIngredients = const {},
    this.isBestseller = false,
    this.hasVariants = false,
    this.variants = const [],
  }) {
    this.itemType = itemType;
  }

  factory MenuItem.fromMap(Map<String, dynamic> data) {
    final itemType = data['itemType'];
    
    InventoryTrackingType trackingType = InventoryTrackingType.none;
    if (data['inventoryTrackingType'] != null) {
      try {
        trackingType = InventoryTrackingType.values.firstWhere(
          (e) => e.name == data['inventoryTrackingType'],
        );
      } catch (_) {
        trackingType = InventoryTrackingType.none;
      }
    }

    final ingredientsData = data['inventoryIngredients'] as Map<String, dynamic>? ?? {};
    final Map<String, double> ingredients = {};
    ingredientsData.forEach((key, value) {
      ingredients[key] = (value as num).toDouble();
    });

    return MenuItem(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['image_url'],
      category: data['category'] ?? data['Category'],
      subcategory: data['subcategory'] ?? data['Subcategory'],
      itemType: itemType,
      stockCount: data['stockCount'] ?? 0,
      isTracked: data['isTracked'] ?? false,
      isManualAvailable: data['isManualAvailable'] ?? true,
      inventoryTrackingType: trackingType,
      inventoryIngredients: ingredients,
      isBestseller: data['isBestseller'] ?? false,
      hasVariants: data['hasVariants'] ?? false,
      variants: (data['variants'] as List<dynamic>?)
          ?.map((v) => Variant.fromMap(v))
          .toList() ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category': category,
      'subcategory': subcategory,
      'itemType': itemType,
      'stockCount': stockCount,
      'isTracked': isTracked,
      'isManualAvailable': isManualAvailable,
      'inventoryTrackingType': inventoryTrackingType.name,
      'inventoryIngredients': inventoryIngredients,
      'isBestseller': isBestseller,
      'hasVariants': hasVariants,
      'variants': variants.map((v) => v.toMap()).toList(),
    };
  }

  MenuItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    String? subcategory,
    String? itemType,
    int? stockCount,
    bool? isTracked,
    bool? isManualAvailable,
    InventoryTrackingType? inventoryTrackingType,
    Map<String, double>? inventoryIngredients,
    bool? isBestseller,
    bool? hasVariants,
    List<Variant>? variants,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      itemType: itemType ?? this.itemType,
      stockCount: stockCount ?? this.stockCount,
      isTracked: isTracked ?? this.isTracked,
      isManualAvailable: isManualAvailable ?? this.isManualAvailable,
      inventoryTrackingType: inventoryTrackingType ?? this.inventoryTrackingType,
      inventoryIngredients: inventoryIngredients ?? this.inventoryIngredients,
      isBestseller: isBestseller ?? this.isBestseller,
      hasVariants: hasVariants ?? this.hasVariants,
      variants: variants ?? this.variants,
    );
  }
}

class RestaurantTable {
  final String id;
  final String name;
  final int capacity;
  final bool isAvailable;
  final TableStatus status;
  final bool isOccupied;
  final String? currentSessionId;
  final DateTime? occupiedAt;
  final DateTime? lastReleasedAt; // For Bug #6 validation
  final String section; // 'AC', 'Non-AC', 'Garden', etc.
  final int orderIndex;

  RestaurantTable({
    required this.id,
    required this.name,
    required this.capacity,
    this.isAvailable = true,
    this.status = TableStatus.available,
    this.isOccupied = false,
    this.currentSessionId,
    this.occupiedAt,
    this.lastReleasedAt,
    this.section = 'General',
    this.orderIndex = 0,
  });

  factory RestaurantTable.fromMap(Map<String, dynamic> data, [String? docId]) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final status = TableStatus.fromString(data['status']);
    
    return RestaurantTable(
      id: data['id'] ?? docId ?? '',
      name: data['name'] ?? '',
      capacity: data['capacity'] ?? 4,
      isAvailable: data['isAvailable'] ?? status.canAcceptCustomers,
      status: status,
      isOccupied: data['isOccupied'] ?? status.hasActiveSession,
      currentSessionId: data['currentSessionId'],
      occupiedAt: parseDateTime(data['occupiedAt']),
      lastReleasedAt: parseDateTime(data['lastReleasedAt']),
      section: data['section'] ?? 'General',
      orderIndex: data['orderIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'isAvailable': isAvailable,
      'status': status.value,
      'isOccupied': isOccupied,
      'currentSessionId': currentSessionId,
      'occupiedAt': occupiedAt != null ? Timestamp.fromDate(occupiedAt!) : null,
      'lastReleasedAt': lastReleasedAt != null ? Timestamp.fromDate(lastReleasedAt!) : null,
      'section': section,
      'orderIndex': orderIndex,
    };
  }
  
  String getTimeOccupied() {
    if (occupiedAt == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(occupiedAt!);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ${difference.inMinutes % 60} min';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    }
  }

  RestaurantTable copyWith({
    String? id,
    String? name,
    int? capacity,
    bool? isAvailable,
    TableStatus? status,
    bool? isOccupied,
    String? currentSessionId,
    DateTime? occupiedAt,
    DateTime? lastReleasedAt,
    String? section,
    int? orderIndex,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      isAvailable: isAvailable ?? this.isAvailable,
      status: status ?? this.status,
      isOccupied: isOccupied ?? this.isOccupied,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      occupiedAt: occupiedAt ?? this.occupiedAt,
      lastReleasedAt: lastReleasedAt ?? this.lastReleasedAt,
      section: section ?? this.section,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
