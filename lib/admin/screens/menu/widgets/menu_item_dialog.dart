import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../models/tenant_model.dart';

class MenuItemDialog extends StatefulWidget {
  final MenuItem? item;
  final List<Category> categories;
  final String tenantId;

  const MenuItemDialog({
    super.key,
    this.item,
    required this.categories,
    required this.tenantId,
  });

  @override
  State<MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends State<MenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  
  String? _selectedCategoryId;
  String _itemType = 'veg';
  String? _imagePreviewUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name);
    _descController = TextEditingController(text: widget.item?.description);
    _priceController = TextEditingController(text: widget.item?.price.toString());
    _imageController = TextEditingController(text: widget.item?.imageUrl);
    _itemType = widget.item?.itemType ?? 'veg';
    _imagePreviewUrl = widget.item?.imageUrl;

    // Initialize category
    if (widget.item != null) {
      for (var cat in widget.categories) {
        if (cat.items.any((i) => i.id == widget.item!.id)) {
          _selectedCategoryId = cat.id;
          break;
        }
      }
    } else if (widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.id;
    }

    // Listen to image controller changes for preview
    _imageController.addListener(() {
      setState(() {
        _imagePreviewUrl = _imageController.text.isNotEmpty ? _imageController.text : null;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600, // Constrain width for larger screens
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Item' : 'Add New Item',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Ionicons.close_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Form Fields
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Item Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Ionicons.restaurant_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter item name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Ionicons.document_text_outline),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Price',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Ionicons.cash_outline),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Invalid price';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCategoryId,
                                    decoration: const InputDecoration(
                                      labelText: 'Category',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    ),
                                    items: widget.categories.map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    )).toList(),
                                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                                    validator: (value) => value == null ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('Item Type', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildTypeOption('veg', 'Veg', Colors.green),
                                const SizedBox(width: 16),
                                _buildTypeOption('nonveg', 'Non-Veg', Colors.red),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _imageController,
                              decoration: const InputDecoration(
                                labelText: 'Image URL',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Ionicons.image_outline),
                                hintText: 'https://example.com/image.jpg',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      
                      // Right Column: Image Preview
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            const Text('Preview', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _imagePreviewUrl != null && _imagePreviewUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _imagePreviewUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Ionicons.alert_circle_outline, size: 48, color: Colors.grey[400]),
                                            const SizedBox(height: 8),
                                            Text('Invalid URL', style: TextStyle(color: Colors.grey[500])),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Ionicons.image_outline, size: 48, color: Colors.grey[400]),
                                        const SizedBox(height: 8),
                                        Text('No Image', style: TextStyle(color: Colors.grey[500])),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveItem,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: Text(isEditing ? 'Save Changes' : 'Create Item'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(String value, String label, Color color) {
    final isSelected = _itemType == value;
    return InkWell(
      onTap: () => setState(() => _itemType = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.circle,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) return;

      final newItem = MenuItem(
        id: widget.item?.id ?? const Uuid().v4(),
        name: _nameController.text,
        description: _descController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        imageUrl: _imageController.text.isEmpty ? null : _imageController.text,
        itemType: _itemType,
        category: widget.categories.firstWhere((c) => c.id == _selectedCategoryId).name,
        subcategory: _itemType == 'veg' ? 'Veg' : 'Non-Veg',
        stockCount: widget.item?.stockCount ?? 10,
        isTracked: widget.item?.isTracked ?? true,
      );

      Navigator.pop(context, {
        'item': newItem,
        'categoryId': _selectedCategoryId,
      });
    }
  }
}
