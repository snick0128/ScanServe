import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:scan_serve/admin/theme/admin_theme.dart';
import 'package:scan_serve/admin/providers/menu_provider.dart';
import 'package:scan_serve/models/tenant_model.dart';

class CategoryManagementDialog extends StatelessWidget {
  const CategoryManagementDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxWidth = (size.width - 24).clamp(320.0, 700.0);
    final maxHeight = size.height * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manage Categories',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),
              Expanded(
                child: Consumer<MenuProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final categories = provider.categories;

                    if (categories.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Ionicons.grid_outline, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('No categories found', style: TextStyle(color: AdminTheme.secondaryText)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${category.items.length} items', style: const TextStyle(fontSize: 12, color: AdminTheme.secondaryText)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Ionicons.create_outline, size: 20, color: AdminTheme.secondaryText),
                                onPressed: () => _showCategoryInput(context, category),
                              ),
                              IconButton(
                                icon: const Icon(Ionicons.trash_outline, size: 20, color: AdminTheme.critical),
                                onPressed: () => _confirmDelete(context, category),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showCategoryInput(context, null),
                icon: const Icon(Ionicons.add_circle, color: Colors.white),
                label: const Text('Add New Category', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryInput(BuildContext context, Category? category) {
    final nameController = TextEditingController(text: category?.name);
    final isEditing = category != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Category' : 'New Category'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g. Starters',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final provider = context.read<MenuProvider>();
              try {
                if (isEditing) {
                   // Create updated category object - preserve items!
                   final updatedCategory = Category(
                     id: category.id,
                     name: nameController.text.trim(),
                     items: category.items, // Keep existing items
                   );
                   await provider.updateCategory(updatedCategory);
                } else {
                  // Create new category
                   final newCategory = Category(
                     id: nameController.text.trim().toLowerCase().replaceAll(' ', '_'), // Simple ID gen
                     name: nameController.text.trim(),
                     items: [],
                   );
                   await provider.addCategory(newCategory);
                }
                if (context.mounted) Navigator.pop(context); // Close input dialog
              } catch (e) {
                // Error handling
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    if (category.items.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete category with items. Please remove or move items first.'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await context.read<MenuProvider>().deleteCategory(category.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
