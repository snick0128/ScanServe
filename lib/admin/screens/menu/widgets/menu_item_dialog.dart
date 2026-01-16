import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../models/tenant_model.dart';
import '../../../../models/inventory_item.dart';
import '../../../providers/inventory_provider.dart';

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
  final _scrollController = ScrollController();
  final _expansionTileKey = GlobalKey();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  
  String? _selectedCategoryId;
  String _itemType = 'veg';
  String? _imagePreviewUrl;
  bool _isManualAvailable = true;

  // Inventory Usage state
  late InventoryTrackingType _trackingType;
  late Map<String, double> _ingredients; // itemId -> qty

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name);
    _descController = TextEditingController(text: widget.item?.description);
    _priceController = TextEditingController(text: widget.item?.price.toString());
    _imageController = TextEditingController(text: widget.item?.imageUrl);
    _itemType = widget.item?.itemType ?? 'veg';
    _imagePreviewUrl = widget.item?.imageUrl;
    _isManualAvailable = widget.item?.isManualAvailable ?? true;

    _trackingType = widget.item?.inventoryTrackingType ?? InventoryTrackingType.none;
    _ingredients = Map.from(widget.item?.inventoryIngredients ?? {});

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
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToInventory() {
    Future.delayed(const Duration(milliseconds: 300), () {
      final context = _expansionTileKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _buildFormFields() {
    return Column(
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
          maxLines: 2,
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
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid price';
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                isExpanded: true,
                items: widget.categories.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
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
        const SizedBox(height: 24),
        const Text('Display Status', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatusOption(true, 'In Stock', Colors.blue),
            const SizedBox(width: 16),
            _buildStatusOption(false, 'Sold Out', Colors.orange),
          ],
        ),
        const SizedBox(height: 24),
        _buildInventorySection(),
      ],
    );
  }

  Widget _buildStatusOption(bool value, String label, Color color) {
    final isSelected = _isManualAvailable == value;
    return InkWell(
      onTap: () => setState(() => _isManualAvailable = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey[300]!, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.check_circle : Icons.radio_button_off, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? color : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection() {
    final inventoryItems = context.watch<InventoryProvider>().items;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: _expansionTileKey,
        title: const Text('Inventory Usage', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        subtitle: const Text('Link to stock and recipes (Optional)', style: TextStyle(fontSize: 12)),
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: _trackingType != InventoryTrackingType.none,
        onExpansionChanged: (expanded) {
          if (expanded) _scrollToInventory();
        },
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How should this item affect inventory?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildTrackingOption(
                  InventoryTrackingType.none, 
                  'Do Not Track', 
                  'No stock deduction (Default)',
                  Icons.block,
                ),
                _buildTrackingOption(
                  InventoryTrackingType.simple, 
                  'Simple Stock Item', 
                  'Link to 1 inventory item',
                  Icons.link,
                ),
                _buildTrackingOption(
                  InventoryTrackingType.recipe, 
                  'Uses Ingredients (Recipe)', 
                  'Deduct multiple ingredients',
                  Icons.layers,
                ),
                if (_trackingType == InventoryTrackingType.simple) ...[
                  const Divider(height: 32),
                  const Text('Link to Inventory Item:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildIngredientSelector(inventoryItems, isRecipe: false),
                ],
                if (_trackingType == InventoryTrackingType.recipe) ...[
                  const Divider(height: 32),
                  const Text('Add Ingredients:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildRecipeIngredients(inventoryItems),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingOption(InventoryTrackingType type, String title, String subtitle, IconData icon) {
    final isSelected = _trackingType == type;
    return RadioListTile<InventoryTrackingType>(
      value: type,
      groupValue: _trackingType,
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      secondary: Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 20),
      contentPadding: EdgeInsets.zero,
      onChanged: (val) {
        setState(() {
          _trackingType = val!;
          if (_trackingType == InventoryTrackingType.none) {
            _ingredients.clear();
          } else if (_trackingType == InventoryTrackingType.simple && _ingredients.length > 1) {
            // Keep only the first ingredient if switching from recipe
            final firstKey = _ingredients.keys.first;
            final firstVal = _ingredients[firstKey]!;
            _ingredients.clear();
            _ingredients[firstKey] = firstVal;
          }
        });
        if (_trackingType != InventoryTrackingType.none) {
          _scrollToInventory();
        }
      },
    );
  }

  Widget _buildIngredientSelector(List<InventoryItem> items, {required bool isRecipe}) {
    if (items.isEmpty) return const Text('No inventory items found. Add some in Inventory screen.');

    final currentId = _ingredients.keys.firstOrNull;
    
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: items.any((i) => i.id == currentId) ? currentId : null,
          decoration: const InputDecoration(
            labelText: 'Inventory Item',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          items: items.map((i) => DropdownMenuItem(value: i.id, child: Text('${i.name} (${i.unit})'))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _ingredients.clear();
                _ingredients[val] = 1.0;
              });
            }
          },
        ),
        if (currentId != null) ...[
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey(currentId),
            initialValue: _ingredients[currentId]?.toString(),
            decoration: InputDecoration(
              labelText: 'Quantity per sale',
              helperText: 'How many ${items.firstWhere((i) => i.id == currentId).unit} per serving?',
              border: const OutlineInputBorder(),
              suffixText: items.firstWhere((i) => i.id == currentId).unit,
              prefixIcon: const Icon(Icons.calculate_outlined),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) {
              final d = double.tryParse(val) ?? 0;
              if (d > 0) _ingredients[currentId!] = d;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRecipeIngredients(List<InventoryItem> items) {
    return Column(
      children: [
        ..._ingredients.entries.map((entry) {
          final item = items.firstWhere((i) => i.id == entry.key, orElse: () => InventoryItem(id: '', tenantId: '', name: 'Unknown', unit: '', currentStock: 0, lastUpdated: DateTime.now()));
          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), 
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: ListTile(
              title: Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text('${entry.value} ${item.unit} per sale', style: const TextStyle(fontSize: 11, color: Colors.blue)),
              trailing: IconButton(
                iconSize: 20, 
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent), 
                onPressed: () => setState(() => _ingredients.remove(entry.key)),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showAddIngredientDialog(items),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.withOpacity(0.3), style: BorderStyle.none),
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text('Add Ingredient to Recipe', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddIngredientDialog(List<InventoryItem> items) {
    if (items.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        String? selectedId;
        String inventoryUnit = '';
        String selectedUsageUnit = '';
        final qtyController = TextEditingController(text: '1');
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            List<String> availableUnits = [inventoryUnit];
            if (inventoryUnit == 'kg') availableUnits = ['kg', 'grams'];
            if (inventoryUnit == 'Liter') availableUnits = ['Liter', 'ml'];
            if (selectedUsageUnit.isEmpty && inventoryUnit.isNotEmpty) selectedUsageUnit = inventoryUnit;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add Recipe Ingredient'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    items: items
                        .where((i) => !_ingredients.containsKey(i.id))
                        .map((i) => DropdownMenuItem(
                              value: i.id,
                              child: Text('${i.name} (${i.unit})'),
                            ))
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Select Ingredient', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedId = val;
                        inventoryUnit = items.firstWhere((i) => i.id == val).unit;
                        selectedUsageUnit = inventoryUnit;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: qtyController,
                          decoration: const InputDecoration(
                            labelText: 'Qty', 
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: selectedUsageUnit.isEmpty ? null : selectedUsageUnit,
                          items: availableUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          onChanged: (val) => setDialogState(() => selectedUsageUnit = val!),
                        ),
                      ),
                    ],
                  ),
                  if (selectedId != null) ...[
                    const SizedBox(height: 8),
                    Builder(builder: (context) {
                      double qty = double.tryParse(qtyController.text) ?? 0;
                      double factor = 1.0;
                      if (selectedUsageUnit == 'grams' || selectedUsageUnit == 'ml') factor = 0.001;
                      double finalQty = qty * factor;
                      
                      return Text('Usage: $finalQty $inventoryUnit will be deducted from stock.', 
                        style: const TextStyle(fontSize: 11, color: Colors.blue, fontStyle: FontStyle.italic));
                    }),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (selectedId != null) {
                      double qty = double.tryParse(qtyController.text) ?? 1.0;
                      double factor = 1.0;
                      if (selectedUsageUnit == 'grams' || selectedUsageUnit == 'ml') factor = 0.001;
                      setState(() => _ingredients[selectedId!] = qty * factor);
                      Navigator.pop(context);
                    }
                  }, 
                  child: const Text('Add to Recipe'),
                ),
              ],
            );
          },
        );
      },
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
          border: Border.all(color: isSelected ? color : Colors.grey[300]!, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.circle, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? color : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        const Text('Image URL (Optional)', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _imageController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Ionicons.image_outline),
            hintText: 'https://...',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 160, width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
          child: _imagePreviewUrl != null && _imagePreviewUrl!.isNotEmpty
              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_imagePreviewUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 40)))
              : const Center(child: Icon(Icons.image_outlined, size: 40, color: Colors.grey)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEditing ? 'Edit Menu Item' : 'Add New Menu Item', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(height: 32),
              Flexible(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildFormFields()),
                      const SizedBox(width: 32),
                      Expanded(flex: 2, child: _buildImagePreview()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveItem,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
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
        stockCount: widget.item?.stockCount ?? 100,
        isTracked: widget.item?.isTracked ?? true,
        isManualAvailable: _isManualAvailable,
        inventoryTrackingType: _trackingType,
        inventoryIngredients: _ingredients,
      );
      Navigator.pop(context, {'item': newItem, 'categoryId': _selectedCategoryId});
    }
  }
}
