import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/tenant_model.dart';
import '../../../services/tables_service.dart';
import '../../widgets/table_orders_dialog.dart';

class TablesScreen extends StatefulWidget {
  final String tenantId;

  const TablesScreen({super.key, required this.tenantId});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  final TablesService _tablesService = TablesService();
  List<RestaurantTable> _tables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);
    try {
      final tables = await _tablesService.getTables(widget.tenantId);
      setState(() {
        _tables = tables;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tables: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showEditDialog([RestaurantTable? table]) async {
    final isEditing = table != null;
    final nameController = TextEditingController(text: table?.name);
    final capacityController = TextEditingController(
      text: table?.capacity.toString() ?? '4',
    );
    bool isAvailable = table?.isAvailable ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Table' : 'Add Table'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Table Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Available'),
                value: isAvailable,
                onChanged: (val) => setState(() => isAvailable = val),
              ),
            ],
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
                  capacity: int.tryParse(capacityController.text) ?? 4,
                  isAvailable: isAvailable,
                );

                try {
                  if (isEditing) {
                    await _tablesService.updateTable(widget.tenantId, newTable);
                  } else {
                    await _tablesService.addTable(widget.tenantId, newTable);
                  }
                  if (mounted) Navigator.pop(context);
                  _loadTables();
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
        _loadTables();
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
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tables.isEmpty
              ? Center(
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
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _tables.length,
                  itemBuilder: (context, index) {
                    final table = _tables[index];
                    return InkWell(
                      onTap: () {
                        // Show table orders dialog
                        showDialog(
                          context: context,
                          builder: (context) => TableOrdersDialog(
                            tenantId: widget.tenantId,
                            tableId: table.id,
                            tableName: table.name,
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.table_restaurant,
                                    color: table.isAvailable ? Colors.green : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      table.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Capacity: ${table.capacity}'),
                              Text(
                                table.isAvailable ? 'Available' : 'Occupied',
                                style: TextStyle(
                                  color: table.isAvailable ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.qr_code_2),
                                    onPressed: () => _showQRCode(table),
                                    tooltip: 'Show QR Code',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showEditDialog(table),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteTable(table),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
