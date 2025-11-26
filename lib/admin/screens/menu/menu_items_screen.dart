import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/tenant_model.dart';
import '../../../services/menu_service.dart';

class MenuItemsScreen extends StatefulWidget {
  final String tenantId;

  const MenuItemsScreen({super.key, required this.tenantId});

  @override
  State<MenuItemsScreen> createState() => _MenuItemsScreenState();
}

class _MenuItemsScreenState extends State<MenuItemsScreen> {
  final MenuService _menuService = MenuService();
  List<MenuItem> _items = [];
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final items = await _menuService.getMenuItems(widget.tenantId);
      final categories = await _menuService.getCategories(widget.tenantId);
      setState(() {
        _items = items;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading menu: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showEditDialog([MenuItem? item]) async {
    final isEditing = item != null;
    final nameController = TextEditingController(text: item?.name);
    final descController = TextEditingController(text: item?.description);
    final priceController = TextEditingController(text: item?.price.toString());
    final imageController = TextEditingController(text: item?.imageUrl);
    
    // Find initial category ID
    String? selectedCategoryId;
    if (isEditing) {
      for (var cat in _categories) {
        if (cat.items.any((i) => i.id == item.id)) {
          selectedCategoryId = cat.id;
          break;
        }
      }
    } else if (_categories.isNotEmpty) {
      selectedCategoryId = _categories.first.id;
    }

    String itemType = item?.itemType ?? 'veg';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Item' : 'Add Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  )).toList(),
                  onChanged: (val) => setState(() => selectedCategoryId = val),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Type: '),
                    Radio<String>(
                      value: 'veg',
                      groupValue: itemType,
                      onChanged: (val) => setState(() => itemType = val!),
                    ),
                    const Text('Veg'),
                    Radio<String>(
                      value: 'nonveg',
                      groupValue: itemType,
                      onChanged: (val) => setState(() => itemType = val!),
                    ),
                    const Text('Non-Veg'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCategoryId == null) return;
                
                final newItem = MenuItem(
                  id: item?.id ?? const Uuid().v4(),
                  name: nameController.text,
                  description: descController.text,
                  price: double.tryParse(priceController.text) ?? 0.0,
                  imageUrl: imageController.text.isEmpty ? null : imageController.text,
                  itemType: itemType,
                  category: _categories.firstWhere((c) => c.id == selectedCategoryId).name,
                  subcategory: itemType == 'veg' ? 'Veg' : 'Non-Veg', // Simplified logic
                  stockCount: item?.stockCount ?? 0,
                  isTracked: item?.isTracked ?? false,
                );

                try {
                  if (isEditing) {
                    await _menuService.updateMenuItem(widget.tenantId, selectedCategoryId!, newItem);
                  } else {
                    await _menuService.addMenuItem(widget.tenantId, selectedCategoryId!, newItem);
                  }
                  if (mounted) Navigator.pop(context);
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving item: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(MenuItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Find category ID
        String? categoryId;
        for (var cat in _categories) {
          if (cat.items.any((i) => i.id == item.id)) {
            categoryId = cat.id;
            break;
          }
        }

        if (categoryId != null) {
          await _menuService.deleteMenuItem(widget.tenantId, categoryId, item.id);
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting item: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  child: ListTile(
                    leading: item.imageUrl != null
                        ? CircleAvatar(backgroundImage: NetworkImage(item.imageUrl!))
                        : const CircleAvatar(child: Icon(Icons.fastfood)),
                    title: Text(item.name),
                    subtitle: Text('₹${item.price} • ${item.category}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditDialog(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteItem(item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
