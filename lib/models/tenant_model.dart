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

  bool get isVeg => itemType?.toLowerCase() == 'veg';

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.category,
    this.subcategory,
    String? itemType,
  }) {
    this.itemType = itemType;
  }

  factory MenuItem.fromMap(Map<String, dynamic> data) {
    final itemType = data['itemType'];
    print('🔍 MenuItem.fromMap - itemType: $itemType, data keys: ${data.keys.toList()}');

    return MenuItem(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['image_url'],
      category: data['category'] ?? data['Category'], // Try both cases
      subcategory: data['subcategory'] ?? data['Subcategory'], // Try both cases
      itemType: itemType, // veg or nonveg
    );
  }
}
