import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../../../models/tenant_model.dart';
import '../../../models/order.dart' as order_model;
import '../../providers/tables_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/table_orders_dialog.dart';
import '../../widgets/staff_order_dialog.dart';
import 'package:scan_serve/utils/screen_scale.dart';
import '../../../models/table_status.dart';

class TablesScreen extends StatefulWidget {
  final String tenantId;
  const TablesScreen({super.key, required this.tenantId});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  String _selectedFilter = 'All Tables';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer2<TablesProvider, OrdersProvider>(
        builder: (context, tablesProvider, ordersProvider, _) {
          final isMobile = MediaQuery.of(context).size.width < 900;
          if (tablesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AdminTheme.primaryColor));
          }

          final allTables = tablesProvider.tables;
          var filteredTables = _applyFilters(allTables);

          // Group by section
          final groupedTables = <String, List<RestaurantTable>>{};
          for (final table in filteredTables) {
            final section = table.section;
            groupedTables.putIfAbsent(section, () => []).add(table);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(tablesProvider),
                _buildKPIBar(tablesProvider),
                _buildFiltersBar(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.w : 32.w),
                  itemCount: groupedTables.length,
                  itemBuilder: (context, index) {
                    final section = groupedTables.keys.elementAt(index);
                    final sectionTables = groupedTables[section]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(section, sectionTables, ordersProvider, isMobile),
                        SizedBox(height: 32.h),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: (context.watch<AdminAuthProvider>().isKitchen) ? null : FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => StaffOrderDialog(tenantId: widget.tenantId),
        ),
        icon: const Icon(Ionicons.add, color: Colors.white),
        label: const Text('New Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AdminTheme.primaryColor,
      ),
    );
  }

  Widget _buildHeader(TablesProvider provider) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isAdmin = context.read<AdminAuthProvider>().isAdmin;

    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 32, 24, isMobile ? 16 : 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tables',
                style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
              ),
              if (!isMobile && isAdmin)
                ElevatedButton.icon(
                  onPressed: () => _showManageTablesDialog(context, provider),
                  icon: const Icon(Ionicons.settings_outline, size: 18),
                  label: const Text('Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AdminTheme.primaryText,
                    side: BorderSide(color: Colors.grey[200]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search tables...',
                hintStyle: TextStyle(color: AdminTheme.secondaryText, fontSize: 13.sp),
                prefixIcon: Icon(Ionicons.search_outline, size: 18, color: AdminTheme.secondaryText),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Removed _buildIconButton

  Widget _buildKPIBar(TablesProvider provider) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKPICard('TOTAL', provider.totalTablesCount.toString()),
            const SizedBox(width: 12),
            _buildKPICard('ACTIVE', provider.activeSessionsCount.toString()),
            const SizedBox(width: 12),
            _buildKPICard('BILLS', provider.billRequestsCount.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(String label, String value) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Container(
      width: isMobile ? 120 : 200,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: isMobile ? 24 : 36, fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
        ],
      ),
    );
  }

  Widget _buildFiltersBar() {
    final filters = ['All Tables', 'Vacant', 'Active', 'Pending'];
    final isMobile = MediaQuery.of(context).size.width < 900;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 8),
      child: Row(
        children: filters.map((f) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _selectedFilter == f ? Colors.white : AdminTheme.secondaryText)),
            selected: _selectedFilter == f,
            onSelected: (val) => setState(() => _selectedFilter = f),
            selectedColor: AdminTheme.primaryColor,
            backgroundColor: Colors.white,
            side: BorderSide(color: _selectedFilter == f ? AdminTheme.primaryColor : Colors.grey[200]!),
            showCheckmark: false,
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSection(String title, List<RestaurantTable> tables, OrdersProvider ordersProvider, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
              ),
              const Text('Updated just now', style: TextStyle(color: AdminTheme.secondaryText, fontSize: 13)),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isMobile ? 180 : 300,
            mainAxisExtent: isMobile ? 220 : 240,
            crossAxisSpacing: isMobile ? 12 : 24,
            mainAxisSpacing: isMobile ? 12 : 24,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) => _TableCard(table: tables[index], ordersProvider: ordersProvider),
        ),
      ],
    );
  }

  List<RestaurantTable> _applyFilters(List<RestaurantTable> tables) {
    var result = tables;
    if (_searchQuery.isNotEmpty) {
      result = result.where((t) => 
        t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        t.section.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    if (_selectedFilter == 'Vacant') {
      result = result.where((t) => t.status == TableStatus.available).toList();
    } else if (_selectedFilter == 'Active') {
      result = result.where((t) => t.status == TableStatus.occupied).toList();
    } else if (_selectedFilter == 'Settlement Pending') {
      result = result.where((t) => t.status == TableStatus.billRequested || t.status == TableStatus.paymentPending).toList();
    }

    return result;
  }

  void _showManageTablesDialog(BuildContext context, TablesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Manage Tables'),
          content: Builder(
            builder: (context) {
              final maxWidth = (MediaQuery.of(context).size.width - 48).clamp(300.0, 650.0);
              final maxHeight = MediaQuery.of(context).size.height * 0.7;
              final listHeight = (maxHeight - 120).clamp(200.0, maxHeight);

              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditTableDialog(context, provider, null),
                      icon: const Icon(Ionicons.add_outline),
                      label: const Text('Add New Table'),
                    ),
                    const Divider(height: 32),
                    SizedBox(
                      height: listHeight,
                      child: ListView.builder(
                        itemCount: provider.tables.length,
                        itemBuilder: (context, index) {
                          final table = provider.tables[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text(table.name.replaceAll(RegExp(r'[^0-9]'), ''))),
                            title: Text(table.name),
                            subtitle: Text('${table.section} • Max Pax: ${table.capacity}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Ionicons.create_outline, size: 18),
                                  onPressed: () => _showAddEditTableDialog(context, provider, table),
                                ),
                                IconButton(
                                  icon: const Icon(Ionicons.trash_outline, size: 18, color: AdminTheme.critical),
                                  onPressed: () => provider.deleteTable(table.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  void _showAddEditTableDialog(BuildContext context, TablesProvider provider, RestaurantTable? table) {
    final nameController = TextEditingController(text: table?.name ?? '');
    final sectionController = TextEditingController(text: table?.section ?? 'Main Hall');
    final capacityController = TextEditingController(text: table?.capacity.toString() ?? '4');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(table == null ? 'Add Table' : 'Edit Table'),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: (MediaQuery.of(context).size.width - 48).clamp(280.0, 420.0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Table Name (e.g. Table 1)')),
              TextField(controller: sectionController, decoration: const InputDecoration(labelText: 'Section')),
              TextField(controller: capacityController, decoration: const InputDecoration(labelText: 'Capacity'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              
              final newTable = RestaurantTable(
                id: table?.id ?? 'table_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text,
                section: sectionController.text,
                capacity: int.tryParse(capacityController.text) ?? 4,
                orderIndex: table?.orderIndex ?? provider.tables.length,
                isOccupied: table?.isOccupied ?? false,
                isAvailable: table?.isAvailable ?? true,
                status: table?.status ?? TableStatus.available,
              );
              
              if (table == null) {
                await provider.addTable(newTable);
              } else {
                await provider.updateTable(newTable);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final RestaurantTable table;
  final OrdersProvider ordersProvider;

  const _TableCard({required this.table, required this.ordersProvider});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isActive = table.status == TableStatus.occupied || 
                     table.status == TableStatus.billRequested ||
                     table.status == TableStatus.paymentPending;
    final isSettlementPending = table.status == TableStatus.billRequested || table.status == TableStatus.paymentPending;
    final isBillRequested = table.status == TableStatus.billRequested;
    final isPaymentPending = table.status == TableStatus.paymentPending;

    // Find items count for this table
    final tableOrders = ordersProvider.orders.where((o) => o.tableId == table.id).toList();
    final itemsCount = tableOrders.fold<int>(0, (sum, o) => sum + o.items.length);

    return Container(
      decoration: BoxDecoration(
        color: isSettlementPending ? (isBillRequested ? AdminTheme.primaryColor.withOpacity(0.05) : Colors.orange.withOpacity(0.05)) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBillRequested 
              ? AdminTheme.primaryColor 
              : (isPaymentPending ? Colors.orange : (isActive ? AdminTheme.primaryColor.withOpacity(0.2) : Colors.grey[100]!)),
          width: isSettlementPending ? 2 : 1,
        ),
        boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: isMobile ? 32 : 40,
                  height: isMobile ? 32 : 40,
                  decoration: BoxDecoration(
                    color: isActive ? AdminTheme.primaryColor : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      table.name.replaceAll(RegExp(r'[^0-9]'), ''),
                      style: TextStyle(
                        color: isActive ? Colors.white : AdminTheme.secondaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 18 : 22,
                      ),
                    ),
                  ),
                ),
                Flexible(child: _buildStatusBadge(isMobile)),
              ],
            ),
          ),
          if (isActive) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Ionicons.time_outline, size: 12, color: AdminTheme.secondaryText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${table.getTimeOccupied()} elapsed', 
                          style: TextStyle(fontSize: isMobile ? 12 : 14, color: AdminTheme.secondaryText),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Ionicons.cart_outline, size: 12, color: AdminTheme.secondaryText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('$itemsCount items', 
                          style: TextStyle(fontSize: isMobile ? 12 : 14, color: AdminTheme.secondaryText),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
             const Expanded(
               child: Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Ionicons.restaurant_outline, color: Color(0xFFE0E0E0), size: 24),
                     SizedBox(height: 4),
                     Text('Ready', style: TextStyle(color: AdminTheme.secondaryText, fontSize: 12)),
                   ],
                 ),
               ),
             ),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildActionButton(context, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isMobile) {
    String label = 'VAC';
    Color color = AdminTheme.secondaryText;
    if (table.status == TableStatus.billRequested) {
      label = isMobile ? 'BILL' : 'BILL REQ';
      color = AdminTheme.primaryColor;
    } else if (table.status == TableStatus.paymentPending) {
      label = isMobile ? 'PAY' : 'PENDING';
      color = Colors.orange;
    } else if (table.status == TableStatus.occupied) {
      label = 'ACT';
      color = AdminTheme.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: isMobile ? 8 : 10, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool isMobile) {
    if (table.status == TableStatus.billRequested) {
      return Row(
        children: [
          if (context.read<AdminAuthProvider>().isAdmin || context.read<AdminAuthProvider>().isCaptain) ...[
            _buildReleaseButton(context, isMobile),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: SizedBox(
              height: isMobile ? 36 : 44,
              child: ElevatedButton(
                onPressed: () => _handleAction(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.zero,
                ),
                child: Text('PAYMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isMobile ? 10 : 11)),
              ),
            ),
          ),
        ],
      );
    } else if (table.status == TableStatus.occupied) {
      return Row(
        children: [
          if (context.read<AdminAuthProvider>().isAdmin) ...[
            _buildReleaseButton(context, isMobile),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: SizedBox(
              height: isMobile ? 36 : 44,
              child: OutlinedButton(
                onPressed: () => _handleAction(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[200]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.zero,
                ),
                child: Text('DETAILS', style: TextStyle(color: AdminTheme.primaryText, fontWeight: FontWeight.bold, fontSize: isMobile ? 10 : 11)),
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        height: isMobile ? 36 : 44,
      child: OutlinedButton(
        onPressed: () => _handleAction(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[200]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
          padding: EdgeInsets.zero,
        ),
        child: Text('OPEN', style: TextStyle(color: AdminTheme.primaryText, fontWeight: FontWeight.bold, fontSize: isMobile ? 10 : 12)),
      ),
      );
    }
  }

  Widget _buildReleaseButton(BuildContext context, bool isMobile) {
    return Tooltip(
      message: 'Emergency release',
      child: SizedBox(
        height: isMobile ? 36 : 44,
        width: isMobile ? 36 : 44,
        child: OutlinedButton(
          onPressed: () => _confirmRelease(context),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: AdminTheme.critical,
            side: BorderSide(color: AdminTheme.critical.withOpacity(0.2)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Icon(Ionicons.log_out_outline, size: isMobile ? 16 : 20),
        ),
      ),
    );
  }

  void _confirmRelease(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Release Table'),
        content: Text('Are you sure you want to end the session for ${table.name}? This will cancel all active orders and free the table.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AdminTheme.critical),
            child: const Text('RELEASE TABLE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<TablesProvider>().releaseTable(table.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${table.name} released successfully'), backgroundColor: AdminTheme.success),
        );
      }
    }
  }

  void _handleAction(BuildContext context) {
    if (table.status == TableStatus.available) {
      // Open Session - Skip table selector by passing preselected data
       showDialog(
        context: context,
        builder: (context) => StaffOrderDialog(
          tenantId: context.read<AdminAuthProvider>().tenantId!,
          preselectedTableId: table.id,
          preselectedTableName: table.name,
        ),
      );
    } else {
      // View Details or Process Payment
      showDialog(
        context: context,
        builder: (context) => TableOrdersDialog(
          tenantId: context.read<AdminAuthProvider>().tenantId!,
          tableId: table.id,
          tableName: table.name,
        ),
      );
    }
  }
}
