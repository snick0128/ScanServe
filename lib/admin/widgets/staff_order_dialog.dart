import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/order.dart' as model;
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
  final bool autoStart;

  const StaffOrderDialog({
    super.key,
    required this.tenantId,
    this.preselectedTableId,
    this.preselectedTableName,
    this.autoStart = false,
  });

  static Future<void> startQuickOrder(
    BuildContext context, {
    required String tenantId,
    String? tableId,
    String? tableName,
  }) async {
    final List<model.OrderItem>? selectedItems = await showDialog(
      context: context,
      builder: (context) => MenuSelectorDialog(tenantId: tenantId),
    );

    if (!context.mounted) return;
    if (selectedItems == null || selectedItems.isEmpty) return;

    await _StaffOrderDialogState._createOrderStatic(
      context,
      items: selectedItems,
      tenantId: tenantId,
      tableId: tableId,
      tableName: tableName,
    );
  }

  @override
  State<StaffOrderDialog> createState() => _StaffOrderDialogState();
}

class _StaffOrderDialogState extends State<StaffOrderDialog> {
  String? _selectedTableId;
  String? _selectedTableName;
  bool _isCreating = false;
  OrderType _selectedOrderType = OrderType.dineIn;
  bool _autoLaunched = false;

  @override
  void initState() {
    super.initState();
    _selectedTableId = widget.preselectedTableId;
    _selectedTableName = widget.preselectedTableName;
    if (widget.autoStart) {
      _selectedOrderType = widget.preselectedTableId != null
          ? OrderType.dineIn
          : OrderType.parcel;
    }
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoStart());
    }
  }

  Future<void> _autoStart() async {
    if (_autoLaunched) return;
    _autoLaunched = true;
    await _selectMenu();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.autoStart) {
      return const SizedBox.shrink();
    }

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
                  const Text(
                    'Create New Staff Order',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeOption(
                      'Dine-in',
                      Icons.restaurant,
                      _selectedOrderType == OrderType.dineIn,
                      () =>
                          setState(() => _selectedOrderType = OrderType.dineIn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeOption(
                      'Parcel',
                      Icons.shopping_bag,
                      _selectedOrderType == OrderType.parcel,
                      () =>
                          setState(() => _selectedOrderType = OrderType.parcel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_selectedOrderType == OrderType.dineIn &&
                  widget.preselectedTableId == null) ...[
                const Text(
                  '1. Select Table',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
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
                            leading: Icon(
                              Icons.table_restaurant,
                              color: table.isOccupied
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            title: Text(table.name),
                            subtitle: Text(
                              table.isOccupied
                                  ? 'Currently Occupied'
                                  : 'Available',
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AdminTheme.success,
                                  )
                                : null,
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
              ] else if (_selectedOrderType == OrderType.dineIn &&
                  widget.preselectedTableId != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminTheme.success.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AdminTheme.success.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.table_restaurant,
                        color: AdminTheme.success,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ordering for ${widget.preselectedTableName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.primaryText,
                        ),
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
                    border: Border.all(
                      color: AdminTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shopping_bag, color: AdminTheme.primaryColor),
                      SizedBox(width: 12),
                      Text(
                        'Creating Parcel / Takeaway Order',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.primaryText,
                        ),
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
                  onPressed:
                      ((_selectedOrderType == OrderType.dineIn &&
                              _selectedTableId == null) ||
                          _isCreating)
                      ? null
                      : _selectMenu,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isCreating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.preselectedTableId != null
                              ? 'Start Ordering'
                              : 'Next: Select Menu Items',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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

    if (!mounted) return;
    if (selectedItems == null || selectedItems.isEmpty) {
      if (widget.autoStart) {
        Navigator.pop(context);
      }
      return;
    }
    final ok = await _createOrder(selectedItems);
    if (!mounted) return;
    if (widget.autoStart) {
      Navigator.pop(context);
      return;
    }
    if (ok) {
      Navigator.pop(context);
    }
  }

  Widget _buildTypeOption(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
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

  Future<bool> _createOrder(List<model.OrderItem> items) async {
    setState(() => _isCreating = true);
    try {
      final auth = context.read<AdminAuthProvider>();
      final ordersProvider = context.read<OrdersProvider>();
      final tablesProvider = context.read<TablesProvider>();

      await _createOrderStatic(
        context,
        items: items,
        tenantId: widget.tenantId,
        tableId: _selectedOrderType == OrderType.parcel
            ? null
            : _selectedTableId,
        tableName: _selectedOrderType == OrderType.parcel
            ? null
            : _selectedTableName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order created successfully'),
            backgroundColor: AdminTheme.success,
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  double _resolveTaxRate(OrdersProvider ordersProvider) {
    final settingsRate = (ordersProvider.tenantSettings['taxRate'] as num?)
        ?.toDouble();
    if (settingsRate != null && settingsRate >= 0) return settingsRate;
    return 0.18;
  }

  static double _resolveTaxRateStatic(OrdersProvider ordersProvider) {
    final settingsRate = (ordersProvider.tenantSettings['taxRate'] as num?)
        ?.toDouble();
    if (settingsRate != null && settingsRate >= 0) return settingsRate;
    return 0.18;
  }

  static Future<void> _createOrderStatic(
    BuildContext context, {
    required List<model.OrderItem> items,
    required String tenantId,
    String? tableId,
    String? tableName,
  }) async {
    final auth = context.read<AdminAuthProvider>();
    final ordersProvider = context.read<OrdersProvider>();
    final tablesProvider = context.read<TablesProvider>();

    final subtotal = items.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final taxRate = _resolveTaxRateStatic(ordersProvider);
    final tax = subtotal * taxRate;
    final total = subtotal + tax;

    final isParcel = tableId == null;
    final newOrder = model.Order(
      id: const Uuid().v4(),
      tenantId: tenantId,
      tableId: isParcel ? 'PARCEL' : tableId,
      tableName: isParcel ? 'Parcel' : tableName,
      items: items,
      status: model.OrderStatus.pending,
      subtotal: subtotal,
      tax: tax,
      total: total,
      createdAt: DateTime.now(),
      customerName: 'Staff Created',
      captainName: auth.userName ?? 'Staff',
      type: isParcel ? 'parcel' : 'dineIn',
    );

    await ordersProvider.createOrder(newOrder);

    if (!isParcel && tableId != null) {
      final table = tablesProvider.tables.firstWhere((t) => t.id == tableId);
      await tablesProvider.updateTable(
        table.copyWith(
          status: TableStatus.occupied,
          isAvailable: false,
          isOccupied: true,
          occupiedAt: DateTime.now(),
        ),
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order created successfully'),
          backgroundColor: AdminTheme.success,
        ),
      );
    }
  }
}
