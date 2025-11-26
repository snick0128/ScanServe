import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../../models/tenant_model.dart';
import '../../../services/inventory_service.dart';
import '../../../services/menu_service.dart';

class InventoryScreen extends StatefulWidget {
  final String tenantId;
  final InventoryService? inventoryService;
  final MenuService? menuService;

  const InventoryScreen({
    super.key,
    required this.tenantId,
    this.inventoryService,
    this.menuService,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late final InventoryService _inventoryService;
  late final MenuService _menuService;
  List<MenuItem> _items = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _inventoryService = widget.inventoryService ?? InventoryService();
    _menuService = widget.menuService ?? MenuService();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _menuService.getMenuItems(widget.tenantId);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading inventory: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  List<MenuItem> get _filteredItems {
    return _items.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_showLowStockOnly) {
        return matchesSearch && item.isTracked && item.stockCount <= 5;
      }
      return matchesSearch;
    }).toList();
  }

  Future<void> _updateStock(MenuItem item, int newStock, bool isTracked) async {
    try {
      // Find category ID for the item (this is a bit inefficient, ideally item should have categoryId)
      // For now, we'll assume we can find it or need to fetch categories first
      // Optimization: In a real app, MenuItem should store categoryId
      final categories = await _menuService.getCategories(widget.tenantId);
      String? categoryId;
      
      for (var cat in categories) {
        if (cat.items.any((i) => i.id == item.id)) {
          categoryId = cat.id;
          break;
        }
      }

      if (categoryId != null) {
        await _inventoryService.updateStock(
          widget.tenantId,
          categoryId,
          item.id,
          newStock,
          isTracked: isTracked,
        );
        await _loadItems(); // Reload to show changes
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stock updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating stock: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Column(
      children: [
        // Header & Filters
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 16),
              FilterChip(
                label: const Text('Low Stock Only'),
                selected: _showLowStockOnly,
                onSelected: (value) => setState(() => _showLowStockOnly = value),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadItems,
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredItems.isEmpty
                  ? const Center(child: Text('No items found'))
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: item.imageUrl != null
                                ? CircleAvatar(backgroundImage: NetworkImage(item.imageUrl!))
                                : const CircleAvatar(child: Icon(Icons.fastfood)),
                            title: Text(item.name),
                            subtitle: Text(
                              item.isTracked
                                  ? 'Stock: ${item.stockCount}'
                                  : 'Stock Tracking: Off',
                              style: TextStyle(
                                color: item.isTracked && item.stockCount <= 5
                                    ? Colors.red
                                    : null,
                                fontWeight: item.isTracked && item.stockCount <= 5
                                    ? FontWeight.bold
                                    : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditStockDialog(item),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showEditStockDialog(MenuItem item) {
    final stockController = TextEditingController(text: item.stockCount.toString());
    bool isTracked = item.isTracked;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Stock: ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Track Stock'),
                value: isTracked,
                onChanged: (value) => setState(() => isTracked = value),
              ),
              if (isTracked)
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Count',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newStock = int.tryParse(stockController.text) ?? 0;
                _updateStock(item, newStock, isTracked);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
