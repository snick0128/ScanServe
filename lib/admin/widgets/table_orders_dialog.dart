import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/tenant_model.dart';
import '../../models/order.dart' as model;
import '../../services/bill_service.dart';
import '../../services/tables_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/tables_provider.dart';
import '../providers/bills_provider.dart';
import 'menu_selector_dialog.dart';
import '../theme/admin_theme.dart';
import '../../../models/table_status.dart';
import 'package:scan_serve/utils/screen_scale.dart';


class TableOrdersDialog extends StatefulWidget {
  final String tenantId;
  final String tableId;
  final String tableName;

  const TableOrdersDialog({
    super.key,
    required this.tenantId,
    required this.tableId,
    required this.tableName,
  });

  @override
  State<TableOrdersDialog> createState() => _TableOrdersDialogState();
}

class _TableOrdersDialogState extends State<TableOrdersDialog> {
  final BillService _billService = BillService();
  final TablesService _tablesService = TablesService();
  final _discountController = TextEditingController(text: '0');
  bool _isGeneratingBill = false;
  Map<String, dynamic>? _generatedBill;

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _startNewOrder() async {
    final auth = context.read<AdminAuthProvider>();
    if (auth.isKitchen) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kitchen staff cannot start orders')));
      return;
    }
    
    final List<model.OrderItem>? selectedItems = await showDialog(
      context: context,
      builder: (context) => MenuSelectorDialog(tenantId: widget.tenantId),
    );

    if (selectedItems != null && selectedItems.isNotEmpty && mounted) {
      try {
        final orderId = const Uuid().v4();
        final subtotal = selectedItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
        final tax = subtotal * 0.05; // 5% tax assumption
        final total = subtotal + tax;

        final newOrder = model.Order(
          id: orderId,
          tenantId: widget.tenantId,
          tableId: widget.tableId,
          tableName: widget.tableName,
          items: selectedItems,
          status: model.OrderStatus.pending,
          subtotal: subtotal,
          tax: tax,
          total: total,
          createdAt: DateTime.now(),
          customerName: 'Walk-in',
          captainName: context.read<AdminAuthProvider>().displayName ?? context.read<AdminAuthProvider>().user?.email,
          captainId: context.read<AdminAuthProvider>().user?.uid,
        );

        await context.read<OrdersProvider>().createOrder(newOrder);
        
        final tablesProvider = context.read<TablesProvider>();
        final table = tablesProvider.tables.firstWhere((t) => t.id == widget.tableId);
        final updatedTable = table.copyWith(
          status: TableStatus.occupied,
          isAvailable: false,
          isOccupied: true,
          occupiedAt: DateTime.now(),
        );
        await tablesProvider.updateTable(updatedTable);

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order started successfully'), backgroundColor: Colors.green));
           setState(() {}); // refresh
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start order: $e')));
      }
    }
  }

  Future<void> _addItemsToOrder(String orderId) async {
    final List<model.OrderItem>? selectedItems = await showDialog(
      context: context,
      builder: (context) => MenuSelectorDialog(tenantId: widget.tenantId),
    );

    if (selectedItems != null && selectedItems.isNotEmpty && mounted) {
      try {
        final provider = context.read<OrdersProvider>();
        final auth = context.read<AdminAuthProvider>();
        final captainName = auth.displayName ?? auth.user?.email;
        for (final item in selectedItems) {
           await provider.addOrderItem(orderId, item.copyWith(captainName: captainName));
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Items added successfully'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add items: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.all(isMobile ? 12 : 32),
      child: Container(
        width: isMobile ? double.infinity : MediaQuery.of(context).size.width * 0.8,
        height: isMobile ? double.infinity : MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Consumer2<TablesProvider, OrdersProvider>(
          builder: (context, tablesProvider, ordersProvider, _) {
            final hasActiveOrders = ordersProvider.orders.any((o) => o.tableId == widget.tableId);
            final tables = tablesProvider.tables;
            final table = tables.firstWhere(
              (t) => t.id == widget.tableId,
              orElse: () => RestaurantTable(id: widget.tableId, name: widget.tableName, capacity: 4),
            );

            final isAvailable = table.isAvailable;
            final isOccupied = table.isOccupied;
            final status = table.status;
            
            // Unified occupied check for Admin UI
            final showAsOccupied = isOccupied || status != TableStatus.available || !isAvailable;
            final isVacant = !showAsOccupied;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                      Icon(
                      Icons.table_restaurant, 
                      color: isVacant ? AdminTheme.success : AdminTheme.primaryColor, 
                      size: 32
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tableName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                            Text(
                            isVacant ? 'Vacant' : 'Occupied • Active Orders',
                            style: TextStyle(
                              fontSize: 14,
                              color: isVacant ? AdminTheme.success : AdminTheme.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showAsOccupied && !hasActiveOrders && (context.read<AdminAuthProvider>().isAdmin || context.read<AdminAuthProvider>().isCaptain))
                      TextButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Release Table'),
                              content: const Text('Are you sure you want to mark this table as Vacant? This will cancel active orders and end the current session.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: AdminTheme.critical),
                                  child: const Text('RELEASE'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await tablesProvider.releaseTable(widget.tableId);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Table released successfully'))
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.no_meeting_room, color: Colors.red, size: 20),
                        label: const Text('RELEASE', style: TextStyle(color: Colors.red)),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),

                if (_generatedBill != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, size: 80, color: Colors.green),
                          const SizedBox(height: 16),
                          const Text(
                            'Bill Generated!',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Bill ID: #${(_generatedBill!['billId'] as String).length > 8 ? (_generatedBill!['billId'] as String).substring(0, 8) : _generatedBill!['billId']}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 32),
                          const SizedBox(height: 32),
                          Wrap(
                            spacing: 16.w,
                            runSpacing: 16.h,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildActionCard(
                                icon: Icons.print,
                                label: 'Print Bill',
                                color: AdminTheme.primaryColor,
                                onTap: () => _printBill(context, _generatedBill!),
                              ),
                              _buildActionCard(
                                icon: Icons.share,
                                label: 'WhatsApp',
                                color: Colors.green,
                                onTap: () => _shareToWhatsApp(context, _generatedBill!),
                              ),
                              if (context.read<AdminAuthProvider>().isAdmin)
                                _buildActionCard(
                                  icon: Icons.payments,
                                  label: 'Mark Paid (Cash)',
                                  color: AdminTheme.success,
                                  onTap: () => _showPaymentConfirmationDialog(context, ordersProvider.orders.where((o) => o.tableId == widget.tableId && !['completed', 'cancelled'].contains(o.status.name)).toList()),
                                ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close Dialog'),
                          ),
                        ],
                      ),
                    ),
                  )



                else if (isVacant)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                          const SizedBox(height: 16),
                          Text(
                            'Table is Vacant',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _startNewOrder,
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('START NEW ORDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminTheme.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('tenants')
                          .doc(widget.tenantId)
                          .collection('orders')
                          .where('tableId', isEqualTo: widget.tableId)
                          .where('status', whereIn: [
                            model.OrderStatus.pending.name,
                            model.OrderStatus.preparing.name,
                            model.OrderStatus.ready.name,
                            model.OrderStatus.served.name,
                            model.OrderStatus.billRequested.name,
                            model.OrderStatus.paymentPending.name,

                          ])

                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        List<model.Order> orders = [];
                        try {
                          orders = snapshot.data!.docs
                              .map((doc) => model.Order.fromFirestore(doc))
                              .toList();
                          // Sort client-side
                          orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                        } catch (e) {
                          return Center(child: Text('Error parsing orders: $e'));
                        }

                        String? activeOrderId;
                        if (orders.isNotEmpty) {
                            activeOrderId = orders.last.id;
                        }

                        // AGGREGATE STATS FOR THE TABLE
                        final totalSubtotal = orders.fold<double>(0, (sum, o) => sum + o.subtotal);
                        final totalTax = orders.fold<double>(0, (sum, o) => sum + o.tax);
                        final totalTotal = orders.fold<double>(0, (sum, o) => sum + o.total);

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    orders.length > 1 ? 'Table Session (${orders.length} Orders)' : 'Current Order', 
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                                  ),
                                  if (activeOrderId != null)
                                    ElevatedButton.icon(
                                      onPressed: () => _addItemsToOrder(activeOrderId!),
                                      icon: const Icon(Icons.add),
                                      label: const Text('ADD ITEMS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.success, foregroundColor: Colors.white),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: orders.isEmpty 
                                ? const Center(child: Text('No active orders'))
                                : ListView.builder(
                                  itemCount: orders.length + 1, // +1 for the bill section
                                  itemBuilder: (context, index) {
                                    if (index < orders.length) {
                                      final order = orders[index];
                                      return _buildOrderCard(order);
                                    } else {
                                      // LAST ITEM: Bill Section (Scrollable)
                                      if (orders.isNotEmpty && (context.read<AdminAuthProvider>().isAdmin || context.read<AdminAuthProvider>().isCaptain)) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 24, bottom: 80), // bottom padding for fixed bar
                                            child: _buildBillSection(orders),
                                          );
                                      } else if (orders.isNotEmpty) {
                                        return const Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Text(
                                            'Billing restricted for your role. Please contact Admin.',
                                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }
                                  },
                                ),
                            ),
                            // FIXED BOTTOM TOTAL BAR
                            if (orders.isNotEmpty)
                              _buildFixedTotalBar(totalTotal),
                          ],
                        );
                      },
                    ),
                  )

              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBillSection(List<model.Order> orders) {
    return Column(
      children: [
        _buildBillSummary(orders),
        const SizedBox(height: 16),
        _buildGenerateBillButton(orders),
      ],
    );
  }

  Widget _buildFixedTotalBar(double total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AdminTheme.dividerColor)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'FINAL TOTALAMOUNT', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 1)
          ),
          Text(
            '₹${total.toStringAsFixed(2)}', 
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminTheme.primaryColor)
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(model.Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                /* Removed FIRE button as per Requirement 3: Transition is automatic */
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, y • h:mm a').format(order.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (order.customerName != null && order.customerName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Customer: ${order.customerName}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            const Divider(height: 16),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('${item.quantity}x ${item.name}'),
                      ),
                      if (item.status != 'served' && (context.read<AdminAuthProvider>().isAdmin || context.read<AdminAuthProvider>().isCaptain))
                        TextButton(
                          onPressed: () => context.read<OrdersProvider>().markItemAsServed(order.id, item.id),
                          child: const Text('SERVE', style: TextStyle(fontSize: 11)),
                        ),
                      Text(
                        '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (order.status == model.OrderStatus.pending && (context.read<AdminAuthProvider>().isAdmin || context.read<AdminAuthProvider>().isCaptain))
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.red),
                          onPressed: () => _handleRemoveItem(order.id, item.id),
                        ),
                      if (context.read<AdminAuthProvider>().isAdmin || context.read<AdminAuthProvider>().isCaptain)
                        IconButton(
                          icon: Icon(item.notes != null ? Icons.note : Icons.note_add_outlined, size: 16, color: Colors.blue),
                          onPressed: () => _showNoteDialog(order.id, item.id, item.notes ?? ''),
                        ),
                    ],
                  ),
                  if (item.notes != null && item.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 4),
                      child: Text(
                        'Chef Note: ${item.notes}',
                        style: const TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                ],
              ),
            )),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '₹${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRemoveItem(String orderId, String itemId) async {
    final provider = context.read<OrdersProvider>();
    final captainPerms = provider.tenantSettings['captainPermissions'] ?? {};
    final requiresApproval = captainPerms['requiresApproval'] ?? false;

    if (context.read<AdminAuthProvider>().isCaptain && requiresApproval) {
      final approved = await _showPinDialog();
      if (approved == true) {
        await provider.removeOrderItem(orderId, itemId, supervisorApproved: true);
      }
    } else {
      await provider.removeOrderItem(orderId, itemId);
    }
  }

  Future<bool?> _showPinDialog() {
    final pinController = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supervisor Approval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter supervisor PIN to confirm deletion.'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              // Static PIN for demo purposes or could be fetched from tenant settings
              if (pinController.text == '1234') {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid PIN')),
                );
              }
            },
            child: const Text('APPROVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentConfirmationDialog(BuildContext context, List<model.Order> orders) async {
    final double subtotal = orders.fold(0.0, (sum, o) => sum + o.subtotal);
    final double tax = orders.fold(0.0, (sum, o) => sum + o.tax);
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final discountAmount = subtotal * (discount / 100);
    final currentTotal = subtotal + tax - discountAmount;

    final amountController = TextEditingController(text: currentTotal.toStringAsFixed(2));
    final reasonController = TextEditingController();
    double correctionAmount = 0;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.payments_outlined, color: AdminTheme.success),
              const SizedBox(width: 12),
              const Text('Confirm Settlement'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please verify the final bill amount. You can apply corrections if necessary.'),
                const SizedBox(height: 20),
                const Text('Bill Total Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    final newTotal = double.tryParse(val) ?? currentTotal;
                    setState(() {
                      correctionAmount = newTotal - currentTotal;
                    });
                  },
                ),
                if (correctionAmount != 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: correctionAmount < 0 ? AdminTheme.success.withOpacity(0.05) : AdminTheme.critical.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          correctionAmount < 0 ? Icons.remove_circle_outline : Icons.add_circle_outline,
                          size: 16,
                          color: correctionAmount < 0 ? AdminTheme.success : AdminTheme.critical,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Correction: ₹${correctionAmount.abs().toStringAsFixed(2)} (${correctionAmount < 0 ? "Discount" : "Charge"})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: correctionAmount < 0 ? AdminTheme.success : AdminTheme.critical,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Reason for Correction', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Rounding error, Item returned...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    autofocus: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (correctionAmount != 0 && reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reason is required for amount correction')),
                  );
                  return;
                }

                final ordersProvider = context.read<OrdersProvider>();
                final billsProvider = context.read<BillsProvider>();
                
                try {
                  final finalAmount = double.tryParse(amountController.text) ?? currentTotal;
                  
                  // REQUIRED: Use BillsProvider flow to ensure Bill record is generated
                  // and table is released in one atomic action.
                  final orderIds = orders.map((o) => o.id).toList();
                  final billId = await billsProvider.markAsPaid(widget.tableId, orderIds);

                  if (context.mounted) {
                    Navigator.pop(context); // Close Confirmation Dialog
                    Navigator.pop(context); // Close Table Orders Dialog
                    
                    if (billId != null) {
                      _showSuccessAndSettlementDialog(context, billId);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Table settled successfully'), backgroundColor: AdminTheme.success),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error settling table: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('CONFIRM PAYMENT & RELEASE'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNoteDialog(String orderId, String itemId, String currentNote) async {

    final noteController = TextEditingController(text: currentNote);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item Note'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Add special instructions (spiciness, no onions, etc.)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<OrdersProvider>().addItemNote(orderId, itemId, noteController.text);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(model.OrderStatus status) {
    Color color;
    switch (status) {
      case model.OrderStatus.pending:
        color = Colors.orange;
        break;
      case model.OrderStatus.preparing:
        color = Colors.blue;
        break;
      case model.OrderStatus.ready:
        color = Colors.green;
        break;
      case model.OrderStatus.served:
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.displayName,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildBillSummary(List<model.Order> orders) {
    final subtotal = orders.fold<double>(0.0, (sum, o) => sum + o.subtotal);
    final tax = orders.fold<double>(0.0, (sum, o) => sum + o.tax);

    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final discountAmount = subtotal * (discount / 100);
    final discountedSubtotal = subtotal - discountAmount;
    final taxRate = subtotal > 0 ? (tax / subtotal) : 0.05;
    final newTax = discountedSubtotal * taxRate;
    final finalTotal = discountedSubtotal + newTax;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminTheme.scaffoldBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BILLING DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 1)),
          const SizedBox(height: 20),
          _buildBillRow('Session Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
          _buildBillRow('Tax (Recalculated)', '₹${newTax.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add Discount (%)', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (discount > 0) ...[
            const SizedBox(height: 12),
            _buildBillRow('Discount Savings', '-₹${discountAmount.toStringAsFixed(2)}', color: AdminTheme.success),
          ],
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bill Payable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('₹${finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AdminTheme.primaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AdminTheme.secondaryText)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildGenerateBillButton(List<model.Order> orders) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isGeneratingBill ? null : () => _generateBill(orders),
        icon: _isGeneratingBill
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.receipt_long),
        label: Text(
          _isGeneratingBill ? 'Generating Bill...' : 'Generate Bill',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _generateBill(List<model.Order> orders) async {
    setState(() => _isGeneratingBill = true);

    try {
      final discount = double.tryParse(_discountController.text) ?? 0.0;
      
      final billId = await _billService.generateBill(
        tenantId: widget.tenantId,
        tableId: widget.tableId,
        orders: orders,
        discount: discount,
      );

      final billData = await _billService.getBill(widget.tenantId, billId);

      if (mounted) {
        setState(() {
          _generatedBill = billData;
          _isGeneratingBill = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingBill = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessAndSettlementDialog(BuildContext context, String billId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AdminTheme.success, size: 28),
            SizedBox(width: 12),
            Text('Settlement Complete'),
          ],
        ),
        content: const Text('Table has been released and mark as PAID. Would you like to print the guest receipt now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DONE'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final billData = await _billService.getBill(widget.tenantId, billId);
              if (billData != null && context.mounted) {
                _printBill(context, billData);
              }
            },
            icon: const Icon(Icons.print),
            label: const Text('PRINT RECEIPT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareToWhatsApp(BuildContext context, Map<String, dynamic> bill) async {
    final phone = bill['customerPhone'];
    final billId = bill['billId'] ?? 'Unknown';
    final total = (bill['finalTotal'] ?? 0).toDouble();
    final tableId = bill['tableId'] ?? 'Unknown';

    String message = "Hello! Here is your bill summary from ScanServe:\n\n"
        "Bill ID: #$billId\n"
        "Table: $tableId\n"
        "Total Amount: ₹${total.toStringAsFixed(2)}\n\n"
        "Thank you for dining with us!";

    if (phone == null || phone.toString().isEmpty) {
      final result = await _showPhonePrompt(context);
      if (result != null && result.isNotEmpty) {
        _launchWhatsApp(result, message);
      }
    } else {
      _launchWhatsApp(phone.toString(), message);
    }
  }

  Future<void> _launchWhatsApp(String phone, String message) async {
    String cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!cleanedPhone.startsWith('+') && cleanedPhone.length == 10) {
      cleanedPhone = '91$cleanedPhone';
    }

    final url = "https://wa.me/$cleanedPhone?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<String?> _showPhonePrompt(BuildContext context) async {
    String phoneNumber = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter WhatsApp Number'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'e.g., 919876543210',
            labelText: 'Phone Number with country code',
          ),
          onChanged: (value) => phoneNumber = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, phoneNumber),
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _printBill(BuildContext context, Map<String, dynamic> bill) async {
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.notoSansDevanagariRegular();
      final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();

      final billId = bill['billId'] ?? 'Unknown';
      final createdAt = (bill['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final tableId = bill['tableId'] ?? 'Unknown';
      final subtotal = (bill['subtotal'] ?? 0).toDouble();
      final tax = (bill['tax'] ?? 0).toDouble();
      final discount = (bill['discount'] ?? 0).toDouble();
      final discountAmount = (bill['discountAmount'] ?? 0).toDouble();
      final finalTotal = (bill['finalTotal'] ?? 0).toDouble();
      final orderDetails = (bill['orderDetails'] as List<dynamic>? ?? []);

      pdf.addPage(
        pw.Page(
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('ScanServe Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Bill #$billId', style: const pw.TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Date: ${DateFormat('MMM d, y').format(createdAt)}'),
                        pw.Text('Time: ${DateFormat('h:mm a').format(createdAt)}'),
                        pw.Text('Table: $tableId'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Table.fromTextArray(
                  context: context,
                  border: null,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                  },
                  headers: ['Item', 'Qty', 'Price', 'Total'],
                  data: orderDetails.expand((order) {
                    final items = (order['items'] as List<dynamic>? ?? []);
                    return items.map((item) {
                      return [
                        item['name'],
                        item['quantity'].toString(),
                        '${(item['price'] as num).toStringAsFixed(2)}',
                        '${(item['total'] as num).toStringAsFixed(2)}',
                      ];
                    });
                  }).toList(),
                ),
                pw.Divider(),
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('Subtotal: ', style: const pw.TextStyle(fontSize: 14)),
                          pw.Text('${subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
                        ],
                      ),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('Tax: ', style: const pw.TextStyle(fontSize: 14)),
                          pw.Text('${tax.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
                        ],
                      ),
                      if (discount > 0)
                        pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text('Discount ($discount%): ', style: const pw.TextStyle(fontSize: 14, color: PdfColors.green)),
                            pw.Text('-${discountAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14, color: PdfColors.green)),
                          ],
                        ),
                      pw.Divider(),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('Total: ', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                          pw.Text('${finalTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Center(child: pw.Text('Thank you!', style: const pw.TextStyle(fontSize: 12))),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'bill_$billId',
      );
    } catch (e) {
      debugPrint('Error printing: $e');
    }
  }
}
