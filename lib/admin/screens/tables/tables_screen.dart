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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(tablesProvider),
              _buildKPIBar(tablesProvider),
              _buildFiltersBar(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  itemCount: groupedTables.length,
                  itemBuilder: (context, index) {
                    final section = groupedTables.keys.elementAt(index);
                    final sectionTables = groupedTables[section]!;
                    return _buildSection(section, sectionTables, ordersProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tables & Sessions',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
          ),
          Row(
            children: [
              Container(
                width: 300,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    hintText: 'Search tables...',
                    prefixIcon: Icon(Ionicons.search_outline, size: 18, color: AdminTheme.secondaryText),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildIconButton(Ionicons.notifications_outline),
              const SizedBox(width: 12),
              _buildIconButton(Ionicons.help_circle_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: AdminTheme.primaryText),
    );
  }

  Widget _buildKPIBar(TablesProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          _buildKPICard('TOTAL TABLES', provider.totalTablesCount.toString()),
          const SizedBox(width: 24),
          _buildKPICard('ACTIVE SESSIONS', provider.activeSessionsCount.toString()),
          const SizedBox(width: 24),
          _buildKPICard('BILL REQUESTS', provider.billRequestsCount.toString()),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    final filters = ['All Tables', 'Vacant', 'Active', 'Bill Requested'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        children: filters.map((f) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ChoiceChip(
            label: Text(f),
            selected: _selectedFilter == f,
            onSelected: (val) => setState(() => _selectedFilter = f),
            selectedColor: AdminTheme.primaryColor,
            labelStyle: TextStyle(
              color: _selectedFilter == f ? Colors.white : AdminTheme.secondaryText,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Colors.white,
            side: BorderSide(color: _selectedFilter == f ? AdminTheme.primaryColor : Colors.grey[200]!),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSection(String title, List<RestaurantTable> tables, OrdersProvider ordersProvider) {
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
              ),
              const Text('Updated just now', style: TextStyle(color: AdminTheme.secondaryText, fontSize: 12)),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            mainAxisExtent: 240, // Increased to accommodate more actions
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
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
      result = result.where((t) => !t.isOccupied && t.status == 'vacant').toList();
    } else if (_selectedFilter == 'Active') {
      result = result.where((t) => t.isOccupied || t.status == 'occupied').toList();
    } else if (_selectedFilter == 'Bill Requested') {
      result = result.where((t) => t.status == 'billRequested').toList();
    }
    return result;
  }
}

class _TableCard extends StatelessWidget {
  final RestaurantTable table;
  final OrdersProvider ordersProvider;

  const _TableCard({required this.table, required this.ordersProvider});

  @override
  Widget build(BuildContext context) {
    final isActive = table.isOccupied || table.status == 'occupied' || table.status == 'billRequested';
    final isBillRequested = table.status == 'billRequested';
    
    // Find items count for this table
    final tableOrders = ordersProvider.orders.where((o) => o.tableId == table.id).toList();
    final itemsCount = tableOrders.fold<int>(0, (sum, o) => sum + o.items.length);

    return Container(
      decoration: BoxDecoration(
        color: isBillRequested ? AdminTheme.primaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBillRequested 
              ? AdminTheme.primaryColor 
              : (isActive ? AdminTheme.primaryColor.withOpacity(0.2) : Colors.grey[100]!),
          width: isBillRequested ? 2 : 1,
          style: isActive ? BorderStyle.solid : BorderStyle.solid, // dashed border if vacant would be cool but complex in vanilla
        ),
        boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
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
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
          ),
          if (isActive) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Ionicons.time_outline, size: 14, color: AdminTheme.secondaryText),
                      const SizedBox(width: 8),
                      Text('${table.getTimeOccupied()} elapsed', style: const TextStyle(fontSize: 13, color: AdminTheme.secondaryText)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Ionicons.cart_outline, size: 14, color: AdminTheme.secondaryText),
                      const SizedBox(width: 8),
                      Text('$itemsCount items ordered', style: const TextStyle(fontSize: 13, color: AdminTheme.secondaryText)),
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
                     Text('Ready for guests', style: TextStyle(color: AdminTheme.secondaryText, fontSize: 12)),
                   ],
                 ),
               ),
             ),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildActionButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    String label = 'VACANT';
    Color color = AdminTheme.secondaryText;
    if (table.status == 'billRequested') {
      label = 'BILL REQUESTED';
      color = AdminTheme.primaryColor;
    } else if (table.isOccupied || table.status == 'occupied') {
      label = 'ACTIVE';
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
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (table.status == 'billRequested') {
      return Row(
        children: [
          _buildReleaseButton(context),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () => _handleAction(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('PAYMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ),
          ),
        ],
      );
    } else if (table.isOccupied || table.status == 'occupied') {
      return Row(
        children: [
          _buildReleaseButton(context),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: () => _handleAction(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[200]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('DETAILS', style: TextStyle(color: AdminTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton(
          onPressed: () => _handleAction(context),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey[200]!),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: Colors.white,
          ),
          child: const Text('OPEN SESSION', style: TextStyle(color: AdminTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      );
    }
  }

  Widget _buildReleaseButton(BuildContext context) {
    return SizedBox(
      height: 44,
      width: 44,
      child: OutlinedButton(
        onPressed: () => _confirmRelease(context),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: AdminTheme.critical,
          side: BorderSide(color: AdminTheme.critical.withOpacity(0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Icon(Ionicons.log_out_outline, size: 20),
      ),
    );
  }

  void _confirmRelease(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Release Table'),
        content: Text('Are you sure you want to end the session for ${table.name}? This will mark all orders as Paid.'),
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
    if (!table.isOccupied && table.status == 'vacant') {
      // Open Session - For now show StaffOrderDialog
       showDialog(
        context: context,
        builder: (context) => StaffOrderDialog(tenantId: context.read<AdminAuthProvider>().tenantId!),
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
