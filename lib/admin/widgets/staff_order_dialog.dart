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

  /// Quick-order path: called when a staff member taps a vacant table card.
  /// Shows a compact guest-info sheet then opens the menu selector.
  static Future<void> startQuickOrder(
    BuildContext context, {
    required String tenantId,
    String? tableId,
    String? tableName,
  }) async {
    // Step 1: Capture guest count + optional customer info
    final guestInfo = await showDialog<_GuestInfo>(
      context: context,
      builder: (_) => _GuestInfoDialog(tableName: tableName),
    );
    if (!context.mounted) return;
    // If dismissed without confirming, abort
    if (guestInfo == null) return;

    // Step 2: Select menu items
    final List<model.OrderItem>? selectedItems = await showDialog(
      context: context,
      builder: (context) => MenuSelectorDialog(tenantId: tenantId),
    );
    if (!context.mounted) return;
    if (selectedItems == null || selectedItems.isEmpty) return;

    // Step 3: Create order
    await _StaffOrderDialogState._createOrderStatic(
      context,
      items: selectedItems,
      tenantId: tenantId,
      tableId: tableId,
      tableName: tableName,
      guestCount: guestInfo.guestCount,
      customerName: guestInfo.customerName,
      customerPhone: guestInfo.customerPhone,
    );
  }

  @override
  State<StaffOrderDialog> createState() => _StaffOrderDialogState();
}

// ─── Simple data class ──────────────────────────────────────────────────────
class _GuestInfo {
  final int guestCount;
  final String? customerName;
  final String? customerPhone;
  const _GuestInfo({
    required this.guestCount,
    this.customerName,
    this.customerPhone,
  });
}

// ─── Compact guest-info dialog ───────────────────────────────────────────────
class _GuestInfoDialog extends StatefulWidget {
  final String? tableName;
  const _GuestInfoDialog({this.tableName});

  @override
  State<_GuestInfoDialog> createState() => _GuestInfoDialogState();
}

class _GuestInfoDialogState extends State<_GuestInfoDialog> {
  int _guestCount = 0;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _customCtrl = TextEditingController();
  bool _showCustomInput = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxW = (size.width - 32).clamp(280.0, 420.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.tableName != null
                          ? 'New Order — ${widget.tableName}'
                          : 'New Order',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.primaryText,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Guest Count ──────────────────────────────────────────────
              const Text(
                'GUESTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AdminTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final n in [1, 2, 3, 4])
                    _GuestChip(
                      label: '$n',
                      selected: _guestCount == n && !_showCustomInput,
                      onTap: () => setState(() {
                        _guestCount = n;
                        _showCustomInput = false;
                      }),
                    ),
                  _GuestChip(
                    label: '5+',
                    selected: _showCustomInput || _guestCount >= 5,
                    onTap: () => setState(() {
                      _showCustomInput = true;
                      if (_guestCount < 5) _guestCount = 5;
                    }),
                  ),
                ],
              ),
              if (_showCustomInput) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _customCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Count',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n > 0) setState(() => _guestCount = n);
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── Optional customer details ─────────────────────────────────
              const Text(
                'CUSTOMER INFO (OPTIONAL)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AdminTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Name',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Phone',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Action buttons ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          _GuestInfo(
                            guestCount: _guestCount,
                            customerName: _nameCtrl.text.trim().isEmpty
                                ? null
                                : _nameCtrl.text.trim(),
                            customerPhone: _phoneCtrl.text.trim().isEmpty
                                ? null
                                : _phoneCtrl.text.trim(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Select Items',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small chip widget ─────────────────────────────────────────────────────────
class _GuestChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GuestChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? AdminTheme.primaryColor : Colors.white,
          border: Border.all(
            color: selected ? AdminTheme.primaryColor : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: selected ? Colors.white : AdminTheme.primaryText,
          ),
        ),
      ),
    );
  }
}

// ─── Main dialog state ───────────────────────────────────────────────────────
class _StaffOrderDialogState extends State<StaffOrderDialog> {
  String? _selectedTableId;
  String? _selectedTableName;
  bool _isCreating = false;
  OrderType _selectedOrderType = OrderType.dineIn;
  bool _autoLaunched = false;
  int _guestCount = 0;
  String? _customerName;
  String? _customerPhone;

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
              const SizedBox(height: 20),

              // ── Guest Count ───────────────────────────────────────────────
              const Text(
                'GUESTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AdminTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final n in [1, 2, 3, 4, 5])
                    _GuestChip(
                      label: n == 5 ? '5+' : '$n',
                      selected: _guestCount == n,
                      onTap: () => setState(() => _guestCount = n),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Customer info ─────────────────────────────────────────────
              const Text(
                'CUSTOMER INFO (OPTIONAL)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AdminTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Name',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => _customerName = v.trim().isEmpty ? null : v.trim(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Phone',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) =>
                          _customerPhone = v.trim().isEmpty ? null : v.trim(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Order type ────────────────────────────────────────────────
              const Text(
                'ORDER TYPE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AdminTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 24),

              if (_selectedOrderType == OrderType.dineIn &&
                  widget.preselectedTableId == null) ...[
                const Text(
                  'SELECT TABLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AdminTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<TablesProvider>(
                  builder: (context, tablesProvider, _) {
                    final tables = tablesProvider.tables;
                    return Container(
                      height: 180,
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
                            dense: true,
                            leading: Icon(
                              Icons.table_restaurant,
                              color: table.isOccupied
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            title: Text(table.name),
                            subtitle: Text(
                              table.isOccupied
                                  ? 'Occupied'
                                  : 'Available',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AdminTheme.success,
                                  )
                                : null,
                            onTap: () => setState(() {
                              _selectedTableId = table.id;
                              _selectedTableName = table.name;
                            }),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ] else if (_selectedOrderType == OrderType.dineIn &&
                  widget.preselectedTableId != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminTheme.success.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AdminTheme.success.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.table_restaurant, color: AdminTheme.success),
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
                const SizedBox(height: 20),
              ] else if (_selectedOrderType == OrderType.parcel) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
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
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      ((_selectedOrderType == OrderType.dineIn &&
                              _selectedTableId == null &&
                              widget.preselectedTableId == null) ||
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
                              ? 'Select Items'
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
      if (widget.autoStart) Navigator.pop(context);
      return;
    }
    final ok = await _createOrder(selectedItems);
    if (!mounted) return;
    if (widget.autoStart) {
      Navigator.pop(context);
      return;
    }
    if (ok) Navigator.pop(context);
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
        padding: const EdgeInsets.symmetric(vertical: 14),
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
            const SizedBox(height: 6),
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
      await _createOrderStatic(
        context,
        items: items,
        tenantId: widget.tenantId,
        tableId: _selectedOrderType == OrderType.parcel
            ? null
            : (_selectedTableId ?? widget.preselectedTableId),
        tableName: _selectedOrderType == OrderType.parcel
            ? null
            : (_selectedTableName ?? widget.preselectedTableName),
        guestCount: _guestCount,
        customerName: _customerName,
        customerPhone: _customerPhone,
      );
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  static double _resolveTaxRateStatic(OrdersProvider ordersProvider) {
    final settingsRate =
        (ordersProvider.tenantSettings['taxRate'] as num?)?.toDouble();
    if (settingsRate != null && settingsRate >= 0) return settingsRate;
    return 0.18;
  }

  static Future<void> _createOrderStatic(
    BuildContext context, {
    required List<model.OrderItem> items,
    required String tenantId,
    String? tableId,
    String? tableName,
    int guestCount = 0,
    String? customerName,
    String? customerPhone,
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
      customerName: customerName ?? (isParcel ? 'Guest' : 'Walk-in'),
      customerPhone: customerPhone,
      captainName: auth.userName ?? 'Staff',
      type: isParcel ? 'parcel' : 'dineIn',
      guestCount: guestCount,
    );

    await ordersProvider.createOrder(newOrder);

    if (!isParcel && tableId != null) {
      try {
        final table = tablesProvider.tables.firstWhere((t) => t.id == tableId);
        await tablesProvider.updateTable(
          table.copyWith(
            status: TableStatus.occupied,
            isAvailable: false,
            isOccupied: true,
            occupiedAt: DateTime.now(),
          ),
        );
      } catch (_) {}
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order created successfully'),
          backgroundColor: AdminTheme.success,
        ),
      );
    }
  }
}
