import 'package:flutter/material.dart';
import '../../models/tenant_model.dart'; // For MenuItem
import '../../services/menu_service.dart';
import '../../models/order.dart'; // For OrderItem
import 'package:uuid/uuid.dart';

class MenuSelectorDialog extends StatefulWidget {
  final String tenantId;

  const MenuSelectorDialog({super.key, required this.tenantId});

  @override
  State<MenuSelectorDialog> createState() => _MenuSelectorDialogState();
}

class _MenuSelectorDialogState extends State<MenuSelectorDialog> {
  final MenuService _menuService = MenuService();
  List<MenuItem> _items = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  
  // Selection state
  final Map<String, int> quantities = {};
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final items = await _menuService.getMenuItems(widget.tenantId);
      final categories = await _menuService.getCategories(widget.tenantId);
      if (mounted) {
        setState(() {
          _items = items.where((i) => !i.isOutOfStock).toList(); // Only available items
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading menu: $e')));
      }
    }
  }

  List<MenuItem> get _filteredItems {
    if (_selectedCategory == 'All') return _items;
    return _items.where((i) => i.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Add Items to Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            
            // Categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('All'),
                  ..._categories.map((c) => _buildCategoryChip(c.name)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Items List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final qty = quantities[item.id] ?? 0;
                        return Card(
                          elevation: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: item.imageUrl != null
                                    ? Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.fastfood, size: 40))
                                    : const Center(child: Icon(Icons.fastfood, size: 40)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('₹${item.price}', style: TextStyle(color: Colors.grey[700])),
                                    const SizedBox(height: 4),
                                    if (qty == 0)
                                      ElevatedButton(
                                        onPressed: () => setState(() => quantities[item.id] = 1),
                                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 30)),
                                        child: const Text('Add'),
                                      )
                                    else
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline),
                                            onPressed: () => setState(() {
                                               if (quantities[item.id]! > 0) quantities[item.id] = quantities[item.id]! - 1;
                                            }),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline),
                                            onPressed: () => setState(() => quantities[item.id] = quantities[item.id]! + 1),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      )
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),
            
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Items: ${quantities.values.fold(0, (sum, q) => sum + q)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: () {
                    final selectedItems = <OrderItem>[];
                    quantities.forEach((itemId, qty) {
                      if (qty > 0) {
                        final menuParam = _items.firstWhere((i) => i.id == itemId);
                        selectedItems.add(OrderItem(
                          id: const Uuid().v4(), // New unique ID for the OrderItem instance
                          name: menuParam.name,
                          price: menuParam.price,
                          quantity: qty,
                          status: OrderItemStatus.pending,
                        ));
                      }
                    });
                    Navigator.pop(context, selectedItems);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
                  child: const Text('CONFIRM'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) => setState(() => _selectedCategory = label),
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.deepPurple.withOpacity(0.2),
        labelStyle: TextStyle(color: isSelected ? Colors.deepPurple : Colors.black),
      ),
    );
  }
}
