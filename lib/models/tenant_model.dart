class Tenant {
  final String id;
  final String name;
  final String description;
  final List<Category> categories;
  final bool isVegOnly;

  Tenant({
    required this.id,
    required this.name,
    required this.description,
    required this.categories,
    this.isVegOnly = false,
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

  bool get isVeg => itemType?.toLowerCase() == 'veg';
  bool get isOutOfStock => isTracked && stockCount <= 0;

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
  }) {
    this.itemType = itemType;
  }

  factory MenuItem.fromMap(Map<String, dynamic> data) {
    final itemType = data['itemType'];
    // print(
    //   '🔍 MenuItem.fromMap - itemType: $itemType, data keys: ${data.keys.toList()}',
    // );

    return MenuItem(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['image_url'],
      category: data['category'] ?? data['Category'], // Try both cases
      subcategory: data['subcategory'] ?? data['Subcategory'], // Try both cases
      itemType: itemType, // veg or nonveg
      stockCount: data['stockCount'] ?? 0,
      isTracked: data['isTracked'] ?? false,
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
    };
  }
}

class RestaurantTable {
  final String id;
  final String name;
  final int capacity;
  final bool isAvailable;
  final String status; // 'available', 'occupied', 'billRequested'
  final DateTime? occupiedAt;

  RestaurantTable({
    required this.id,
    required this.name,
    required this.capacity,
    this.isAvailable = true,
    this.status = 'available',
    this.occupiedAt,
  });

  factory RestaurantTable.fromMap(Map<String, dynamic> data) {
    return RestaurantTable(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      capacity: data['capacity'] ?? 4,
      isAvailable: data['isAvailable'] ?? true,
      status: data['status'] ?? 'available',
      occupiedAt: data['occupiedAt'] != null 
        ? DateTime.parse(data['occupiedAt']) 
        : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'isAvailable': isAvailable,
      'status': status,
      'occupiedAt': occupiedAt?.toIso8601String(),
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
}
