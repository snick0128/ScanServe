import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../theme/admin_theme.dart';
import '../../../../models/tenant_model.dart';
import '../../../../models/inventory_item.dart';
import '../../../providers/inventory_provider.dart';
import 'package:scan_serve/utils/screen_scale.dart';

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
  
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  
  String? _selectedCategoryId;
  String _itemType = 'veg';
  String? _imagePreviewUrl;
  bool _isManualAvailable = true;
  bool _isBestseller = false;
  bool _isSaving = false;

  // Inventory Usage state
  late InventoryTrackingType _trackingType;
  late Map<String, double> _ingredients; // itemId -> qty (ALWAYS in base units: kg, Liter, etc.)
  final Map<String, String> _displayUnits = {}; // itemId -> displayed unit in UI (grams, ml, etc.)

  // Variants state
  bool _hasVariants = false;
  List<Variant> _variants = [];
  final _variantNameController = TextEditingController();
  final _variantPriceController = TextEditingController();

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
    _isBestseller = widget.item?.isBestseller ?? false;

    _trackingType = widget.item?.inventoryTrackingType ?? InventoryTrackingType.none;
    _ingredients = Map.from(widget.item?.inventoryIngredients ?? {});
    _hasVariants = widget.item?.hasVariants ?? false;
    _variants = List.from(widget.item?.variants ?? []);

    // Initialize category
    if (widget.item != null) {
      for (var cat in widget.categories) {
        if (cat.items.any((i) => i.id == widget.item!.id)) {
          _selectedCategoryId = cat.id;
          break;
        }
      }
    } 
    
    // Safety check: if _selectedCategoryId is not in categories, reset it
    if (_selectedCategoryId != null && !widget.categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = null;
    }

    if (_selectedCategoryId == null && widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.id;
    }
    _imageController.addListener(() {
      setState(() {
        _imagePreviewUrl = _imageController.text.isNotEmpty ? _imageController.text : null;
      });
    });

    _initializeDisplayUnits();
  }

  void _initializeDisplayUnits() {
    final inventoryItems = context.read<InventoryProvider>().items;
    for (var entry in _ingredients.entries) {
      final item = inventoryItems.firstWhere((i) => i.id == entry.key, orElse: () => InventoryItem(id: '', tenantId: '', name: '', category: '', unit: '', currentStock: 0, lastUpdated: DateTime.now()));
      
      if (item.unit == 'kg' && entry.value < 1.0 && entry.value > 0) {
        _displayUnits[entry.key] = 'grams';
      } else if (item.unit == 'Liter' && entry.value < 1.0 && entry.value > 0) {
        _displayUnits[entry.key] = 'ml';
      } else {
        _displayUnits[entry.key] = item.unit;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _scrollController.dispose();
    _variantNameController.dispose();
    _variantPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 1100,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildStickyHeader(isEditing),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(40.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN: Primary Work
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGeneralInfoSection(),
                            SizedBox(height: 32.h),
                            _buildPricingAndCategorySection(),
                            SizedBox(height: 32.h),
                            _buildRecipeBuilderSection(),
                          ],
                        ),
                      ),
                      SizedBox(width: 48.w),
                      // RIGHT COLUMN: Meta & Controls
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageSection(),
                            SizedBox(height: 32.h),
                            _buildStatusSettingsSection(),
                            SizedBox(height: 32.h),
                            _buildPrepTimeSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader(bool isEditing) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: AdminTheme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Edit Menu Item' : 'Add New Menu Item',
                  style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
                ),
                Text(
                  isEditing ? 'Update details, price and ingredients' : 'Configure your new dish for the digital menu',
                  style: TextStyle(fontSize: 14.sp, color: AdminTheme.secondaryText),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              side: const BorderSide(color: AdminTheme.dividerColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text('Cancel', style: TextStyle(color: AdminTheme.secondaryText, fontWeight: FontWeight.bold, fontSize: 14.sp)),
          ),
          SizedBox(width: 16.w),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: _isSaving 
              ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(isEditing ? 'Save Changes' : 'Create Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfoSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AdminTheme.dividerColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('General Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g. Traditional Paneer Tikka',
                labelStyle: const TextStyle(fontSize: 14, color: AdminTheme.secondaryText),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                contentPadding: const EdgeInsets.all(20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.dividerColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.dividerColor)),
                prefixIcon: const Icon(Ionicons.restaurant_outline, color: AdminTheme.primaryColor),
              ),
              validator: (v) => v?.isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Describe ingredients, taste, or portion size...',
                alignLabelWithHint: true,
                labelStyle: const TextStyle(fontSize: 14, color: AdminTheme.secondaryText),
                contentPadding: const EdgeInsets.all(20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.dividerColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.dividerColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingAndCategorySection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AdminTheme.dividerColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pricing & Categorization', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: widget.categories.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null,
                    isExpanded: true, // Prevent overflow
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: const TextStyle(fontSize: 14, color: AdminTheme.secondaryText),
                      contentPadding: const EdgeInsets.all(20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.dividerColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.dividerColor)),
                    ),
                    items: widget.categories
                        .fold<List<Category>>([], (list, cat) => list.any((c) => c.id == cat.id) ? list : [...list, cat])
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Standard Price',
                      prefixText: '₹ ',
                      labelStyle: const TextStyle(fontSize: 14, color: AdminTheme.secondaryText),
                      contentPadding: const EdgeInsets.all(20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.dividerColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.dividerColor)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty == true ? 'Price required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildVariantsSection(),
            const SizedBox(height: 24),
            const Text('Diet Preference', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText)),
            const SizedBox(height: 12),
            _buildDietSegmentedControl(),
          ],
        ),
      ),
    );
  }

  Widget _buildDietSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildDietOption('veg', 'Vegetarian', Colors.green),
          _buildDietOption('nonveg', 'Non-Vegetarian', Colors.red),
        ],
      ),
    );
  }

  Widget _buildDietOption(String type, String label, Color color) {
    final isSelected = _itemType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _itemType = type),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDietDot(type == 'veg'),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AdminTheme.primaryText : AdminTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeBuilderSection() {
    final inventoryItems = context.watch<InventoryProvider>().items;
    
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AdminTheme.dividerColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recipe & Ingredients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AdminTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text('AUTO-DEDUCT STOCK ON SALE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.primaryColor)),
                    ),
                  ],
                ),
                _buildTrackingTypeToggle(),
              ],
            ),
            if (_trackingType != InventoryTrackingType.none) ...[
              const SizedBox(height: 32),
              _buildIngredientSearchBar(inventoryItems),
              const SizedBox(height: 24),
              _buildModernIngredientList(inventoryItems),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF1F3F4), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTrackingTab(InventoryTrackingType.none, 'None'),
          _buildTrackingTab(InventoryTrackingType.recipe, 'Recipe'),
        ],
      ),
    );
  }

  Widget _buildTrackingTab(InventoryTrackingType type, String label) {
    final isSelected = _trackingType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _trackingType = type;
          if (type == InventoryTrackingType.none) _ingredients.clear();
        });
        if (type == InventoryTrackingType.recipe) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? AdminTheme.primaryColor : AdminTheme.secondaryText)),
      ),
    );
  }

  Widget _buildIngredientSearchBar(List<InventoryItem> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: ValueKey('ingredient_search_${_ingredients.length}'),
          hint: const Text('Search or select ingredient...', style: TextStyle(fontSize: 14, color: AdminTheme.secondaryText)),
          isExpanded: true,
          value: null,
          icon: const Icon(Ionicons.search_outline, size: 20, color: AdminTheme.secondaryText),
          items: items
              .where((i) => !_ingredients.containsKey(i.id))
              .fold<List<InventoryItem>>([], (list, item) => list.any((i) => i.id == item.id) ? list : [...list, item])
              .map((i) => DropdownMenuItem(value: i.id, child: Text('${i.name} (${i.unit})')))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                final item = items.firstWhere((i) => i.id == val);
                _ingredients[val] = 1.0;
                _displayUnits[val] = item.unit; // Default to inventory base unit

                if (_trackingType == InventoryTrackingType.simple) {
                  final currentVal = _ingredients[val];
                  final currentUnit = _displayUnits[val];
                  _ingredients.clear();
                  _displayUnits.clear();
                  _ingredients[val] = currentVal!;
                  _displayUnits[val] = currentUnit!;
                }
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildModernIngredientList(List<InventoryItem> allItems) {
    if (_ingredients.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        ..._ingredients.entries.map((entry) {
          final item = allItems.firstWhere((i) => i.id == entry.key, orElse: () => InventoryItem(id: '', tenantId: '', name: 'Unknown', category: '', unit: 'unit', currentStock: 0, lastUpdated: DateTime.now()));
          
          final displayUnit = _displayUnits[entry.key] ?? item.unit;
          final isKg = item.unit == 'kg';
          final isLiter = item.unit == 'Liter';
          
          double factor = 1.0;
          if (displayUnit == 'grams' || displayUnit == 'ml') factor = 1000.0;
          
          final displayValue = (entry.value * factor);
          final displayValueStr = displayValue == displayValue.toInt() ? displayValue.toInt().toString() : displayValue.toStringAsFixed(2);

          List<String> availableUnits = [item.unit];
          if (isKg) availableUnits = ['kg', 'grams'];
          if (isLiter) availableUnits = ['Liter', 'ml'];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminTheme.dividerColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
                      Text('Stock: ${item.currentStock} ${item.unit} left', style: const TextStyle(fontSize: 11, color: AdminTheme.secondaryText)),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  child: TextFormField(
                    key: ValueKey('qty_${entry.key}_$displayUnit'),
                    initialValue: displayValueStr,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      isDense: true, 
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8), 
                      border: UnderlineInputBorder()
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      final parsed = double.tryParse(v) ?? 0.0;
                      setState(() {
                        _ingredients[entry.key] = parsed / factor;
                      });
                    },
                  ),
                ),
                DropdownButton<String>(
                  value: displayUnit,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 16),
                  style: const TextStyle(fontSize: 12, color: AdminTheme.primaryColor, fontWeight: FontWeight.bold),
                  items: availableUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (newUnit) {
                    if (newUnit != null) {
                      setState(() {
                        _displayUnits[entry.key] = newUnit;
                      });
                    }
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => setState(() {
                    _ingredients.remove(entry.key);
                    _displayUnits.remove(entry.key);
                  }),
                  icon: const Icon(Ionicons.trash_outline, color: AdminTheme.critical, size: 20),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AdminTheme.dividerColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Item Highlight Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
            const SizedBox(height: 24),
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdminTheme.dividerColor),
              ),
              child: Stack(
                children: [
                  _imagePreviewUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(_imagePreviewUrl!, width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Ionicons.cloud_upload_outline, size: 48, color: AdminTheme.secondaryText))),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Ionicons.image_outline, size: 48, color: AdminTheme.secondaryText),
                              const SizedBox(height: 12),
                              const Text('No Image Selected', style: TextStyle(color: AdminTheme.secondaryText, fontWeight: FontWeight.bold)),
                              Text('Click to set URL', style: TextStyle(fontSize: 12, color: AdminTheme.secondaryText.withOpacity(0.6))),
                            ],
                          ),
                        ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showImageURLDialog,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(),
                      ),
                    ),
                  ),
                  if (_imagePreviewUrl != null)
                    Positioned(
                      top: 12, right: 12,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 18,
                        child: IconButton(icon: const Icon(Ionicons.close, size: 16, color: AdminTheme.critical), onPressed: () => setState(() => _imagePreviewUrl = null)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Center(child: Text('Recommended size: 800x600px', style: TextStyle(fontSize: 11, color: AdminTheme.secondaryText))),
          ],
        ),
      ),
    );
  }

  void _showImageURLDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Image URL'),
        content: TextField(
          controller: _imageController,
          decoration: const InputDecoration(hintText: 'https://example.com/image.jpg', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { _imagePreviewUrl = _imageController.text; Navigator.pop(context); setState(() {}); }, child: const Text('Update')),
        ],
      ),
    );
  }

  Widget _buildStatusSettingsSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AdminTheme.dividerColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Availability & Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
            const SizedBox(height: 24),
            _buildSettingsToggle(
              'Active Visibility',
              'Show/Hide this item from the public digital menu.',
              _isManualAvailable,
              (v) => setState(() => _isManualAvailable = v),
            ),
            const SizedBox(height: 16),
            _buildSettingsToggle(
              'Mark as Bestseller',
              'Adds a special badge and boosts visibility.',
              _isBestseller,
              (v) => setState(() => _isBestseller = v),
            ),
            const SizedBox(height: 16),
            _buildSettingsToggle(
              'Out of Stock',
              'Maintain visibility but disable ordering.',
              !_isManualAvailable,
              (v) => setState(() => _isManualAvailable = !v),
              isDanger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsToggle(String title, String subtitle, bool value, Function(bool) onChanged, {bool isDanger = false}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AdminTheme.secondaryText)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: isDanger ? AdminTheme.critical : AdminTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildPrepTimeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.primaryColor.withOpacity(0.1)),
      ),
      child: const Row(
        children: [
          Icon(Ionicons.time_outline, color: AdminTheme.primaryColor, size: 24),
          SizedBox(width: 12),
          Expanded(child: Text('Avg. Preparation Time', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryColor, fontSize: 14))),
          Text('25 mins', style: TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.primaryColor, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDietDot(bool isVeg) {
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: isVeg ? Colors.green : Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: BoxDecoration(
          color: isVeg ? Colors.green : Colors.red,
          shape: isVeg ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }

  Widget _buildVariantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _hasVariants,
              onChanged: (val) => setState(() => _hasVariants = val ?? false),
              activeColor: AdminTheme.primaryColor,
            ),
            const Text('Has Variants / Portions', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        if (_hasVariants) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminTheme.dividerColor),
            ),
            child: Column(
              children: [
                // List of variants
                ..._variants.asMap().entries.map((entry) {
                  final index = entry.key;
                  final variant = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(variant.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                        Text('₹${variant.price}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Ionicons.close_circle, size: 20, color: AdminTheme.critical),
                          onPressed: () => setState(() => _variants.removeAt(index)),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                // Add new variant
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _variantNameController,
                        decoration: const InputDecoration(
                          hintText: 'Name (e.g. Half)',
                          isDense: true,
                          contentPadding: EdgeInsets.all(12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _variantPriceController,
                        decoration: const InputDecoration(
                          hintText: 'Price',
                          isDense: true,
                          contentPadding: EdgeInsets.all(12),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Ionicons.add_circle, color: AdminTheme.primaryColor, size: 28),
                      onPressed: () {
                        if (_variantNameController.text.isNotEmpty && _variantPriceController.text.isNotEmpty) {
                          setState(() {
                            _variants.add(Variant(
                              name: _variantNameController.text,
                              price: double.tryParse(_variantPriceController.text) ?? 0.0,
                            ));
                            _variantNameController.clear();
                            _variantPriceController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) return;
      
      setState(() => _isSaving = true);
      
      // Simulate network latency for UX satisfaction
      await Future.delayed(const Duration(milliseconds: 600));

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
        isBestseller: _isBestseller,
        inventoryTrackingType: _trackingType,
        inventoryIngredients: _ingredients,
        hasVariants: _hasVariants,
        variants: _variants,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newItem.name} saved successfully'),
            backgroundColor: AdminTheme.success,
            behavior: SnackBarBehavior.floating,
            width: 400,
          )
        );
        
        Navigator.pop(context, {'item': newItem, 'categoryId': _selectedCategoryId});
      }
    }
  }
}
