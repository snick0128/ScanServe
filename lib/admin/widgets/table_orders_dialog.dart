import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart' as model;
import '../../services/bill_service.dart';

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
  final _discountController = TextEditingController(text: '0');
  bool _isGeneratingBill = false;

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tenants')
              .doc(widget.tenantId)
              .collection('tables')
              .doc(widget.tableId)
              .snapshots(),
          builder: (context, tableSnapshot) {
            if (tableSnapshot.hasError) {
              return Center(child: Text('Error: ${tableSnapshot.error}'));
            }

            if (!tableSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final tableData = tableSnapshot.data!.data() as Map<String, dynamic>?;
            final isAvailable = tableData?['isAvailable'] ?? true;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.table_restaurant, 
                      color: isAvailable ? Colors.green : Colors.deepPurple, 
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
                            isAvailable ? 'Vacant' : 'Occupied • Active Orders',
                            style: TextStyle(
                              fontSize: 14,
                              color: isAvailable ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),

                if (isAvailable)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                          SizedBox(height: 16),
                          Text(
                            'Table is Vacant',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No active orders for this table.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
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
                            model.OrderStatus.pending.toString().split('.').last,
                            model.OrderStatus.preparing.toString().split('.').last,
                            model.OrderStatus.ready.toString().split('.').last,
                            model.OrderStatus.served.toString().split('.').last,
                          ])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          final error = snapshot.error.toString();
                          if (error.contains('requires an index') || error.contains('failed-precondition')) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.build_circle_outlined, size: 48, color: Colors.orange),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Database Setup Required',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'A Firestore index is required for this query.',
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    SelectableText(
                                      error,
                                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                const Text('Something went wrong loading orders.'),
                                TextButton(
                                  onPressed: () => setState(() {}),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        List<model.Order> orders;
                        try {
                          orders = snapshot.data!.docs
                              .map((doc) => model.Order.fromFirestore(doc))
                              .toList();
                          // Sort client-side to avoid composite index requirement
                          orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                        } catch (e) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text('Error parsing orders: $e', textAlign: TextAlign.center),
                              ],
                            ),
                          );
                        }

                        if (orders.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No active orders',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: orders.length,
                                itemBuilder: (context, index) {
                                  final order = orders[index];
                                  return _buildOrderCard(order);
                                },
                              ),
                            ),
                            const Divider(height: 24),
                            _buildBillSection(orders),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBillSection(List<model.Order> orders) {
    final subtotal = orders.fold<double>(
      0.0,
      (sum, model.Order order) => sum + order.subtotal,
    );
    final tax = orders.fold<double>(
      0.0,
      (sum, model.Order order) => sum + order.tax,
    );
    final total = orders.fold<double>(
      0.0,
      (sum, model.Order order) => sum + order.total,
    );

    return Column(
      children: [
        _buildBillSummary(subtotal, tax, total),
        const SizedBox(height: 16),
        _buildGenerateBillButton(orders),
      ],
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
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item.quantity}x ${item.name}'),
                  ),
                  Text(
                    '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
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

  Widget _buildBillSummary(double subtotal, double tax, double total) {
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final discountAmount = total * (discount / 100);
    final finalTotal = total - discountAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:'),
              Text('₹${subtotal.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax:'),
              Text('₹${tax.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount (%):'),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discount Amount:', style: TextStyle(color: Colors.green)),
                Text(
                  '-₹${discountAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Final Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${finalTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
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
        label: Text(_isGeneratingBill ? 'Generating Bill...' : 'Generate Bill'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill generated successfully! ID: ${billId.substring(0, 8)}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingBill = false);
      }
    }
  }
}
