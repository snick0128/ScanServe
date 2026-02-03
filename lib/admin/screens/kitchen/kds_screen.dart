import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';
import 'package:scan_serve/models/order.dart' as model;
import 'package:scan_serve/models/tenant_model.dart';
import 'package:scan_serve/admin/providers/orders_provider.dart';
import 'package:scan_serve/admin/providers/admin_auth_provider.dart';
import 'package:scan_serve/admin/providers/menu_provider.dart';
import 'package:scan_serve/admin/theme/admin_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:scan_serve/utils/screen_scale.dart';

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
  final Set<String> _printedOrders = {};

  // Bug #8: Connectivity & Heartbeat
  DateTime _lastUpdate = DateTime.now();
  bool _isOffline = false;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
    
    // Enable Wakelock to keep KDS screen on
    WakelockPlus.enable();

    // Setup connectivity monitoring
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      setState(() {
        _connectionStatus = results.first;
        if (_connectionStatus == ConnectivityResult.none) {
          _isOffline = true;
        }
      });
    });

    // Heartbeat monitoring (Every 30 seconds)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkHeartbeat();
    });

    // Auto-resolve station
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveStation();
    });
  }

  void _checkHeartbeat() {
    final now = DateTime.now();
    // If no update received for more than 2 minutes, trigger offline warning
    if (now.difference(_lastUpdate).inMinutes >= 2) {
      setState(() => _isOffline = true);
    }
  }

  void _acknowledgeOnline() {
    setState(() {
      _lastUpdate = DateTime.now();
      _isOffline = false;
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
      else _currentStation = StationConfig.defaultStations[3]; // Default to PASS / EXPO (shows all)
    }
    
    print('🔥 KDS: Active Station is ${_currentStation?.name}');
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _heartbeatTimer?.cancel();
    _connectivitySubscription.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4), // Light KDS background
      body: Stack(
        children: [
          Consumer2<OrdersProvider, MenuProvider>(
            builder: (context, ordersProvider, menuProvider, _) {
              // Track last update time from provider
              if (ordersProvider.orders.isNotEmpty || !ordersProvider.isLoading) {
                _lastUpdate = DateTime.now();
              }

              // Final station filtering
              final stationOrders = _filterOrdersForStation(ordersProvider.kdsOrders, menuProvider.allItems);
              
              return Column(
                children: [
                  _buildTopStatusBar(stationOrders.length, ordersProvider),
                  Expanded(
                    child: (menuProvider.isLoading && menuProvider.allItems.isEmpty)
                      ? const Center(child: CircularProgressIndicator())
                      : (stationOrders.isEmpty 
                        ? _buildEmptyState()
                        : ClipRect(child: _buildOrderGrid(stationOrders, menuProvider.allItems))),
                  ),
                  if (ordersProvider.latestNewOrder != null)
                    _buildNewOrderBanner(ordersProvider),
                ],
              );
            },
          ),
          
          // Bug #8: Offline Overlay
          if (_isOffline)
            _buildOfflineOverlay(),
        ],
      ),
    );
  }

  Widget _buildOfflineOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Ionicons.cloud_offline_outline, size: 80, color: AdminTheme.critical),
              const SizedBox(height: 24),
              const Text(
                'CONNECTION LOST',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AdminTheme.critical),
              ),
              const SizedBox(height: 16),
              const Text(
                'The KDS has stopped receiving orders. This may be due to a network failure or session expiry.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: AdminTheme.primaryText),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _acknowledgeOnline,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.critical,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('RETRY & ACKNOWLEDGE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Manual acknowledgement is required to resume kitchen operations.',
                style: TextStyle(fontSize: 12, color: AdminTheme.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatusBar(int activeCount, OrdersProvider provider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AdminTheme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    'KITCHEN DISPLAY',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: AdminTheme.primaryText, letterSpacing: 1),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          
          // Station Display & Selector
          InkWell(
            onTap: _showStationSettings,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                border: Border.all(color: AdminTheme.primaryColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Ionicons.restaurant_outline, size: 16, color: AdminTheme.primaryColor),
                  SizedBox(width: 8.w),
                  Text(
                    _currentStation?.name ?? 'SELECT STATION',
                    style: TextStyle(color: AdminTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13.sp),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Ionicons.chevron_down, size: 14, color: AdminTheme.primaryColor),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          
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

    final hasCheckedItems = _checkedItems[order.id]?.isNotEmpty ?? false;
    final allCheckedReady = stationItems.every((item) => item.status == model.OrderItemStatus.ready);

    return Container(
      width: 320,
      margin: EdgeInsets.only(bottom: 8.h),
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
                          icon: const Icon(Ionicons.information_circle_outline, size: 20, color: AdminTheme.secondaryText),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
                      child: Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Ionicons.print_outline, size: 20, color: AdminTheme.secondaryText),
                      onPressed: () => _printKOT(order),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Print KOT',
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
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: (hasCheckedItems && !allCheckedReady) ? () => _markCheckedItemsReady(order.id, stationItems) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.success,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[200],
                  ),
                  child: Text(
                    allCheckedReady ? 'ALL READY' : 'MARK SELECTED READY', 
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 13.sp)
                  ),
                ),
                if (_currentStation?.id == 'pass_expo' && context.read<AdminAuthProvider>().isAdmin) ...[
                  SizedBox(height: 8.h),
                  ElevatedButton(
                    onPressed: () => context.read<OrdersProvider>().updateOrderStatus(order.id, model.OrderStatus.served),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AdminTheme.primaryColor,
                      minimumSize: Size(double.infinity, 48.h),
                      side: const BorderSide(color: AdminTheme.primaryColor, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Ionicons.checkmark_done_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'SERVE ENTIRE ORDER', 
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.sp, letterSpacing: 0.5)
                        ),
                      ],
                    ),
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


  Future<void> _markCheckedItemsReady(String orderId, List<model.OrderItem> allItems) async {
    final provider = context.read<OrdersProvider>();
    final checkedItemIds = _checkedItems[orderId] ?? {};
    
    if (checkedItemIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items selected'), backgroundColor: AdminTheme.warning),
        );
      }
      return;
    }

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 16),
              Text('Updating items...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      int updatedCount = 0;
      List<String> errors = [];

      for (var item in allItems) {
        if (checkedItemIds.contains(item.id) && item.status != model.OrderItemStatus.ready) {
          try {
            await provider.updateOrderItemStatus(orderId, item.id, model.OrderItemStatus.ready);
            updatedCount++;
            debugPrint('✅ KDS: Marked item ${item.name} as READY');
          } catch (itemError) {
            debugPrint('❌ KDS: Failed to update item ${item.name}: $itemError');
            errors.add(item.name);
          }
        }
      }
      
      // Clear checked items for this order
      setState(() {
        _checkedItems.remove(orderId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        
        if (errors.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ $updatedCount item${updatedCount > 1 ? 's' : ''} marked as READY'),
              backgroundColor: AdminTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠ Updated $updatedCount items, ${errors.length} failed: ${errors.join(', ')}'),
              backgroundColor: AdminTheme.warning,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ KDS: Critical error in _markCheckedItemsReady: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating items: ${e.toString()}'),
            backgroundColor: AdminTheme.critical,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _markCheckedItemsReady(orderId, allItems),
            ),
          ),
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
                      onPressed: () => _printKOT(order), // Handle print
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

  List<model.Order> _filterOrdersForStation(List<model.Order> orders, List<MenuItem> menuItems) {
    var filtered = orders.toList();
    
    if (_currentStation?.id != 'pass_expo') {
      filtered = filtered.where((order) {
        return order.items.any((item) {
          final menuItem = menuItems.firstWhere(
            (mi) => mi.id == item.id || mi.name == item.name, 
            orElse: () => MenuItem(id: '', name: '', category: '', price: 0, description: '', imageUrl: '', isManualAvailable: true, itemType: 'veg')
          );
          if (menuItem.id.isEmpty) return true; // Show in all if unknown
          return _currentStation?.categories.contains(menuItem.category) ?? true;
        });
      }).toList();
    }

    // Robust Sorting logic: 
    // 1. Urgency Score (System score)
    // 2. Age (Oldest first)
    filtered.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });

    return filtered;
  }

  List<model.OrderItem> _filterItemsForStation(List<model.OrderItem> items, List<MenuItem> menuItems) {
    if (_currentStation?.id == 'pass_expo') return items;
    
    return items.where((item) {
      final menuItem = menuItems.firstWhere(
        (mi) => mi.id == item.id || mi.name == item.name, 
        orElse: () => MenuItem(id: '', name: '', category: '', price: 0, description: '', imageUrl: '', isManualAvailable: true, itemType: 'veg')
      );
      if (menuItem.id.isEmpty) return true; // Keep if unknown to be safe
      return _currentStation?.categories.contains(menuItem.category) ?? true;
    }).toList();
  }

  Future<void> _printKOT(model.Order order) async {
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.notoSansDevanagariRegular();
      final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(10),
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('KOT Ticket', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Table: ${order.tableName ?? "N/A"}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text(DateFormat('h:mm a').format(order.createdAt), style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
                pw.Text('Order: #${order.id.substring(0, 8)}', style: const pw.TextStyle(fontSize: 10)),
                if (order.customerName != null)
                   pw.Text('Cust: ${order.customerName}', style: const pw.TextStyle(fontSize: 10)),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 5),
                ...order.items.map((item) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 20,
                          child: pw.Text('${item.quantity}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(item.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                               /* Variants display in KOT */
                              if (item.variantName != null) 
                                pw.Text('(${item.variantName})', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                              if (item.notes != null && item.notes!.isNotEmpty)
                                pw.Text('Note: ${item.notes}', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                              if (item.addons != null && item.addons!.isNotEmpty)
                                ...item.addons!.map((a) => pw.Text('+ $a', style: const pw.TextStyle(fontSize: 10))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                pw.Divider(),
                pw.Center(
                  child: pw.Text('Printed at ${DateFormat('h:mm a').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8)),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'KOT_${order.id.substring(0, 8)}',
      );
    } catch (e) {
      debugPrint('Error printing KOT: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print Error: $e')));
      }
    }
  }

  Widget _buildNewOrderBanner(OrdersProvider provider) {
    final order = provider.latestNewOrder!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      color: AdminTheme.primaryColor,
      child: Row(
        children: [
          Icon(Ionicons.alert_circle, color: Colors.white, size: 24.w),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              'NEW ORDER RECEIVED: Table ${order.tableName} - #${order.id.substring(0, 8)}',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
          ),
          TextButton(
            onPressed: () => provider.clearLatestNewOrder(),
            child: Text('ACKNOWLEDGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, decoration: TextDecoration.underline, fontSize: 13.sp)),
          ),
        ],
      ),
    );
  }
}
