import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../../models/inventory_item.dart';
import '../../../models/inventory_log.dart';

class InventoryScreen extends StatefulWidget {
  final String tenantId;
  const InventoryScreen({super.key, required this.tenantId});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'DASHBOARD & ITEMS'),
            Tab(text: 'AUDIT LOGS'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _InventoryDashboard(),
              _InventoryAuditLogs(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventory Management',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text('Traceable stock tracking for owners'),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddItemDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Primary Item'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final stockController = TextEditingController(text: '0');
    final lowStockController = TextEditingController(text: '5');
    String selectedUnit = 'kg';
    final List<String> units = ['kg', 'Liter', 'Pcs', 'Grams', 'ml', 'Box', 'Tray'];
    final auth = context.read<AdminAuthProvider>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_shopping_cart, color: Colors.blue),
              SizedBox(width: 12),
              Text('Add New Stock Item'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Keep item names generic (e.g., "Milk" instead of "Amul Gold Milk").', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g. Rice, Tomato, Oil',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (val) => setDialogState(() => selectedUnit = val!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: stockController,
                        decoration: const InputDecoration(
                          labelText: 'Initial Stock',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: lowStockController,
                  decoration: const InputDecoration(
                    labelText: 'Low Stock Alert Level',
                    helperText: 'System warns you when stock hits this level',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notifications_active_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (nameController.text.isEmpty) return;
                final item = InventoryItem(
                  id: '',
                  tenantId: widget.tenantId,
                  name: nameController.text,
                  unit: selectedUnit,
                  currentStock: double.tryParse(stockController.text) ?? 0,
                  lowStockLevel: double.tryParse(lowStockController.text) ?? 5,
                  lastUpdated: DateTime.now(),
                );
                context.read<InventoryProvider>().addItem(item, auth.userName ?? 'Admin');
                Navigator.pop(context);
              },
              child: const Text('Create Item'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsRow(provider),
              const SizedBox(height: 32),
              const Text(
                'All Inventory Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildItemsList(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(InventoryProvider provider) {
    return Row(
      children: [
        _StatCard(
          label: 'Total Items',
          value: provider.items.length.toString(),
          color: Colors.blue,
          icon: Icons.inventory_2_outlined,
        ),
        _StatCard(
          label: 'Low Stock',
          value: provider.lowStockItems.length.toString(),
          color: Colors.orange,
          icon: Icons.warning_amber_rounded,
        ),
        _StatCard(
          label: 'Out of Stock',
          value: provider.outOfStockItems.length.toString(),
          color: Colors.red,
          icon: Icons.error_outline_rounded,
        ),
      ],
    );
  }

  Widget _buildItemsList(BuildContext context, InventoryProvider provider) {
    if (provider.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text('No inventory items yet. Add your first item (e.g. Milk, Rice).'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.items.length,
      itemBuilder: (context, index) {
        final item = provider.items[index];
        return _InventoryItemTile(item: item);
      },
    );
  }
}

class _InventoryItemTile extends StatelessWidget {
  final InventoryItem item;
  const _InventoryItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(item.status.color);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.shopping_basket_outlined, color: statusColor),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${item.currentStock} ${item.unit} available'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.status.label,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QuickAdjustButton(item: item, isAdd: false),
            const SizedBox(width: 8),
            _QuickAdjustButton(item: item, isAdd: true),
            const VerticalDivider(),
            IconButton(
              icon: const Icon(Icons.settings_backup_restore),
              tooltip: 'Reconcile (Match Physical Count)',
              onPressed: () => _showReconcileDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showReconcileDialog(BuildContext context) {
    final controller = TextEditingController(text: item.currentStock.toString());
    final auth = context.read<AdminAuthProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reconcile: ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the ACTUAL quantity you counted on the shelf.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Physical Count (${item.unit})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Stock will be REPLACED to match this number, not added to it.',
              style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null) {
                await context.read<InventoryProvider>().reconcileStock(
                  itemId: item.id,
                  actualQuantity: val,
                  performedBy: auth.userName ?? 'Admin',
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inventory updated to match physical stock.')),
                  );
                }
              }
            },
            child: const Text('Confirm Match'),
          ),
        ],
      ),
    );
  }
}

class _QuickAdjustButton extends StatelessWidget {
  final InventoryItem item;
  final bool isAdd;
  const _QuickAdjustButton({required this.item, required this.isAdd});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isAdd ? Colors.green[50] : Colors.red[50],
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showAdjustDialog(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Icon(
            isAdd ? Icons.add : Icons.remove,
            color: isAdd ? Colors.green[700] : Colors.red[700],
            size: 20,
          ),
        ),
      ),
    );
  }

  void _showAdjustDialog(BuildContext context) {
    final controller = TextEditingController();
    final auth = context.read<AdminAuthProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdd ? 'Quick Add: ${item.name}' : 'Stock OUT: ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Quantity to ${isAdd ? 'Add' : 'Remove'} (${item.unit})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text('Reason for change:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: (isAdd 
                ? [InventoryChangeReason.purchase, InventoryChangeReason.manual]
                : [InventoryChangeReason.wastage, InventoryChangeReason.damage, InventoryChangeReason.manual]
              ).map((reason) => ChoiceChip(
                label: Text(reason.label),
                selected: false,
                onSelected: (_) async {
                  final qty = double.tryParse(controller.text) ?? 0;
                  if (qty > 0) {
                    await context.read<InventoryProvider>().updateStock(
                      itemId: item.id,
                      quantityChange: isAdd ? qty : -qty,
                      type: isAdd ? InventoryChangeType.stockIn : InventoryChangeType.stockOut,
                      reason: reason,
                      performedBy: auth.userName ?? 'Admin',
                    );
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryAuditLogs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        if (provider.recentLogs.isEmpty) {
          return const Center(child: Text('No activity logs yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: provider.recentLogs.length,
          itemBuilder: (context, index) {
            final log = provider.recentLogs[index];
            final isPositive = log.type == InventoryChangeType.stockIn;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: Colors.grey[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isPositive ? Colors.green[50] : Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                log.itemName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${isPositive ? '+' : ''}${log.quantityChanged}',
                                style: TextStyle(
                                  color: isPositive ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Reason: ${log.reason.label} • By: ${log.performedBy}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'After: ${log.quantityAfter}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('MMM d, h:mm a').format(log.timestamp),
                          style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.05),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
