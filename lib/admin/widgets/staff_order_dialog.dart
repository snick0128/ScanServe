import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/order.dart' as model;
import '../../models/tenant_model.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/tables_provider.dart';
import 'menu_selector_dialog.dart';
import '../theme/admin_theme.dart';
import '../../../models/table_status.dart';
import '../../../models/order_model.dart';

class StaffOrderDialog extends StatefulWidget {
  final String tenantId;
  final String? preselectedTableId;
  final String? preselectedTableName;

  const StaffOrderDialog({
    super.key, 
    required this.tenantId,
    this.preselectedTableId,
    this.preselectedTableName,
  });

  @override
  State<StaffOrderDialog> createState() => _StaffOrderDialogState();
}

class _StaffOrderDialogState extends State<StaffOrderDialog> {
  String? _selectedTableId;
  String? _selectedTableName;
  bool _isCreating = false;
  OrderType _selectedOrderType = OrderType.dineIn;

  @override
  void initState() {
    super.initState();
    _selectedTableId = widget.preselectedTableId;
    _selectedTableName = widget.preselectedTableName;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width < 600 ? size.width - 24 : 500.0;
    final maxHeight = size.height * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create New Staff Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 24),
              
              // Order Type Selection
              const Text('Order Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeOption(
                      'Dine-in', 
                      Icons.restaurant, 
                      _selectedOrderType == OrderType.dineIn,
                      () => setState(() => _selectedOrderType = OrderType.dineIn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeOption(
                      'Parcel', 
                      Icons.shopping_bag, 
                      _selectedOrderType == OrderType.parcel,
                      () => setState(() => _selectedOrderType = OrderType.parcel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

            if (_selectedOrderType == OrderType.dineIn && widget.preselectedTableId == null) ...[
              const Text('1. Select Table', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Consumer<TablesProvider>(
                builder: (context, tablesProvider, _) {
                  final tables = tablesProvider.tables;
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: tables.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final table = tables[index];
                        final isSelected = _selectedTableId == table.id;
                        return ListTile(
                          leading: Icon(Icons.table_restaurant, color: table.isOccupied ? Colors.orange : Colors.green),
                          title: Text(table.name),
                          subtitle: Text(table.isOccupied ? 'Currently Occupied' : 'Available'),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: AdminTheme.success) : null,
                          onTap: () {
                            setState(() {
                              _selectedTableId = table.id;
                              _selectedTableName = table.name;
                            });
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ] else if (_selectedOrderType == OrderType.dineIn && widget.preselectedTableId != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AdminTheme.success.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminTheme.success.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.table_restaurant, color: AdminTheme.success),
                    const SizedBox(width: 12),
                    Text(
                      'Ordering for ${widget.preselectedTableName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else if (_selectedOrderType == OrderType.parcel) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AdminTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminTheme.primaryColor.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shopping_bag, color: AdminTheme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'Creating Parcel / Takeaway Order',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: ((_selectedOrderType == OrderType.dineIn && _selectedTableId == null) || _isCreating) ? null : _selectMenu,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isCreating 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.preselectedTableId != null ? 'Start Ordering' : 'Next: Select Menu Items', 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectMenu() async {
    final List<model.OrderItem>? selectedItems = await showDialog(
      context: context,
      builder: (context) => MenuSelectorDialog(tenantId: widget.tenantId),
    );

    if (selectedItems != null && selectedItems.isNotEmpty && mounted) {
      _createOrder(selectedItems);
    }
  }

  Widget _buildTypeOption(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AdminTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AdminTheme.primaryColor : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createOrder(List<model.OrderItem> items) async {
    setState(() => _isCreating = true);
    try {
      final auth = context.read<AdminAuthProvider>();
      final ordersProvider = context.read<OrdersProvider>();
      final tablesProvider = context.read<TablesProvider>();

      final subtotal = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
      final tax = subtotal * 0.05; // assumption
      final total = subtotal + tax;

      final newOrder = model.Order(
        id: const Uuid().v4(),
        tenantId: widget.tenantId,
        tableId: _selectedOrderType == OrderType.parcel ? 'PARCEL' : _selectedTableId,
        tableName: _selectedOrderType == OrderType.parcel ? 'Parcel' : _selectedTableName,
        items: items,
        status: model.OrderStatus.pending,
        subtotal: subtotal,
        tax: tax,
        total: total,
        createdAt: DateTime.now(),
        customerName: 'Staff Created',
        captainName: auth.userName ?? 'Staff',
        type: _selectedOrderType == OrderType.parcel ? 'parcel' : 'dineIn',
      );

      await ordersProvider.createOrder(newOrder);

      // Update table status if it's a Dine-in order
      if (_selectedOrderType == OrderType.dineIn && _selectedTableId != null) {
        final table = tablesProvider.tables.firstWhere((t) => t.id == _selectedTableId);
        await tablesProvider.updateTable(table.copyWith(
          status: TableStatus.occupied,
          isAvailable: false,
          isOccupied: true,
          occupiedAt: DateTime.now(),
        ));
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order created successfully'), backgroundColor: AdminTheme.success),
        );
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
       }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}
