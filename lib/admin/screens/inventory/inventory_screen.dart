import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/procurement_provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../../models/inventory_item.dart';
import '../../../models/inventory_log.dart';
import '../../../models/vendor.dart';
import '../../../models/purchase_order.dart';
import '../../../models/low_stock_alert.dart';
import '../../theme/admin_theme.dart';
import 'package:scan_serve/utils/screen_scale.dart';
import 'package:url_launcher/url_launcher.dart';

class InventoryScreen extends StatefulWidget {
  final String tenantId;
  const InventoryScreen({super.key, required this.tenantId});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1100;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer2<InventoryProvider, ProcurementProvider>(
        builder: (context, provider, procurement, _) {
          if (provider.isLoading || procurement.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AdminTheme.primaryColor),
            );
          }

          procurement.syncLowStockAlerts(provider.rawItems);

          return Padding(
            padding: EdgeInsets.all(isMobile ? 12.w : 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, provider, isMobile),
                Expanded(
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            if (isMobile) ...[
                              _buildSummaryCards(provider, isMobile),
                              SizedBox(height: 16.h),
                            ],
                            TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              labelColor: AdminTheme.primaryColor,
                              unselectedLabelColor: AdminTheme.secondaryText,
                              indicatorColor: AdminTheme.primaryColor,
                              indicatorWeight: 3.h,
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 12.sp : 14.sp,
                              ),
                              tabs: const [
                                Tab(text: 'Stock Console'),
                                Tab(text: 'Audit History'),
                                Tab(text: 'Vendors'),
                                Tab(text: 'Purchase Orders'),
                                Tab(text: 'Alerts'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    body: isMobile
                        ? SingleChildScrollView(
                            child: Column(
                              children: [
                                SizedBox(height: 16.h),
                                _buildMobileTabContent(provider),
                                SizedBox(height: 24.h),
                                _buildQuickActions(context, provider, isMobile),
                              ],
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    Column(
                                      children: [
                                        _buildFilters(context, provider, false),
                                        SizedBox(height: 24.h),
                                        Expanded(
                                          child: _buildInventoryTable(
                                            context,
                                            provider,
                                          ),
                                        ),
                                      ],
                                    ),
                                    _InventoryAuditLogs(),
                                    _VendorsTab(),
                                    _PurchaseOrdersTab(),
                                    _AlertsTab(),
                                  ],
                                ),
                              ),
                              SizedBox(width: 32.w),
                              SizedBox(
                                width: 300.w,
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      _buildSummaryCards(provider, false),
                                      SizedBox(height: 24.h),
                                      _buildQuickActions(
                                        context,
                                        provider,
                                        false,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    InventoryProvider provider,
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventory Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AdminTheme.primaryText,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => provider.refresh(),
                  icon: const Icon(Ionicons.refresh_outline, size: 16),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddIngredientDialog(context, provider),
                  icon: const Icon(Ionicons.add_outline, size: 16),
                  label: const Text('Add New'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventory Management',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.primaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                'Monitor stock levels, track ingredients, and manage audit logs.',
                style: TextStyle(color: AdminTheme.secondaryText, fontSize: 16),
              ),
            ],
          ),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                await provider.refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Inventory data synced with server'),
                    ),
                  );
                }
              },
              icon: const Icon(Ionicons.refresh_outline, size: 18),
              label: const Text('Refresh Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminTheme.primaryText,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileTabContent(InventoryProvider provider) {
    if (_tabController.index == 0) {
      return Column(
        children: [
          _buildFilters(context, provider, true),
          SizedBox(height: 16.h),
          _buildInventoryTable(context, provider),
        ],
      );
    }
    if (_tabController.index == 1) {
      return _InventoryAuditLogs();
    }
    if (_tabController.index == 2) {
      return _VendorsTab();
    }
    if (_tabController.index == 3) {
      return _PurchaseOrdersTab();
    }
    return _AlertsTab();
  }

  Widget _buildFilters(
    BuildContext context,
    InventoryProvider provider,
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: provider.setSearchQuery,
              decoration: const InputDecoration(
                hintText: 'Search ingredients...',
                prefixIcon: Icon(Ionicons.search_outline, size: 20),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterDropdown<String>(
                  label: 'Category',
                  icon: Ionicons.grid_outline,
                  value: provider.selectedCategory,
                  items:
                      [
                            'Meat',
                            'Produce',
                            'Dairy',
                            'Spices',
                            'Bakery',
                            'General',
                          ]
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged: provider.setCategory,
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown<StockStatus>(
                  label: 'Status',
                  icon: Ionicons.list_outline,
                  value: provider.selectedStatus,
                  items: StockStatus.values
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                      )
                      .toList(),
                  onChanged: provider.setStatus,
                ),
              ],
            ),
          ),
        ],
      );
    }
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
                  hintText: 'Search ingredients by name...',
                  prefixIcon: Icon(
                    Ionicons.search_outline,
                    size: 20,
                    color: AdminTheme.secondaryText,
                  ),
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
          items: [
            'Meat',
            'Produce',
            'Dairy',
            'Spices',
            'Bakery',
            'General',
          ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
            style: const TextStyle(
              color: AdminTheme.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTable(
    BuildContext context,
    InventoryProvider provider,
  ) {
    if (provider.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.cube_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No inventory data connected',
              style: TextStyle(color: AdminTheme.secondaryText, fontSize: 18),
            ),
          ],
        ),
      );
    }

    final verticalController = ScrollController();
    final horizontalController = ScrollController();

    final isMobile = MediaQuery.of(context).size.width < 1100;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: horizontalController,
        child: SingleChildScrollView(
          controller: horizontalController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: isMobile ? 800 : 1200,
            child: DataTable(
              headingRowHeight: 56,
              dataRowHeight: 64,
              horizontalMargin: 24,
              columnSpacing: isMobile ? 24 : 56,
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFFFBFBFB),
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    'ITEM NAME',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.secondaryText,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'CATEGORY',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.secondaryText,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'CURRENT STOCK',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.secondaryText,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'LOW STOCK ALERT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.secondaryText,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.secondaryText,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'ACTIONS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.secondaryText,
                    ),
                  ),
                ),
              ],
              rows: provider.items
                  .map((item) => _buildDataRow(context, provider, item))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(
    BuildContext context,
    InventoryProvider provider,
    InventoryItem item,
  ) {
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

    return DataRow(
      cells: [
        DataCell(
          Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.category,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            '${item.currentStock} ${item.unit}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: item.currentStock <= 0
                  ? AdminTheme.critical
                  : AdminTheme.primaryText,
            ),
          ),
        ),
        DataCell(
          Text(
            '${item.lowStockLevel} ${item.unit}',
            style: const TextStyle(
              color: AdminTheme.secondaryText,
              fontSize: 15,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                onPressed: () => _showAdjustDialog(context, provider, item),
                icon: const Icon(
                  Ionicons.create_outline,
                  size: 18,
                  color: AdminTheme.secondaryText,
                ),
                tooltip: 'Adjust Stock',
              ),
              IconButton(
                onPressed: () => _confirmDelete(context, provider, item),
                icon: const Icon(
                  Ionicons.trash_outline,
                  size: 18,
                  color: AdminTheme.critical,
                ),
                tooltip: 'Delete Item',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(InventoryProvider provider, bool isMobile) {
    if (isMobile) {
      return Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'CRITICAL',
              value:
                  '${provider.lowStockItems.length + provider.outOfStockItems.length}',
              icon: Ionicons.information_circle_outline,
              color: AdminTheme.warning,
              isMobile: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              label: 'TOTAL',
              value: '${provider.items.length}',
              icon: Ionicons.cube_outline,
              color: AdminTheme.success,
              isMobile: true,
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _SummaryCard(
          label: 'CRITICAL STOCK',
          value:
              '${provider.lowStockItems.length + provider.outOfStockItems.length} Items',
          icon: Ionicons.information_circle_outline,
          color: AdminTheme.warning,
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          label: 'TOTAL INVENTORY',
          value: '${provider.items.length} Items',
          icon: Ionicons.cube_outline,
          color: AdminTheme.success,
        ),
      ],
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    InventoryProvider provider,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      decoration: BoxDecoration(
        color: AdminTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _ActionButton(
            label: 'Add Ingredient',
            icon: Ionicons.add_circle_outline,
            onTap: () => _showAddIngredientDialog(context, provider),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Add Vendor',
            icon: Ionicons.business_outline,
            onTap: () => _showAddVendorDialog(context),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Create Purchase Order',
            icon: Ionicons.cart_outline,
            onTap: () => _showCreatePoDialog(context),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Generate Report',
            icon: Ionicons.document_text_outline,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    InventoryProvider provider,
    InventoryItem item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ingredient'),
        content: Text(
          'Are you sure you want to delete "${item.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await provider.deleteItem(item.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('${item.name} deleted')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: AdminTheme.critical),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddIngredientDialog(
    BuildContext context,
    InventoryProvider provider,
  ) {
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
          content: Builder(
            builder: (context) {
              final maxWidth = (MediaQuery.of(context).size.width - 48).clamp(
                280.0,
                500.0,
              );
              final maxHeight = MediaQuery.of(context).size.height * 0.7;
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Ingredient Name (Required)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items:
                            [
                                  'Meat',
                                  'Produce',
                                  'Dairy',
                                  'Spices',
                                  'Bakery',
                                  'General',
                                ]
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedCategory = v!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                              ),
                              items: ['kg', 'Liter', 'Units', 'Grams', 'ml']
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setDialogState(() => selectedUnit = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: stockController,
                              decoration: const InputDecoration(
                                labelText: 'Initial Stock',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: reorderController,
                        decoration: const InputDecoration(
                          labelText: 'Low Stock Alert Level',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingredient name is required'),
                    ),
                  );
                  return;
                }
                final initialStock =
                    double.tryParse(stockController.text) ?? -1;
                if (initialStock < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Initial stock must be 0 or greater'),
                    ),
                  );
                  return;
                }

                final item = InventoryItem(
                  id: '',
                  tenantId: widget.tenantId,
                  name: nameController.text.trim(),
                  category: selectedCategory,
                  unit: selectedUnit,
                  currentStock: initialStock,
                  lowStockLevel: double.tryParse(reorderController.text) ?? 10,
                  lastUpdated: DateTime.now(),
                );
                await provider.addItem(
                  item,
                  context.read<AdminAuthProvider>().userName ?? 'Admin',
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add Ingredient'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVendorDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final gstController = TextEditingController();
    final openingController = TextEditingController(text: '0');
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminTheme.cardBackground,
        title: const Text('Add Vendor'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Vendor Name'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: gstController,
                  decoration: const InputDecoration(labelText: 'GSTIN'),
                ),
                TextField(
                  controller: openingController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Opening Balance',
                  ),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final opening =
                  double.tryParse(openingController.text.trim()) ?? 0;
              final vendor = Vendor(
                id: '',
                name: name,
                phone: phoneController.text.trim().isEmpty
                    ? null
                    : phoneController.text.trim(),
                email: emailController.text.trim().isEmpty
                    ? null
                    : emailController.text.trim(),
                gstin: gstController.text.trim().isEmpty
                    ? null
                    : gstController.text.trim(),
                address: addressController.text.trim().isEmpty
                    ? null
                    : addressController.text.trim(),
                openingBalance: opening,
                currentBalance: opening,
                createdAt: DateTime.now(),
              );
              await context.read<ProcurementProvider>().addVendor(vendor);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCreatePoDialog(BuildContext context) {
    final procurement = context.read<ProcurementProvider>();
    final inventory = context.read<InventoryProvider>();
    if (procurement.vendors.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add a vendor first')));
      return;
    }

    String? selectedVendorId = procurement.vendors.first.id;
    DateTime? expectedDate;
    final noteController = TextEditingController();

    final List<_PoLineItem> lines = [_PoLineItem()];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          final vendor = procurement.vendors.firstWhere(
            (v) => v.id == selectedVendorId,
          );
          final total = lines.fold<double>(0, (sum, l) => sum + l.total);

          return AlertDialog(
            backgroundColor: AdminTheme.cardBackground,
            title: const Text('Create Purchase Order'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedVendorId,
                      decoration: const InputDecoration(labelText: 'Vendor'),
                      items: procurement.vendors
                          .map(
                            (v) => DropdownMenuItem(
                              value: v.id,
                              child: Text(v.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedVendorId = value),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 1),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 60),
                                ),
                              );
                              if (picked != null) {
                                setDialogState(() => expectedDate = picked);
                              }
                            },
                            child: Text(
                              expectedDate == null
                                  ? 'Expected Date'
                                  : DateFormat('MMM dd').format(expectedDate!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Total: ₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...lines.asMap().entries.map((entry) {
                      final index = entry.key;
                      final line = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: line.itemId,
                                decoration: const InputDecoration(
                                  labelText: 'Item',
                                ),
                                items: inventory.rawItems
                                    .map(
                                      (i) => DropdownMenuItem(
                                        value: i.id,
                                        child: Text(i.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  final item = inventory.rawItems.firstWhere(
                                    (i) => i.id == value,
                                  );
                                  setDialogState(() {
                                    line.itemId = value;
                                    line.name = item.name;
                                    line.unit = item.unit;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Qty',
                                ),
                                onChanged: (value) => setDialogState(() {
                                  line.quantity = double.tryParse(value) ?? 0;
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                ),
                                onChanged: (value) => setDialogState(() {
                                  line.unitPrice = double.tryParse(value) ?? 0;
                                }),
                              ),
                            ),
                            IconButton(
                              onPressed: lines.length == 1
                                  ? null
                                  : () => setDialogState(
                                      () => lines.removeAt(index),
                                    ),
                              icon: const Icon(Ionicons.trash_outline),
                            ),
                          ],
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            setDialogState(() => lines.add(_PoLineItem())),
                        icon: const Icon(Ionicons.add_outline),
                        label: const Text('Add Item'),
                      ),
                    ),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedVendorId == null) return;
                  final validLines = lines.where((l) => l.isValid).toList();
                  if (validLines.isEmpty) return;

                  final items = validLines
                      .map(
                        (l) => PurchaseOrderItem(
                          itemId: l.itemId!,
                          name: l.name ?? '',
                          unit: l.unit ?? 'pcs',
                          quantity: l.quantity,
                          unitPrice: l.unitPrice,
                        ),
                      )
                      .toList();

                  final total = items.fold<double>(
                    0,
                    (sum, i) => sum + i.total,
                  );
                  final vendor = procurement.vendors.firstWhere(
                    (v) => v.id == selectedVendorId,
                  );

                  final po = PurchaseOrder(
                    id: '',
                    vendorId: vendor.id,
                    vendorName: vendor.name,
                    status: 'draft',
                    items: items,
                    totalAmount: total,
                    createdAt: DateTime.now(),
                    expectedAt: expectedDate,
                    notes: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                  );
                  await procurement.createPurchaseOrder(po);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAdjustDialog(
    BuildContext context,
    InventoryProvider provider,
    InventoryItem item,
  ) {
    final qtyController = TextEditingController();
    InventoryChangeReason selectedReason = InventoryChangeReason.manual;
    String adjustmentMode = 'Add';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Adjust Stock: ${item.name}'),
          content: Builder(
            builder: (context) {
              final maxWidth = (MediaQuery.of(context).size.width - 48).clamp(
                280.0,
                420.0,
              );
              final maxHeight = MediaQuery.of(context).size.height * 0.7;
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Current Stock: ${item.currentStock} ${item.unit}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: adjustmentMode,
                              decoration: const InputDecoration(
                                labelText: 'Action',
                                border: OutlineInputBorder(),
                              ),
                              items: ['Add', 'Remove']
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setDialogState(() => adjustmentMode = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: qtyController,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                hintText: 'e.g. 5, 10',
                                suffixText: item.unit,
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: false,
                                    decimal: true,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<InventoryChangeReason>(
                        value: selectedReason,
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                          border: OutlineInputBorder(),
                        ),
                        items: InventoryChangeReason.values
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedReason = v!),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                double quantity = double.tryParse(qtyController.text) ?? 0;
                if (quantity == 0) return;

                // Force positive then apply mode
                quantity = quantity.abs();
                final double finalChange = adjustmentMode == 'Add'
                    ? quantity
                    : -quantity;

                if (item.currentStock + finalChange < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: Stock cannot be negative.'),
                    ),
                  );
                  return;
                }

                await provider.updateStock(
                  itemId: item.id,
                  quantityChange: finalChange,
                  type: finalChange > 0
                      ? InventoryChangeType.stockIn
                      : InventoryChangeType.stockOut,
                  reason: selectedReason,
                  performedBy:
                      context.read<AdminAuthProvider>().userName ?? 'Admin',
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Stock for ${item.name} updated: ${finalChange > 0 ? "+" : ""}$finalChange ${item.unit}',
                      ),
                    ),
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
                Icon(
                  Ionicons.document_text_outline,
                  size: 64,
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No audit logs yet.',
                  style: TextStyle(color: AdminTheme.secondaryText),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          itemCount: provider.recentLogs.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 32, color: AdminTheme.dividerColor),
          itemBuilder: (context, index) {
            final log = provider.recentLogs[index];
            final isPositive =
                log.type == InventoryChangeType.stockIn ||
                log.type == InventoryChangeType.adjustment &&
                    log.quantityChanged > 0;

            return Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPositive
                        ? AdminTheme.success.withOpacity(0.1)
                        : AdminTheme.critical.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPositive
                        ? Ionicons.arrow_up_outline
                        : Ionicons.arrow_down_outline,
                    color: isPositive
                        ? AdminTheme.success
                        : AdminTheme.critical,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AdminTheme.primaryText,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.type.label,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AdminTheme.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reason: ${log.reason.label} • By: ${log.performedBy} ${log.sourceId != null ? "• Ref: ${log.sourceId}" : ""}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AdminTheme.secondaryText,
                        ),
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
                        color: isPositive
                            ? AdminTheme.success
                            : AdminTheme.critical,
                      ),
                    ),
                    Text(
                      'Stock: ${log.quantityAfter}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminTheme.secondaryText,
                      ),
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
        );
      },
    );
  }
}

class _VendorsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProcurementProvider>(
      builder: (context, provider, _) {
        if (provider.vendors.isEmpty) {
          return Center(
            child: Text(
              'No vendors added yet.',
              style: TextStyle(color: AdminTheme.secondaryText),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              itemCount: provider.vendors.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 24, color: AdminTheme.dividerColor),
              itemBuilder: (context, index) {
                final vendor = provider.vendors[index];
                return Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AdminTheme.primaryColor.withOpacity(
                        0.12,
                      ),
                      child: Icon(
                        Ionicons.business_outline,
                        color: AdminTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vendor.phone ?? vendor.email ?? 'No contact',
                            style: const TextStyle(
                              color: AdminTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Due ₹${vendor.currentBalance.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: vendor.currentBalance > 0
                                ? AdminTheme.critical
                                : AdminTheme.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              _showVendorPaymentDialog(context, vendor),
                          child: const Text('Record Payment'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Supplier Ledger',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            _VendorLedger(),
          ],
        );
      },
    );
  }

  void _showVendorPaymentDialog(BuildContext context, Vendor vendor) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminTheme.cardBackground,
        title: Text('Payment to ${vendor.name}'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              if (amount <= 0) return;
              await context.read<ProcurementProvider>().recordVendorPayment(
                vendorId: vendor.id,
                amount: amount,
                note: noteController.text.trim().isEmpty
                    ? 'Payment'
                    : noteController.text.trim(),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _VendorLedger extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProcurementProvider>(
      builder: (context, provider, _) {
        if (provider.ledger.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No ledger entries yet.',
              style: TextStyle(color: AdminTheme.secondaryText),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          itemCount: provider.ledger.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 16, color: AdminTheme.dividerColor),
          itemBuilder: (context, index) {
            final entry = provider.ledger[index];
            final color = entry.type == 'debit'
                ? AdminTheme.warning
                : AdminTheme.success;
            return Row(
              children: [
                Icon(
                  entry.type == 'debit'
                      ? Ionicons.arrow_up_outline
                      : Ionicons.arrow_down_outline,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(entry.note)),
                Text(
                  '${entry.type == 'debit' ? '+' : '-'}₹${entry.amount.toStringAsFixed(0)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PurchaseOrdersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<ProcurementProvider, InventoryProvider>(
      builder: (context, procurement, inventory, _) {
        if (procurement.purchaseOrders.isEmpty) {
          return Center(
            child: Text(
              'No purchase orders created yet.',
              style: TextStyle(color: AdminTheme.secondaryText),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          itemCount: procurement.purchaseOrders.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 24, color: AdminTheme.dividerColor),
          itemBuilder: (context, index) {
            final po = procurement.purchaseOrders[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'PO #${po.id.substring(0, 8)} • ${po.vendorName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _statusChip(po.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ₹${po.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: po.items
                        .map(
                          (i) => Chip(label: Text('${i.name} x ${i.quantity}')),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (po.status == 'draft')
                        TextButton(
                          onPressed: () => procurement.markPurchaseOrderStatus(
                            po.id,
                            'sent',
                          ),
                          child: const Text('Mark Sent'),
                        ),
                      if (po.status == 'sent')
                        TextButton(
                          onPressed: () async {
                            await procurement.receivePurchaseOrder(
                              po,
                              context.read<AdminAuthProvider>().userName ??
                                  'Admin',
                            );
                          },
                          child: const Text('Receive Stock'),
                        ),
                      if (po.status == 'received')
                        TextButton(
                          onPressed: () => procurement.markPurchaseOrderStatus(
                            po.id,
                            'closed',
                          ),
                          child: const Text('Close'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusChip(String status) {
    Color color = AdminTheme.secondaryText;
    if (status == 'sent') color = AdminTheme.warning;
    if (status == 'received') color = AdminTheme.info;
    if (status == 'closed') color = AdminTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AlertsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProcurementProvider>(
      builder: (context, provider, _) {
        if (provider.alerts.isEmpty) {
          return Center(
            child: Text(
              'No low stock alerts.',
              style: TextStyle(color: AdminTheme.secondaryText),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          itemCount: provider.alerts.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 24, color: AdminTheme.dividerColor),
          itemBuilder: (context, index) {
            final alert = provider.alerts[index];
            final color = alert.status == 'out'
                ? AdminTheme.critical
                : AdminTheme.warning;
            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(Ionicons.alert_outline, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${alert.itemName} (${alert.currentStock} ${alert.unit})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        alert.status == 'out' ? 'Out of stock' : 'Low stock',
                        style: TextStyle(color: color),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await provider.acknowledgeAlert(alert.id);
                  },
                  child: const Text('Acknowledge'),
                ),
                TextButton(
                  onPressed: () => _sendWhatsAppAlert(context, alert, provider),
                  child: const Text('WhatsApp'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendWhatsAppAlert(
    BuildContext context,
    LowStockAlert alert,
    ProcurementProvider provider,
  ) async {
    final phoneController = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminTheme.cardBackground,
        title: const Text('Send WhatsApp Alert'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'WhatsApp Number'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, phoneController.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (phone == null || phone.isEmpty) return;

    final message =
        'Low Stock Alert: ${alert.itemName} is ${alert.status == 'out' ? 'OUT OF STOCK' : 'LOW'} (${alert.currentStock} ${alert.unit}).';
    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      await provider.markWhatsappSent(alert.id);
    }
  }
}

class _PoLineItem {
  String? itemId;
  String? name;
  String? unit;
  double quantity = 0;
  double unitPrice = 0;

  bool get isValid => itemId != null && quantity > 0 && unitPrice >= 0;

  double get total => quantity * unitPrice;
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isMobile;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: isMobile ? 18 : 24),
          ),
          SizedBox(width: isMobile ? 12 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 8 : 10,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.secondaryText,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 26,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          foregroundColor: AdminTheme.primaryText,
          side: const BorderSide(color: AdminTheme.dividerColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
