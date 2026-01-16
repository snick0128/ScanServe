import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../models/tenant_model.dart';
import '../../../models/activity_log_model.dart';
import '../../../services/menu_service.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/activity_provider.dart';
import 'widgets/menu_item_dialog.dart';

class MenuItemsScreen extends StatefulWidget {
  final String tenantId;

  const MenuItemsScreen({super.key, required this.tenantId});

  @override
  State<MenuItemsScreen> createState() => _MenuItemsScreenState();
}

class _MenuItemsScreenState extends State<MenuItemsScreen> {
  final MenuService _menuService = MenuService();
  List<MenuItem> _items = [];
  List<MenuItem> _filteredItems = [];
  List<Category> _categories = [];
  bool _isLoading = true;

  // Filter states
  String _searchQuery = '';
  String? _selectedCategoryFilter;
  String? _selectedTypeFilter; // 'all', 'veg', 'nonveg'
  String? _selectedAvailabilityFilter; // 'all', 'available', 'outofstock'

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
        _applyFilters();
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

  void _applyFilters() {
    setState(() {
      _filteredItems = _items.where((item) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!item.name.toLowerCase().contains(query) &&
              !(item.category?.toLowerCase().contains(query) ?? false)) {
            return false;
          }
        }

        // Category filter
        if (_selectedCategoryFilter != null && _selectedCategoryFilter != 'all') {
          if (item.category != _selectedCategoryFilter) {
            return false;
          }
        }

        // Type filter (Veg/Non-Veg)
        if (_selectedTypeFilter != null && _selectedTypeFilter != 'all') {
          if (_selectedTypeFilter == 'veg' && !item.isVeg) {
            return false;
          }
          if (_selectedTypeFilter == 'nonveg' && item.isVeg) {
            return false;
          }
        }

        // Availability filter
        if (_selectedAvailabilityFilter != null && _selectedAvailabilityFilter != 'all') {
          if (_selectedAvailabilityFilter == 'available' && item.isOutOfStock) {
            return false;
          }
          if (_selectedAvailabilityFilter == 'outofstock' && !item.isOutOfStock) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  Future<void> _toggleAvailability(MenuItem item) async {
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
        final updatedItem = MenuItem(
          id: item.id,
          name: item.name,
          description: item.description,
          price: item.price,
          imageUrl: item.imageUrl,
          category: item.category,
          subcategory: item.subcategory,
          itemType: item.itemType,
          stockCount: item.stockCount,
          isTracked: item.isTracked,
          isManualAvailable: !item.isManualAvailable,
          inventoryTrackingType: item.inventoryTrackingType,
          inventoryIngredients: item.inventoryIngredients,
        );

        // Optimistic UI Update
        setState(() {
          final index = _items.indexWhere((i) => i.id == item.id);
          if (index != -1) {
            _items[index] = updatedItem;
            _applyFilters();
          }
        });

        await _menuService.updateMenuItem(widget.tenantId, categoryId, updatedItem);
        
        // Log activity (non-blocking)
        if (mounted) {
          final auth = context.read<AdminAuthProvider>();
          final activity = context.read<ActivityProvider>();
          activity.logAction(
            action: 'Availability Changed',
            description: '${item.name} is now ${updatedItem.isManualAvailable ? 'AVAILABLE' : 'SOLD OUT'}',
            actorId: auth.user?.uid ?? 'demo',
            actorName: auth.role == 'kitchen' ? 'Kitchen Staff' : 'Admin User',
            actorRole: auth.role ?? 'admin',
            type: ActivityType.menuItemUpdate,
            tenantId: widget.tenantId,
            metadata: {'itemId': item.id, 'isAvailable': updatedItem.isManualAvailable},
          );
        }
      }
    } catch (e) {
      // Revert optimistic update on failure
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = item;
          _applyFilters();
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating availability: $e')),
        );
      }
    }
  }

  Future<void> _showEditDialog([MenuItem? item]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => MenuItemDialog(
        item: item,
        categories: _categories,
        tenantId: widget.tenantId,
      ),
    );

    if (result != null) {
      final newItem = result['item'] as MenuItem;
      final categoryId = result['categoryId'] as String;
      final isEditing = item != null;

      try {
        if (isEditing) {
          await _menuService.updateMenuItem(widget.tenantId, categoryId, newItem);
        } else {
          await _menuService.addMenuItem(widget.tenantId, categoryId, newItem);
        }

        // Log activity
        if (mounted) {
          final auth = context.read<AdminAuthProvider>();
          final activity = context.read<ActivityProvider>();
          
          String description = isEditing ? 'Updated menu item: ${newItem.name}' : 'Added new menu item: ${newItem.name}';
          
          if (isEditing && item.price != newItem.price) {
            description = 'Price changed for ${newItem.name}: ₹${item.price.toStringAsFixed(0)} ➔ ₹${newItem.price.toStringAsFixed(0)}';
          }

          await activity.logAction(
            action: isEditing ? 'Menu Updated' : 'Item Added',
            description: description,
            actorId: auth.user?.uid ?? 'demo',
            actorName: auth.role == 'kitchen' ? 'Kitchen Staff' : 'Admin User',
            actorRole: auth.role ?? 'admin',
            type: isEditing ? ActivityType.menuItemUpdate : ActivityType.menuItemAdd,
            tenantId: widget.tenantId,
            metadata: {
              'itemId': newItem.id, 
              'category': newItem.category,
              'oldPrice': isEditing ? item.price : null,
              'newPrice': newItem.price,
            },
          );
        }

        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving item: $e')),
          );
        }
      }
    }
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
          
          // Log activity
          if (mounted) {
            final auth = context.read<AdminAuthProvider>();
            context.read<ActivityProvider>().logAction(
              action: 'Menu Item Deleted',
              description: 'Deleted menu item: ${item.name}',
              actorId: auth.user?.uid ?? 'demo',
              actorName: auth.role == 'kitchen' ? 'Kitchen Staff' : 'Admin User',
              actorRole: auth.role ?? 'admin',
              type: ActivityType.menuItemDelete,
              tenantId: widget.tenantId,
              metadata: {'itemId': item.id, 'name': item.name},
            );
          }
          
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

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Category Filter
            PopupMenuButton<String>(
              child: Chip(
                avatar: const Icon(Ionicons.grid_outline, size: 18),
                label: Text(_selectedCategoryFilter == null || _selectedCategoryFilter == 'all' 
                  ? 'Category' 
                  : _selectedCategoryFilter!),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'all', child: Text('All Categories')),
                ..._categories.map((cat) => PopupMenuItem(
                  value: cat.name,
                  child: Text(cat.name),
                )),
              ],
              onSelected: (value) {
                setState(() {
                  _selectedCategoryFilter = value;
                  _applyFilters();
                });
              },
            ),
            const SizedBox(width: 8),
            // Type Filter
            ChoiceChip(
              label: const Text('All'),
              selected: _selectedTypeFilter == null || _selectedTypeFilter == 'all',
              onSelected: (selected) {
                setState(() {
                  _selectedTypeFilter = 'all';
                  _applyFilters();
                });
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Ionicons.leaf_outline, color: Colors.green, size: 14),
                  SizedBox(width: 4),
                  Text('Veg'),
                ],
              ),
              selected: _selectedTypeFilter == 'veg',
              onSelected: (selected) {
                setState(() {
                  _selectedTypeFilter = 'veg';
                  _applyFilters();
                });
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Ionicons.nutrition_outline, color: Colors.red, size: 14),
                  SizedBox(width: 4),
                  Text('Non-Veg'),
                ],
              ),
              selected: _selectedTypeFilter == 'nonveg',
              onSelected: (selected) {
                setState(() {
                  _selectedTypeFilter = 'nonveg';
                  _applyFilters();
                });
              },
            ),
            const SizedBox(width: 8),
            // Availability Filter
            ChoiceChip(
              label: const Text('Available'),
              selected: _selectedAvailabilityFilter == 'available',
              onSelected: (selected) {
                setState(() {
                  _selectedAvailabilityFilter = selected ? 'available' : 'all';
                  _applyFilters();
                });
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Out of Stock'),
              selected: _selectedAvailabilityFilter == 'outofstock',
              onSelected: (selected) {
                setState(() {
                  _selectedAvailabilityFilter = selected ? 'outofstock' : 'all';
                  _applyFilters();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(),
        icon: const Icon(Ionicons.add_circle_outline),
        label: const Text('Add Item'),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search menu items...',
                prefixIcon: const Icon(Ionicons.search_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),

          // Filter Chips
          _buildFilterChips(),

          const Divider(height: 1),

          // Results count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Text(
                  '${_filteredItems.length} item${_filteredItems.length != 1 ? 's' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Responsive Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 900;

                      if (_filteredItems.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restaurant_menu,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                _items.isEmpty
                                    ? 'No menu items yet'
                                    : 'No items match your filters',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                              if (_items.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedCategoryFilter = 'all';
                                      _selectedTypeFilter = 'all';
                                      _selectedAvailabilityFilter = 'all';
                                      _applyFilters();
                                    });
                                  },
                                  child: const Text('Clear Filters'),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          // Table Header (Desktop Only)
                          if (!isMobile)
                            Container(
                              color: Colors.grey[200],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: const Row(
                                children: [
                                  SizedBox(
                                      width: 60,
                                      child: Text('Photo',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12))),
                                  SizedBox(width: 12),
                                  Expanded(
                                      flex: 2,
                                      child: Text('Name',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12))),
                                  SizedBox(width: 8),
                                  Expanded(
                                      child: Text('Category',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12))),
                                  SizedBox(width: 8),
                                  SizedBox(
                                      width: 40,
                                      child: Text('Type',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12))),
                                  SizedBox(width: 8),
                                  SizedBox(
                                      width: 80,
                                      child: Text('Price',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12))),
                                  SizedBox(width: 8),
                                  SizedBox(
                                      width: 90,
                                      child: Text('Available',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12))),
                                  SizedBox(width: 8),
                                  SizedBox(
                                      width: 100,
                                      child: Text('Actions',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12))),
                                ],
                              ),
                            ),

                          // Items List
                          Expanded(
                            child: ListView.builder(
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];

                                if (isMobile) {
                                  // Mobile Card View
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Photo
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: item.imageUrl != null
                                                    ? Image.network(
                                                        item.imageUrl!,
                                                        width: 70,
                                                        height: 70,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context,
                                                                error,
                                                                stackTrace) =>
                                                            Container(
                                                          width: 70,
                                                          height: 70,
                                                          color:
                                                              Colors.grey[200],
                                                          child: const Icon(
                                                              Ionicons
                                                                  .restaurant_outline,
                                                              size: 30),
                                                        ),
                                                      )
                                                    : Container(
                                                        width: 70,
                                                        height: 70,
                                                        color:
                                                            Colors.grey[200],
                                                        child: const Icon(
                                                            Ionicons
                                                                .restaurant_outline,
                                                            size: 30),
                                                      ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            item.name,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16),
                                                          ),
                                                        ),
                                                        Icon(
                                                          item.isVeg
                                                              ? Ionicons.leaf
                                                              : Ionicons
                                                                  .nutrition,
                                                          color: item.isVeg
                                                              ? Colors.green
                                                              : Colors.red,
                                                          size: 16,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      item.category ?? 'N/A',
                                                      style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 13),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '₹${item.price.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                          color: Colors
                                                              .deepPurple),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 20),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    item.isOutOfStock
                                                        ? 'Out of Stock'
                                                        : 'Available',
                                                    style: TextStyle(
                                                      color: item.isOutOfStock
                                                          ? Colors.red
                                                          : Colors.green,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Switch(
                                                    value: !item.isOutOfStock,
                                                    onChanged: (value) =>
                                                        _toggleAvailability(
                                                            item),
                                                    activeColor: Colors.green,
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                        Ionicons.create_outline,
                                                        size: 20),
                                                    onPressed: () =>
                                                        _showEditDialog(item),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Ionicons.trash_outline,
                                                        size: 20,
                                                        color: Colors.red),
                                                    onPressed: () =>
                                                        _deleteItem(item),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                // Desktop Table Row
                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey[300]!),
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => _showEditDialog(item),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 60,
                                            child: item.imageUrl != null
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Image.network(
                                                      item.imageUrl!,
                                                      width: 50,
                                                      height: 50,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                              error,
                                                              stackTrace) =>
                                                          const Icon(
                                                              Ionicons
                                                                  .restaurant_outline,
                                                              size: 50),
                                                    ),
                                                  )
                                                : const Icon(
                                                    Ionicons.restaurant_outline,
                                                    size: 50),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (item.description.isNotEmpty)
                                                  Text(
                                                    item.description,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item.category ?? 'N/A',
                                              style:
                                                  const TextStyle(fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 40,
                                            child: Icon(
                                              item.isVeg
                                                  ? Ionicons.leaf
                                                  : Ionicons.nutrition,
                                              color: item.isVeg
                                                  ? Colors.green
                                                  : Colors.red,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 80,
                                            child: Text(
                                              '₹${item.price.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 90,
                                            child: Switch(
                                              value: !item.isOutOfStock,
                                              onChanged: (value) =>
                                                  _toggleAvailability(item),
                                              activeColor: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 100,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Ionicons.create_outline,
                                                      size: 20),
                                                  onPressed: () =>
                                                      _showEditDialog(item),
                                                  tooltip: 'Edit',
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(
                                                      Ionicons.trash_outline,
                                                      size: 20,
                                                      color: Colors.red),
                                                  onPressed: () =>
                                                      _deleteItem(item),
                                                  tooltip: 'Delete',
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
