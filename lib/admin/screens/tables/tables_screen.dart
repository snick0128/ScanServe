import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../../models/tenant_model.dart';
import '../../../services/tables_service.dart';
import '../../widgets/table_orders_dialog.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/tables_provider.dart';

class TablesScreen extends StatefulWidget {
  final String tenantId;

  const TablesScreen({super.key, required this.tenantId});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  final TablesService _tablesService = TablesService();

  Future<void> _showEditDialog([RestaurantTable? table]) async {
    final isEditing = table != null;
    final nameController = TextEditingController(text: table?.name);
    final sectionController = TextEditingController(text: table?.section ?? 'General');
    final capacityController = TextEditingController(
      text: table?.capacity.toString() ?? '4',
    );
    bool isAvailable = table?.isAvailable ?? true;
    String status = table?.status ?? 'available';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Table' : 'Add Table'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Table Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sectionController,
                  decoration: const InputDecoration(labelText: 'Section (e.g. Indoor, Rooftop)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: capacityController,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'available', child: Text('Available')),
                    DropdownMenuItem(value: 'occupied', child: Text('Occupied')),
                    DropdownMenuItem(value: 'billRequested', child: Text('Bill Requested')),
                  ],
                  onChanged: (val) => setState(() {
                    status = val!;
                    if (status == 'occupied' || status == 'billRequested') {
                      isAvailable = false;
                    } else if (status == 'available') {
                      isAvailable = true;
                    }
                  }),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Available'),
                  value: isAvailable,
                  onChanged: (val) => setState(() {
                    isAvailable = val;
                    if (isAvailable) {
                      status = 'available';
                    } else if (status == 'available') {
                      status = 'occupied';
                    }
                  }),
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
                final newTable = RestaurantTable(
                  id: table?.id ?? const Uuid().v4(),
                  name: nameController.text,
                  section: sectionController.text,
                  capacity: int.tryParse(capacityController.text) ?? 4,
                  isAvailable: isAvailable,
                  status: status,
                  isOccupied: status == 'occupied' || status == 'billRequested',
                  currentSessionId: (status == 'occupied' || status == 'billRequested') ? table?.currentSessionId : null,
                  occupiedAt: status == 'occupied' || status == 'billRequested' 
                    ? (table?.occupiedAt ?? DateTime.now())
                    : null,
                  orderIndex: isEditing ? table!.orderIndex : context.read<TablesProvider>().tables.length,
                );

                try {
                  if (isEditing) {
                    await context.read<TablesProvider>().updateTable(newTable);
                  } else {
                    await _tablesService.addTable(widget.tenantId, newTable);
                  }
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving table: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTable(RestaurantTable table) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Table'),
        content: Text('Are you sure you want to delete ${table.name}?'),
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
        await _tablesService.deleteTable(widget.tenantId, table.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting table: $e')),
          );
        }
      }
    }
  }

  void _showQRCode(RestaurantTable table) {
    // Generate URL for customer app
    final qrUrl = 'https://scan-serve.web.app/${widget.tenantId}/${table.id}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code - ${table.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2, size: 200),
                  const SizedBox(height: 16),
                  Text(
                    'Scan to order from ${table.name}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              qrUrl,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color _getStatusColor(RestaurantTable table) {
      if (table.isOccupied || table.status == 'occupied') return Colors.red;
      if (table.status == 'billRequested') return Colors.orange;
      if (!table.isAvailable) return Colors.grey;
      return Colors.green;
    }

    String _getStatusLabel(RestaurantTable table) {
      if (table.isOccupied || table.status == 'occupied') return 'Occupied';
      if (table.status == 'billRequested') return 'Bill Requested';
      if (!table.isAvailable) return 'Unavailable';
      return 'Available';
    }

    return Scaffold(
      floatingActionButton: context.watch<AdminAuthProvider>().isAdmin 
          ? FloatingActionButton.extended(
              onPressed: () => _showEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Table'),
            )
          : null,
      body: Consumer<TablesProvider>(
        builder: (context, tablesProvider, _) {
          if (tablesProvider.isLoading) {
             return const Center(child: CircularProgressIndicator());
          }

          final tables = tablesProvider.tables;
          // Group by section
          final groupedTables = <String, List<RestaurantTable>>{};
          for (final table in tables) {
            final section = table.section ?? 'General';
            groupedTables.putIfAbsent(section, () => []).add(table);
          }

          if (tables.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.table_restaurant, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No tables yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showEditDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Table'),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groupedTables.length,
                itemBuilder: (context, sectionIndex) {
                  final section = groupedTables.keys.elementAt(sectionIndex);
                  final sectionTables = groupedTables[section]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 24, 16, 16),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              section.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${sectionTables.length})',
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isMobile ? 200 : 280,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 200, // Fixed height prevents vertical cut-offs
                        ),
                        itemCount: sectionTables.length,
                        itemBuilder: (context, index) {
                          final table = sectionTables[index];
                          final statusColor = _getStatusColor(table);
                          
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => TableOrdersDialog(
                                    tenantId: widget.tenantId,
                                    tableId: table.id,
                                    tableName: table.name,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.table_restaurant, color: statusColor, size: 20),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _getStatusLabel(table),
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      table.name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Capacity: ${table.capacity}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                    if (table.isOccupied || table.status == 'occupied' || table.status == 'billRequested') ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              table.getTimeOccupied(),
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.qr_code_2, size: 18),
                                          onPressed: () => _showQRCode(table),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                        ),
                                        if (context.read<AdminAuthProvider>().isAdmin) ...[
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            onPressed: () => _showEditDialog(table),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(4),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            onPressed: () => _deleteTable(table),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(4),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
