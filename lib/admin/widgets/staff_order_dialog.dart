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

  @override
  void initState() {
    super.initState();
    _selectedTableId = widget.preselectedTableId;
    _selectedTableName = widget.preselectedTableName;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
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
            if (widget.preselectedTableId == null) ...[
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
            ] else ...[
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
            ],
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _selectedTableId == null ? null : _selectMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  widget.preselectedTableId != null ? 'Start Ordering' : 'Next: Select Menu Items', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
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
        tableId: _selectedTableId,
        tableName: _selectedTableName,
        items: items,
        status: model.OrderStatus.pending,
        subtotal: subtotal,
        tax: tax,
        total: total,
        createdAt: DateTime.now(),
        customerName: 'Staff Created',
        captainName: auth.userName ?? 'Staff',
      );

      await ordersProvider.createOrder(newOrder);

      // Update table status
      final table = tablesProvider.tables.firstWhere((t) => t.id == _selectedTableId);
      await tablesProvider.updateTable(table.copyWith(
        status: 'occupied',
        isAvailable: false,
        isOccupied: true,
        occupiedAt: DateTime.now(),
      ));

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
