import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/order.dart' as order_model;
import '../../providers/orders_provider.dart';
import '../../providers/admin_auth_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OrdersScreen extends StatefulWidget {
  final String tenantId;

  const OrdersScreen({super.key, required this.tenantId});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  order_model.OrderStatus? _selectedStatus;
  OrdersProvider? _ordersProvider;
  bool _showFlash = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ordersProvider = context.read<OrdersProvider>();
      _ordersProvider?.initialize(widget.tenantId);
      _ordersProvider?.addListener(_onOrdersChanged);
      _ordersProvider?.addListener(_handleOrderEvents);
    });
  }

  @override
  void dispose() {
    _ordersProvider?.removeListener(_onOrdersChanged);
    _ordersProvider?.removeListener(_handleOrderEvents);
    _searchController.dispose();
    super.dispose();
  }

  void _onOrdersChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleOrderEvents() {
    final provider = context.read<OrdersProvider>();
    if (provider.latestNewOrder != null && mounted) {
      final newOrder = provider.latestNewOrder!;
      _showNewOrderNotification(newOrder);
      _triggerFlash();
      provider.clearLatestNewOrder();
    }
  }

  void _triggerFlash() async {
    setState(() => _showFlash = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _showFlash = false);
  }

  void _showNewOrderNotification(order_model.Order order) {
    final bool isCustomerOrder = order.customerName != null && order.customerName!.isNotEmpty;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEW ORDER: Table ${order.tableName ?? order.tableId ?? "N/A"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Order #${order.id.substring(0, 8)} • ${isCustomerOrder ? "Customer" : "Captain"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.blue[800],
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
               _searchQuery = order.id.substring(0, 8).toLowerCase();
               _searchController.text = _searchQuery;
            });
          },
        ),
      ),
    );
  }

  List<order_model.Order> _filterOrders(List<order_model.Order> orders, {order_model.OrderStatus? status}) {
    var filtered = orders;
    final auth = context.read<AdminAuthProvider>();

    // Role-based filtering: Captains only see assigned tables
    // if (auth.isCaptain && auth.assignedTables.isNotEmpty) {
    //   filtered = filtered.where((order) => auth.assignedTables.contains(order.tableId)).toList();
    // }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (order) =>
                order.id.toLowerCase().contains(_searchQuery) ||
                (order.customerName ?? '').toLowerCase().contains(
                  _searchQuery,
                ) ||
                (order.tableName ?? '').toLowerCase().contains(_searchQuery),
          )
          .toList();
    }

    // Filter by status
    if (status != null) {
      filtered = filtered.where((order) => order.status == status).toList();
    }

    return filtered;
  }

  Future<void> _updateOrderStatus(OrdersProvider provider, String orderId, order_model.OrderStatus status) async {
    try {
      await provider.updateOrderStatus(orderId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order status updated to ${status.displayName}',
            ),
            backgroundColor: _getStatusColor(status),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> _printKOT(order_model.Order order) async {
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.notoSansDevanagariRegular();
      final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80, // Standard KOT width
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('KITCHEN ORDER TICKET',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Order ID: #${order.id.substring(0, 8)}'),
                    pw.Text('Table: ${order.tableName ?? order.tableId ?? "N/A"}'),
                  ],
                ),
                pw.Text('Time: ${DateFormat('hh:mm a').format(order.createdAt)}'),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  border: null,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                  headers: ['Item', 'Qty', 'Note'],
                  data: order.items.map((item) => [
                    item.name,
                    item.quantity.toString(),
                    item.notes ?? '',
                  ]).toList(),
                ),
                pw.Divider(),
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  pw.Text('KITCHEN NOTES:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(order.notes!),
                ],
                pw.SizedBox(height: 20),
                pw.Center(child: pw.Text('---------------------')),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print KOT: $e')),
        );
      }
    }
  }

  Future<void> _showCancelDialog(order_model.Order order, OrdersProvider provider) async {
    final reasonController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this order?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for cancellation (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await provider.cancelOrder(order.id, reasonController.text);
                if (mounted) {
                  Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order has been cancelled'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to cancel order: $e')),
                  );
                }
              }
            },
            child: const Text(
              'YES, CANCEL',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending:
        return Colors.orange;
      case order_model.OrderStatus.preparing:
        return Colors.blue;
      case order_model.OrderStatus.ready:
        return Colors.green;
      case order_model.OrderStatus.served:
      case order_model.OrderStatus.completed:
        return Colors.teal;
      case order_model.OrderStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, provider, _) {
        final allOrders = provider.allOrders;
        final activeOrders = allOrders.where((o) =>
          o.status == order_model.OrderStatus.pending ||
          o.status == order_model.OrderStatus.preparing ||
          o.status == order_model.OrderStatus.ready ||
          o.status == order_model.OrderStatus.served
        ).toList();

        activeOrders.sort((a, b) {
          if (a.urgencyScore != b.urgencyScore) {
            return b.urgencyScore.compareTo(a.urgencyScore);
          }
          return a.createdAt.compareTo(b.createdAt);
        });

        final historyOrders = allOrders.where((o) =>
          o.status == order_model.OrderStatus.completed ||
          o.status == order_model.OrderStatus.cancelled
        ).toList();
        historyOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.grey[50],
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: const Text(
                  'Orders Flow',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.autorenew, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'Auto Flow: ON',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildStatsBar(activeOrders)),
                      SliverToBoxAdapter(child: _buildSearchBar()),
                      SliverToBoxAdapter(child: _buildFilterChips()),
                      if (_selectedStatus != null)
                        _buildSliverOrderList('FILTERED: ${_selectedStatus!.displayName.toUpperCase()}', _filterOrders(allOrders, status: _selectedStatus), provider)
                      else ...[
                        _buildSliverOrderList('LIVE ORDERS (${_filterOrders(activeOrders).length})', _filterOrders(activeOrders), provider),
                        _buildSliverOrderList('RECENT HISTORY', _filterOrders(historyOrders), provider, isHistory: true),
                      ]
                    ],
                  ),
            ),
            if (_showFlash) _buildFlashOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildStatsBar(List<order_model.Order> activeOrders) {
    if (context.read<AdminAuthProvider>().isCaptain) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('PREPARING', activeOrders.where((o) => o.status != order_model.OrderStatus.ready).length, Colors.blue),
          const SizedBox(width: 12),
          _buildStatCard('READY', activeOrders.where((o) => o.status == order_model.OrderStatus.ready).length, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search table or order #...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Orders'),
            selected: _selectedStatus == null,
            onSelected: (selected) {
              setState(() => _selectedStatus = null);
            },
            selectedColor: Colors.blue.withOpacity(0.2),
            checkmarkColor: Colors.blue,
          ),
          const SizedBox(width: 8),
          ...order_model.OrderStatus.values.map((status) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(status.displayName),
                selected: _selectedStatus == status,
                onSelected: (selected) {
                  setState(() => _selectedStatus = selected ? status : null);
                },
                selectedColor: _getStatusColor(status).withOpacity(0.2),
                checkmarkColor: _getStatusColor(status),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSliverOrderList(String title, List<order_model.Order> orders, OrdersProvider provider, {bool isHistory = false}) {
    if (orders.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isHistory ? Colors.grey[600] : (_selectedStatus != null ? _getStatusColor(_selectedStatus!) : Colors.grey[600]),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Opacity(
              opacity: isHistory ? 0.7 : 1.0,
              child: AnimatedOrderCard(
                key: ValueKey(orders[index].id),
                child: _buildCompactOrderCard(orders[index], provider),
              ),
            ),
            childCount: orders.length,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactOrderCard(order_model.Order order, OrdersProvider provider) {
    // 2️⃣ Simple English time (P0)
    final elapsedText = order.elapsedText;
    final isLate = elapsedText.contains('Late');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shadowColor: isLate ? Colors.red.withOpacity(0.4) : Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLate ? Colors.red : _getStatusColor(order.status).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Big Table Name & Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.tableName ?? 'TAKEAWAY',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (order.captainName != null || order.customerName != null)
                      Text(
                        'By: ${order.captainName ?? order.customerName}',
                        style: TextStyle(fontSize: 16, color: Colors.indigo[900], fontWeight: FontWeight.w900),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      elapsedText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isLate ? Colors.red : (elapsedText.contains('Just') ? Colors.green : Colors.grey[700]),
                      ),
                    ),
                    Text(
                      '#${order.id.substring(0, 8)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items List (Expanded by default for kitchen)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: order.items.map((item) => _buildOrderItem(item, order.id, provider)).toList(),
            ),
          ),

          // Global Note
          if (order.notes != null && order.notes!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[800]!, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber[900]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'NOTE: ${order.notes}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.amber[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1, thickness: 1),

          // LARGE HIGH-CONTRAST BUTTONS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (order.status == order_model.OrderStatus.pending)
                  Expanded(
                    child: _buildKitchenButton(
                      label: 'START PREPARING',
                      color: Colors.blue[700]!,
                      icon: Icons.restaurant,
                      onPressed: () => _updateOrderStatus(provider, order.id, order_model.OrderStatus.preparing),
                    ),
                  ),
                if (order.status == order_model.OrderStatus.preparing)
                  Expanded(
                    child: _buildKitchenButton(
                      label: 'MARK READY',
                      color: Colors.green[700]!,
                      icon: Icons.check_circle,
                      onPressed: () => _updateOrderStatus(provider, order.id, order_model.OrderStatus.ready),
                    ),
                  ),
                if (order.status == order_model.OrderStatus.ready)
                  Expanded(
                    child: _buildKitchenButton(
                      label: 'MARK SERVED',
                      color: Colors.teal[700]!,
                      icon: Icons.delivery_dining,
                      onPressed: () => _updateOrderStatus(provider, order.id, order_model.OrderStatus.served),
                    ),
                  ),
                if (order.status == order_model.OrderStatus.served)
                   Expanded(
                    child: _buildKitchenButton(
                      label: 'COLLECT CASH & CLOSE',
                      color: Colors.indigo[800]!,
                      icon: Icons.payments,
                      onPressed: () => provider.markAsPaid(order.id),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKitchenButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
      ),
    );
  }

  /// 4️⃣ Item-level status display and control (P0)
  Widget _buildOrderItem(order_model.OrderItem item, String orderId, OrdersProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        color: item.status == order_model.OrderItemStatus.served ? Colors.green[50] : null,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.quantity}x',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getItemStatusColor(item.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.status.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.deepOrange),
                        ),
                        child: Text(
                          'INSTRUCTION: ${item.notes}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                    if (item.isAddon)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEW ADD-ON',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Item-level status buttons
          if (item.status != order_model.OrderItemStatus.served && item.status != order_model.OrderItemStatus.cancelled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  if (item.status == order_model.OrderItemStatus.pending)
                    Expanded(
                      child: _buildItemStatusButton(
                        'Start Cooking',
                        Colors.blue,
                        () => provider.updateOrderItemStatus(orderId, item.id, order_model.OrderItemStatus.preparing),
                      ),
                    ),
                  if (item.status == order_model.OrderItemStatus.preparing)
                    Expanded(
                      child: _buildItemStatusButton(
                        'Mark Ready',
                        Colors.green,
                        () => provider.updateOrderItemStatus(orderId, item.id, order_model.OrderItemStatus.ready),
                      ),
                    ),
                  if (item.status == order_model.OrderItemStatus.ready)
                    Expanded(
                      child: _buildItemStatusButton(
                        'Mark Served',
                        Colors.teal,
                        () => provider.updateOrderItemStatus(orderId, item.id, order_model.OrderItemStatus.served),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemStatusButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Color _getItemStatusColor(order_model.OrderItemStatus status) {
    switch (status) {
      case order_model.OrderItemStatus.pending:
        return Colors.orange;
      case order_model.OrderItemStatus.preparing:
        return Colors.blue;
      case order_model.OrderItemStatus.ready:
        return Colors.green;
      case order_model.OrderItemStatus.served:
        return Colors.teal;
      case order_model.OrderItemStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildFlashOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.orange.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_active, color: Colors.orange, size: 40),
                SizedBox(width: 20),
                Text(
                  'NEW ORDER ALERT!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.orange[900],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class AnimatedOrderCard extends StatefulWidget {
  final Widget child;

  const AnimatedOrderCard({super.key, required this.child});

  @override
  State<AnimatedOrderCard> createState() => _AnimatedOrderCardState();
}

class _AnimatedOrderCardState extends State<AnimatedOrderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.05), // Slide down slightly
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
