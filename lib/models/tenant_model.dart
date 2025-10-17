class Tenant {
  final String id;
  final String name;
  final String description;
  final List<Category> categories;

  Tenant({
    required this.id,
    required this.name,
    required this.description,
    required this.categories,
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

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
  });

  factory MenuItem.fromMap(Map<String, dynamic> data) {
    return MenuItem(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['image_url'],
    );
  }
}
