import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../../models/inventory_item.dart';
import '../../../models/inventory_log.dart';
import '../../theme/admin_theme.dart';

class InventoryScreen extends StatefulWidget {
  final String tenantId;
  const InventoryScreen({super.key, required this.tenantId});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AdminTheme.primaryColor));
          }

          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, provider),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AdminTheme.primaryColor,
                  unselectedLabelColor: AdminTheme.secondaryText,
                  indicatorColor: AdminTheme.primaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Stock Console'),
                    Tab(text: 'Audit History'),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: STOCK CONSOLE
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilters(context, provider),
                          const SizedBox(height: 24),
                          Expanded(child: _buildInventoryTable(context, provider)),
                          const SizedBox(height: 32),
                          _buildSummaryCards(provider),
                        ],
                      ),
                      // TAB 2: AUDIT HISTORY
                      _InventoryAuditLogs(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, InventoryProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Management',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
            ),
            SizedBox(height: 4),
            Text(
              'Monitor stock levels, track ingredients, and manage audit logs.',
              style: TextStyle(color: AdminTheme.secondaryText, fontSize: 16),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                await provider.refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inventory data synced with server')),
                  );
                }
              },
              icon: const Icon(Ionicons.refresh_outline, size: 18),
              label: const Text('Refresh Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminTheme.primaryText,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddIngredientDialog(context, provider),
              icon: const Icon(Ionicons.add_outline, size: 20),
              label: const Text('Add New Ingredient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, InventoryProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: TextField(
                controller: _searchController,
                onChanged: provider.setSearchQuery,
                decoration: const InputDecoration(
                  hintText: 'Search ingredients, SKUs or categories...',
                  prefixIcon: Icon(Ionicons.search_outline, size: 20, color: AdminTheme.secondaryText),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildFilterDropdown<String>(
          label: 'Category',
          icon: Ionicons.grid_outline,
          value: provider.selectedCategory,
          items: ['Meat', 'Produce', 'Dairy', 'Spices', 'Bakery', 'General']
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: provider.setCategory,
        ),
        const SizedBox(width: 16),
        _buildFilterDropdown<StockStatus>(
          label: 'Status',
          icon: Ionicons.list_outline,
          value: provider.selectedStatus,
          items: StockStatus.values
              .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
              .toList(),
          onChanged: provider.setStatus,
        ),
      ],
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AdminTheme.secondaryText),
          const SizedBox(width: 8),
          DropdownButton<T>(
            value: value,
            hint: Text(label, style: const TextStyle(fontSize: 14)),
            underline: const SizedBox(),
            items: [
              DropdownMenuItem<T>(value: null, child: Text('All $label')),
              ...items,
            ],
            onChanged: onChanged,
            style: const TextStyle(color: AdminTheme.primaryText, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTable(BuildContext context, InventoryProvider provider) {
    if (provider.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.cube_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No inventory data connected', style: TextStyle(color: AdminTheme.secondaryText, fontSize: 18)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 56,
          dataRowHeight: 64,
          horizontalMargin: 24,
          columnSpacing: 40,
          headingRowColor: MaterialStateProperty.all(const Color(0xFFFBFBFB)),
          columns: const [
            DataColumn(label: Text('ITEM NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText))),
            DataColumn(label: Text('CATEGORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText))),
            DataColumn(label: Text('CURRENT STOCK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText))),
            DataColumn(label: Text('REORDER LEVEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText))),
            DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText))),
            DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText))),
          ],
          rows: provider.items.map((item) => _buildDataRow(context, provider, item)).toList(),
        ),
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, InventoryProvider provider, InventoryItem item) {
    final status = item.status;
    Color statusColor;
    Color statusBg;

    switch (status) {
      case StockStatus.inStock:
        statusColor = AdminTheme.success;
        statusBg = AdminTheme.success.withOpacity(0.1);
        break;
      case StockStatus.low:
        statusColor = AdminTheme.warning;
        statusBg = AdminTheme.warning.withOpacity(0.1);
        break;
      case StockStatus.out:
        statusColor = AdminTheme.critical;
        statusBg = AdminTheme.critical.withOpacity(0.1);
        break;
    }

    return DataRow(cells: [
      DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(item.category, style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600)),
      )),
      DataCell(Text('${item.currentStock} ${item.unit}', style: TextStyle(
        fontWeight: FontWeight.bold, 
        color: item.currentStock <= 0 ? AdminTheme.critical : AdminTheme.primaryText
      ))),
      DataCell(Text('${item.lowStockLevel} ${item.unit}', style: const TextStyle(color: AdminTheme.secondaryText))),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statusBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(status.label, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      )),
      DataCell(Row(
        children: [
          IconButton(
            onPressed: () => _showAdjustDialog(context, provider, item),
            icon: const Icon(Ionicons.create_outline, size: 18, color: AdminTheme.secondaryText),
          ),
        ],
      )),
    ]);
  }

  Widget _buildSummaryCards(InventoryProvider provider) {
    return Row(
      children: [
        _SummaryCard(
          label: 'CRITICAL STOCK',
          value: '${provider.lowStockItems.length + provider.outOfStockItems.length} Items',
          icon: Ionicons.warning_outline,
          color: AdminTheme.warning,
        ),
        const SizedBox(width: 24),
        _SummaryCard(
          label: 'TOTAL INVENTORY',
          value: '${provider.items.length} Items',
          icon: Ionicons.cube_outline,
          color: AdminTheme.success,
        ),
        const SizedBox(width: 24),
        _SummaryCard(
          label: 'INCOMING ORDERS',
          value: '0 Batches',
          icon: Ionicons.trail_sign_outline,
          color: Colors.blue,
        ),
      ],
    );
  }

  void _showAddIngredientDialog(BuildContext context, InventoryProvider provider) {
    final nameController = TextEditingController();
    final stockController = TextEditingController(text: '0');
    final reorderController = TextEditingController(text: '10');
    String selectedCategory = 'General';
    String selectedUnit = 'kg';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Ingredient'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Ingredient Name')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Meat', 'Produce', 'Dairy', 'Spices', 'Bakery', 'General'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setDialogState(() => selectedCategory = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: ['kg', 'Liter', 'Units', 'Grams', 'ml'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (v) => setDialogState(() => selectedUnit = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Initial Stock'), keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: reorderController, decoration: const InputDecoration(labelText: 'Reorder Level'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final item = InventoryItem(
                  id: '',
                  tenantId: widget.tenantId,
                  name: nameController.text,
                  category: selectedCategory,
                  unit: selectedUnit,
                  currentStock: double.tryParse(stockController.text) ?? 0,
                  lowStockLevel: double.tryParse(reorderController.text) ?? 10,
                  lastUpdated: DateTime.now(),
                );
                await provider.addItem(item, context.read<AdminAuthProvider>().userName ?? 'Admin');
                Navigator.pop(context);
              },
              child: const Text('Add Ingredient'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustDialog(BuildContext context, InventoryProvider provider, InventoryItem item) {
    final qtyController = TextEditingController();
    InventoryChangeReason selectedReason = InventoryChangeReason.manual;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Adjust Stock: ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Stock: ${item.currentStock} ${item.unit}'),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                decoration: InputDecoration(
                  labelText: 'Adjustment Amount (+ / -)',
                  hintText: 'e.g. 5, -2, 10',
                  suffixText: item.unit,
                ),
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<InventoryChangeReason>(
                value: selectedReason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: InventoryChangeReason.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
                onChanged: (v) => setDialogState(() => selectedReason = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final change = double.tryParse(qtyController.text) ?? 0;
                if (change == 0) return;
                
                await provider.updateStock(
                  itemId: item.id,
                  quantityChange: change,
                  type: change > 0 ? InventoryChangeType.stockIn : InventoryChangeType.stockOut,
                  reason: selectedReason,
                  performedBy: context.read<AdminAuthProvider>().userName ?? 'Admin',
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Stock for ${item.name} updated: ${change > 0 ? "+" : ""}$change ${item.unit}')),
                  );
                }
              },
              child: const Text('Save Adjustment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkUpdateDialog(BuildContext context, InventoryProvider provider) {
     // Re-reconcile dialog for all items if needed
  }
}

class _InventoryAuditLogs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        if (provider.recentLogs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Ionicons.document_text_outline, size: 64, color: Colors.grey[200]),
                const SizedBox(height: 16),
                const Text('No audit logs yet.', style: TextStyle(color: AdminTheme.secondaryText)),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[100]!),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: provider.recentLogs.length,
            separatorBuilder: (context, index) => const Divider(height: 32, color: AdminTheme.dividerColor),
            itemBuilder: (context, index) {
              final log = provider.recentLogs[index];
              final isPositive = log.type == InventoryChangeType.stockIn || log.type == InventoryChangeType.adjustment && log.quantityChanged > 0;
              
              return Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isPositive ? AdminTheme.success.withOpacity(0.1) : AdminTheme.critical.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPositive ? Ionicons.arrow_up_outline : Ionicons.arrow_down_outline,
                      color: isPositive ? AdminTheme.success : AdminTheme.critical,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              log.itemName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AdminTheme.primaryText),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                log.type.label,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reason: ${log.reason.label} • By: ${log.performedBy} ${log.sourceId != null ? "• Ref: ${log.sourceId}" : ""}',
                          style: const TextStyle(fontSize: 13, color: AdminTheme.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isPositive ? "+" : ""}${log.quantityChanged}',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: isPositive ? AdminTheme.success : AdminTheme.critical
                        ),
                      ),
                      Text(
                        'Stock: ${log.quantityAfter}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminTheme.secondaryText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM d, h:mm a').format(log.timestamp),
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
