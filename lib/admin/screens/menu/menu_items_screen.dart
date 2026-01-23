import 'package:flutter/material.dart' hide Category;
import 'package:provider/provider.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../../../models/tenant_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../theme/admin_theme.dart';
import 'widgets/menu_item_dialog.dart';

class MenuItemsScreen extends StatefulWidget {
  final String tenantId;
  const MenuItemsScreen({super.key, required this.tenantId});

  @override
  State<MenuItemsScreen> createState() => _MenuItemsScreenState();
}

class _MenuItemsScreenState extends State<MenuItemsScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _exportCsv(BuildContext context, List<MenuItem> items) {
    final header = 'ID,Name,Category,Subcategory,Price,Type,Bestseller,Manual Availability,Stock Count\n';
    final rows = items.map((i) => 
      '${i.id},"${i.name}","${i.category ?? ''}","${i.subcategory ?? ''}",${i.price},${i.itemType},${i.isBestseller},${i.isManualAvailable},${i.stockCount}'
    ).join('\n');
    final csvContent = header + rows;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export CSV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Copy the CSV data below:'),
            const SizedBox(height: 8),
            Container(
              height: 300,
              width: 500,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  csvContent, 
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<MenuProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider),
              _buildFiltersBar(provider),
              Expanded(
                child: provider.isLoading 
                    ? const Center(child: CircularProgressIndicator(color: AdminTheme.primaryColor))
                    : _buildMenuTable(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(MenuProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Menu Management',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your restaurant’s digital menu items, categories, and availability.',
                style: const TextStyle(color: AdminTheme.secondaryText, fontSize: 16),
              ),
            ],
          ),
          Row(
            children: [
              _buildActionCircle(Ionicons.download_outline, 'Export CSV', () => _exportCsv(context, provider.allItems)),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showEditDialog(null, provider),
                icon: const Icon(Ionicons.add_outline, size: 20),
                label: const Text('Add New Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminTheme.primaryText,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        side: BorderSide(color: Colors.grey[200]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildFiltersBar(MenuProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => provider.setSearchQuery(v),
                    decoration: const InputDecoration(
                      hintText: 'Search by item name or category...',
                      prefixIcon: Icon(Ionicons.search_outline, size: 18, color: AdminTheme.secondaryText),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildFilterCategoryDropdown(provider),
              const SizedBox(width: 12),
              _buildDietFilter(provider),
              const SizedBox(width: 12),
              _buildBestsellerToggle(provider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCategoryDropdown(MenuProvider provider) {
    final categories = ['All Items', ...provider.categories.map((c) => c.name)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.selectedCategory,
          onChanged: (v) => provider.setCategoryFilter(v!),
          items: categories
              .toSet()
              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14))))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDietFilter(MenuProvider provider) {
    final types = ['All', 'Veg', 'Non-Veg'];
    return Row(
      children: types.map((t) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(t),
          selected: provider.selectedType == t,
          onSelected: (val) => provider.setTypeFilter(t),
          selectedColor: AdminTheme.primaryColor,
          labelStyle: TextStyle(
            color: provider.selectedType == t ? Colors.white : AdminTheme.secondaryText,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: Colors.white,
          side: BorderSide(color: provider.selectedType == t ? AdminTheme.primaryColor : Colors.grey[200]!),
          showCheckmark: false,
        ),
      )).toList(),
    );
  }

  Widget _buildBestsellerToggle(MenuProvider provider) {
    return FilterChip(
      label: const Text('Bestsellers Only'),
      selected: provider.isBestsellerOnly,
      onSelected: (val) => provider.toggleBestsellerFilter(),
      selectedColor: AdminTheme.primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: provider.isBestsellerOnly ? AdminTheme.primaryColor : AdminTheme.secondaryText,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: provider.isBestsellerOnly ? AdminTheme.primaryColor : Colors.grey[200]!),
      avatar: Icon(Ionicons.star, size: 14, color: provider.isBestsellerOnly ? AdminTheme.primaryColor : AdminTheme.secondaryText),
    );
  }

  Widget _buildMenuTable(MenuProvider provider) {
    final items = provider.filteredItems;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.restaurant_outline, size: 64, color: Colors.grey[200]),
            const SizedBox(height: 16),
            const Text('No menu items match your search', style: TextStyle(color: AdminTheme.secondaryText)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Table Header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: const Row(
            children: [
              SizedBox(width: 60, child: Text('IMAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 0.5))),
              Expanded(flex: 3, child: Text('ITEM NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 0.5))),
              Expanded(flex: 2, child: Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 0.5))),
              Expanded(flex: 1, child: Text('PRICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 0.5))),
              Expanded(flex: 1, child: Text('DIET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 0.5))),
              Expanded(flex: 1, child: Text('BESTSELLER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 0.5))),
              Expanded(flex: 1, child: Text('ACTIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 0.5))),
              SizedBox(width: 80, child: Text('ACTIONS', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 0.5))),
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
            itemBuilder: (context, index) {
              final item = items[index];
              return _MenuItemRow(item: item, provider: provider);
            },
          ),
        ),
      ],
    );
  }

  void _showEditDialog(MenuItem? item, MenuProvider provider) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => MenuItemDialog(
        item: item,
        categories: provider.categories,
        tenantId: widget.tenantId,
      ),
    );

    if (result != null) {
      final newItem = result['item'] as MenuItem;
      final categoryId = result['categoryId'] as String;
      
      try {
        if (item != null) {
          await provider.updateMenuItem(categoryId, newItem);
        } else {
          await provider.addMenuItem(categoryId, newItem);
        }
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(item != null ? 'Item updated successfully' : 'Item added successfully'), backgroundColor: AdminTheme.success),
          );
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

class _MenuItemRow extends StatelessWidget {
  final MenuItem item;
  final MenuProvider provider;

  const _MenuItemRow({required this.item, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          // Image
          SizedBox(
            width: 60,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
                image: item.imageUrl != null ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover) : null,
              ),
              child: item.imageUrl == null ? const Icon(Ionicons.fast_food_outline, color: Colors.grey) : null,
            ),
          ),
          // Name + Desc
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
                if (item.description.isNotEmpty)
                  Text(item.description, style: const TextStyle(fontSize: 12, color: AdminTheme.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Category
          Expanded(flex: 2, child: Text(item.category ?? 'N/A', style: const TextStyle(color: AdminTheme.primaryText))),
          // Price
          Expanded(flex: 1, child: Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryText))),
          // Diet
          Expanded(
            flex: 1,
            child: Row(
              children: [
                _buildDietBadge(item.isVeg),
              ],
            ),
          ),
          // Bestseller Toggle
          Expanded(
            flex: 1,
            child: Transform.scale(
              scale: 0.8,
              alignment: Alignment.centerLeft,
              child: Switch(
                value: item.isBestseller,
                onChanged: (val) => _updateBestseller(context, val),
                activeColor: AdminTheme.primaryColor,
              ),
            ),
          ),
          // Availability Toggle
          Expanded(
            flex: 1,
            child: Transform.scale(
              scale: 0.8,
              alignment: Alignment.centerLeft,
              child: Switch(
                value: !item.isOutOfStock,
                onChanged: (val) => _toggleAvailability(context),
                activeColor: AdminTheme.primaryColor,
              ),
            ),
          ),
          // Actions
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(onPressed: () => _editItem(context), icon: const Icon(Ionicons.create_outline, size: 18, color: AdminTheme.secondaryText)),
                IconButton(onPressed: () => _deleteItem(context), icon: const Icon(Ionicons.trash_outline, size: 18, color: AdminTheme.critical)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietBadge(bool isVeg) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: isVeg ? Colors.green : Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: isVeg ? Colors.green : Colors.red,
          shape: isVeg ? BoxShape.circle : BoxShape.rectangle, // Simple approximation
        ),
      ),
    );
  }

  void _updateBestseller(BuildContext context, bool val) async {
    final cat = provider.categories.firstWhere((c) => c.name == item.category, orElse: () => provider.categories.first);
    await provider.updateBestsellerStatus(cat.id, item.id, val);
  }

  void _toggleAvailability(BuildContext context) async {
    final cat = provider.categories.firstWhere((c) => c.name == item.category, orElse: () => provider.categories.first);
    await provider.toggleAvailability(cat.id, item.id);
  }

  void _editItem(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => MenuItemDialog(
        item: item,
        categories: provider.categories,
        tenantId: context.read<AdminAuthProvider>().tenantId!,
      ),
    );
    if (result != null) {
      await provider.updateMenuItem(result['categoryId'], result['item']);
    }
  }

  void _deleteItem(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AdminTheme.critical),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final cat = provider.categories.firstWhere((c) => c.name == item.category, orElse: () => provider.categories.first);
      await provider.deleteMenuItem(cat.id, item.id);
    }
  }
}
