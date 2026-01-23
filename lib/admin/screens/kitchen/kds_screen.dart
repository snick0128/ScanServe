import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';
import '../../../models/order.dart' as model;
import '../../../models/tenant_model.dart';
import '../../providers/orders_provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../theme/admin_theme.dart';

class StationConfig {
  final String id;
  final String name;
  final List<String> categories;

  StationConfig({required this.id, required this.name, required this.categories});

  static List<StationConfig> get defaultStations => [
    StationConfig(id: 'hot_kitchen', name: 'HOT KITCHEN', categories: ['Main Course', 'Starters', 'Grill', 'Tandoor', 'Meals']),
    StationConfig(id: 'cold_kitchen', name: 'COLD KITCHEN', categories: ['Salads', 'Desserts', 'Cold Starters']),
    StationConfig(id: 'bar', name: 'BAR STATION', categories: ['Beverages', 'Drinks', 'Mocktails', 'Cocktails']),
    StationConfig(id: 'pass_expo', name: 'PASS / EXPO', categories: []), // Special case for all
  ];
}

class KDSScreen extends StatefulWidget {
  final String tenantId;
  const KDSScreen({super.key, required this.tenantId});

  @override
  State<KDSScreen> createState() => _KDSScreenState();
}

class _KDSScreenState extends State<KDSScreen> {
  Timer? _timer;
  bool _isFullScreen = false;
  StationConfig? _currentStation;
  Map<String, Set<String>> _checkedItems = {}; // orderId -> set of itemIds

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
    
    // Auto-resolve station based on user's kitchenStationId or role
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveStation();
    });
  }

  void _resolveStation() {
    final auth = context.read<AdminAuthProvider>();
    final stationId = auth.kitchenStationId;
    
    print('🔥 KDS: Resolving station for role: ${auth.role}, stationId: $stationId');
    
    if (stationId != null && stationId.isNotEmpty) {
      _currentStation = StationConfig.defaultStations.firstWhere(
        (s) => s.id == stationId,
        orElse: () => StationConfig.defaultStations.first,
      );
    } else {
      // Fallback based on role names
      final role = auth.role?.toLowerCase() ?? '';
      if (role.contains('hot')) _currentStation = StationConfig.defaultStations[0];
      else if (role.contains('cold')) _currentStation = StationConfig.defaultStations[1];
      else if (role.contains('bar')) _currentStation = StationConfig.defaultStations[2];
      else if (role.contains('kitchen')) _currentStation = StationConfig.defaultStations[0];
      else _currentStation = StationConfig.defaultStations[0]; // Default
    }
    
    print('🔥 KDS: Active Station is ${_currentStation?.name}');
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4), // Light KDS background
      body: Consumer2<OrdersProvider, MenuProvider>(
        builder: (context, ordersProvider, menuProvider, _) {
          final stationOrders = _filterOrdersForStation(ordersProvider.currentOrders, menuProvider.allItems);
          
          return Column(
            children: [
              _buildTopStatusBar(stationOrders.length),
              Expanded(
                child: (menuProvider.isLoading && menuProvider.allItems.isEmpty)
                  ? const Center(child: CircularProgressIndicator())
                  : (stationOrders.isEmpty 
                    ? _buildEmptyState()
                    : _buildOrderGrid(stationOrders, menuProvider.allItems)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopStatusBar(int activeCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AdminTheme.dividerColor)),
      ),
      child: Row(
        children: [
          // Station Name & Status
          Row(
            children: [
              Container(
                width: 12, height: 12,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              const Text(
                'MAIN KITCHEN DISPLAY',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AdminTheme.primaryText, letterSpacing: 1),
              ),
            ],
          ),
          const Spacer(),
          
          // Active Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: AdminTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(
              '$activeCount ACTIVE ORDERS',
              style: const TextStyle(color: AdminTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 24),
          
          // Controls
          _buildStatusBarIcon(Ionicons.expand_outline, () {
            setState(() => _isFullScreen = !_isFullScreen);
            // In a real app, toggle platform fullscreen
          }),
        ],
      ),
    );
  }

  Widget _buildStatusBarIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: AdminTheme.dividerColor), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 20, color: AdminTheme.secondaryText),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AdminTheme.dividerColor, width: 2)),
            child: const Icon(Ionicons.restaurant_outline, size: 64, color: AdminTheme.secondaryText),
          ),
          const SizedBox(height: 24),
          const Text('Awaiting orders...', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText)),
          const SizedBox(height: 8),
          const Text('New orders for this station will appear here automatically.', style: TextStyle(color: AdminTheme.secondaryText)),
        ],
      ),
    );
  }

  Widget _buildOrderGrid(List<model.Order> orders, List<MenuItem> menuItems) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      scrollDirection: Axis.horizontal,
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(width: 24),
      itemBuilder: (context, index) => _buildOrderColumn(orders[index], menuItems),
    );
  }

  Widget _buildOrderColumn(model.Order order, List<MenuItem> menuItems) {
    final stationItems = _filterItemsForStation(order.items, menuItems);
    if (stationItems.isEmpty) return const SizedBox.shrink();

    final age = DateTime.now().difference(order.createdAt);
    final isUrgent = age.inMinutes >= 10;
    final isMedium = age.inMinutes >= 5 && age.inMinutes < 10;
    
    final statusColor = isUrgent ? AdminTheme.critical : (isMedium ? Colors.orange : Colors.green);
    final statusLabel = isUrgent ? 'URGENT' : (isMedium ? 'COOKING' : 'NEW');

    final allChecked = stationItems.every((item) => (_checkedItems[order.id]?.contains(item.id) ?? false) || item.status == model.OrderItemStatus.ready);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: statusColor.withOpacity(0.2))),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.tableName ?? 'TAB 0',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AdminTheme.primaryText),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Ionicons.information_circle_outline, size: 20),
                          onPressed: () => _showOrderDetails(order, menuItems),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(age),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
                      child: Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stationItems.length,
              itemBuilder: (context, idx) {
                final item = stationItems[idx];
                final isReady = item.status == model.OrderItemStatus.ready;
                final isChecked = (_checkedItems[order.id]?.contains(item.id) ?? false) || isReady;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: InkWell(
                    onTap: isReady ? null : () => _toggleItemCheck(order.id, item.id),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          color: isChecked ? AdminTheme.success : AdminTheme.secondaryText,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.quantity}× ${item.name}',
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold, 
                                  color: isChecked ? AdminTheme.secondaryText : AdminTheme.primaryText,
                                  decoration: isReady ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              if (item.notes != null && item.notes!.isNotEmpty)
                                Text(item.notes!, style: const TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.bold)),
                              if (item.addons != null && item.addons!.isNotEmpty)
                                ...item.addons!.map((addon) => Text('• $addon', style: const TextStyle(fontSize: 12, color: AdminTheme.secondaryText))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Action Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: allChecked ? () => _markStationReady(order.id, stationItems) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[200],
                  ),
                  child: const Text('MARK AS READY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
                if (_currentStation?.id == 'pass_expo') ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.read<OrdersProvider>().updateOrderStatus(order.id, model.OrderStatus.served),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminTheme.primaryColor,
                      minimumSize: const Size(double.infinity, 44),
                      side: const BorderSide(color: AdminTheme.primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('SERVE ENTIRE ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes);
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _toggleItemCheck(String orderId, String itemId) {
    setState(() {
      _checkedItems.putIfAbsent(orderId, () => {});
      if (_checkedItems[orderId]!.contains(itemId)) {
        _checkedItems[orderId]!.remove(itemId);
      } else {
        _checkedItems[orderId]!.add(itemId);
      }
    });
  }

  Future<void> _markStationReady(String orderId, List<model.OrderItem> items) async {
    final provider = context.read<OrdersProvider>();
    try {
      for (var item in items) {
        if (item.status != model.OrderItemStatus.ready) {
          await provider.updateOrderItemStatus(orderId, item.id, model.OrderItemStatus.ready);
        }
      }
      
      setState(() {
        _checkedItems.remove(orderId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Items marked as READY'), backgroundColor: AdminTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AdminTheme.critical),
        );
      }
    }
  }

  void _showOrderDetails(model.Order order, List<MenuItem> menuItems) {
    final stationItems = _filterItemsForStation(order.items, menuItems);
    final age = DateTime.now().difference(order.createdAt);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Table ${order.tableName}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Ionicons.close)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Order ID: #${order.id.substring(0, 8)}', style: const TextStyle(color: AdminTheme.secondaryText)),
              Text('Order Age: ${_formatDuration(age)}', style: const TextStyle(color: AdminTheme.secondaryText)),
              const SizedBox(height: 24),
              const Text('STATION ITEMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1, color: AdminTheme.secondaryText)),
              const Divider(),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: stationItems.length,
                  itemBuilder: (context, idx) {
                    final item = stationItems[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${item.quantity}× ${item.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: (item.notes != null || (item.addons != null && item.addons!.isNotEmpty)) 
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.notes != null) Text(item.notes!, style: const TextStyle(color: Colors.orange)),
                              if (item.addons != null) ...item.addons!.map((a) => Text('• $a')),
                            ],
                          ) 
                        : null,
                      trailing: Text(item.status.displayName, style: TextStyle(color: item.status == model.OrderItemStatus.ready ? AdminTheme.success : AdminTheme.secondaryText, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {}, // Handle print
                      icon: const Icon(Ionicons.print_outline, size: 18),
                      label: const Text('PRINT KOT'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
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

  void _showStationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Kitchen Station'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: StationConfig.defaultStations.map((station) => ListTile(
            title: Text(station.name),
            selected: _currentStation?.id == station.id,
            onTap: () {
              setState(() => _currentStation = station);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  // LOGIC: Show ALL orders regardless of station
  List<model.Order> _filterOrdersForStation(List<model.Order> orders, List<MenuItem> menuItems) {
    // Only show NEW / PREPARING orders
    final allowedStatuses = [model.OrderStatus.pending, model.OrderStatus.preparing];
    return orders.where((o) => allowedStatuses.contains(o.status)).toList();
  }

  List<model.OrderItem> _filterItemsForStation(List<model.OrderItem> items, List<MenuItem> menuItems) {
    return items; // Return all items
  }
}
