import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:scan_serve/models/order_model.dart';
import 'package:scan_serve/utils/snackbar_helper.dart';
import '../controllers/order_controller.dart';
import '../models/order_details.dart';
import '../services/bill_request_service.dart';
import '../services/guest_session_service.dart';
import '../widgets/customer_details_bottom_sheet.dart';
import 'components/order_status_badge.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({Key? key}) : super(key: key);

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final _billRequestService = BillRequestService();
  final _guestSession = GuestSessionService();
  bool _isRequestingBill = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('My Orders')),
      body: Consumer<OrderController>(
        builder: (context, orderController, child) {
          // Debug: Print current state
          print('OrderListScreen rebuild - Orders count: ${orderController.activeOrders.length}');

          // Check if there are no orders at all
          final hasNoOrders = orderController.activeOrders.isEmpty;

          if (hasNoOrders) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              _buildTotalWaitTime(orderController),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildOrderSection(
                      'Dine-in Orders',
                      orderController.activeOrders
                          .where((order) => order.type == OrderType.dineIn)
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    _buildOrderSection(
                      'Parcel Orders',
                      orderController.activeOrders
                          .where((order) => order.type == OrderType.parcel)
                          .toList(),
                    ),
                  ],
                ),
              ),
              // Request Bill Button
              if (orderController.activeOrders.isNotEmpty)
                _buildRequestBillButton(orderController),
            ],
          );
        },
      ),
    );
  }

  /// Request Bill Button
  Widget _buildRequestBillButton(OrderController orderController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea( // SafeArea for bottom padding
        top: false,
        child: Row(
          children: [
            // Pay at Counter Button
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Pay at Counter'),
                        content: const Text(
                          'Please proceed to the billing counter to complete your payment.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.deepPurple, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Pay at Counter',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Request Bill Button
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isRequestingBill
                      ? null
                      : () => _handleRequestBill(orderController),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.zero, // Important for Gradient
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: _isRequestingBill
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Request Bill',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle Request Bill button tap
  Future<void> _handleRequestBill(OrderController orderController) async {
    try {
      // Get guest profile
      final profile = await _guestSession.getGuestProfile();
      final session = await _guestSession.getCurrentSession();
      final tenantId = session['tenantId'];
      final tableId = session['tableId'];

      if (tenantId == null) {
        SnackbarHelper.showTopSnackBar(
          context,
          'Unable to request bill - session not found',
        );
        return;
      }

      // Check if already has pending bill request
      final guestId = await _guestSession.getGuestId();
      final hasPending = await _billRequestService.hasPendingBillRequest(
        tenantId: tenantId,
        guestId: guestId,
      );

      if (hasPending) {
        SnackbarHelper.showTopSnackBar(
          context,
          'You already have a pending bill request',
        );
        return;
      }

      // Show customer details bottom sheet
      final customerDetails = await CustomerDetailsBottomSheet.show(
        context: context,
        existingProfile: profile,
        orderType: orderController.activeOrders.first.type,
        title: 'Request Bill',
        submitButtonText: 'Request Bill',
      );

      if (customerDetails == null) return;

      setState(() => _isRequestingBill = true);

      // Create bill request
      final orderIds = orderController.activeOrders
          .map((order) => order.orderId)
          .toList();
      
      final tableName = orderController.activeOrders.isNotEmpty 
          ? orderController.activeOrders.first.tableName 
          : (tableId != null ? 'Table $tableId' : null);

      await _billRequestService.createBillRequest(
        tenantId: tenantId,
        guestId: guestId,
        customerName: customerDetails.name,
        customerPhone: customerDetails.phone,
        tableId: tableId,
        tableName: tableName,
        orderIds: orderIds,
      );

      // Update guest profile
      await _guestSession.updateGuestProfile(
        name: customerDetails.name,
        phone: customerDetails.phone,
      );

      if (mounted) {
        SnackbarHelper.showTopSnackBar(
          context,
          '✅ Bill requested — staff notified',
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showTopSnackBar(
          context,
          'Error requesting bill: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingBill = false);
      }
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Orders Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t placed any orders yet.\nBrowse the menu and place your first order!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Browse Menu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalWaitTime(OrderController controller) {
    final totalWaitMinutes = controller.activeOrders.fold<int>(
      0,
      (sum, order) => sum + order.estimatedWaitTime,
    );

    if (totalWaitMinutes == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Expected wait time: $totalWaitMinutes minutes',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSection(String title, List<OrderDetails> orders) {
    if (orders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...orders.map((order) => _OrderCard(order: order)).toList(),
      ],
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderDetails order;

  const _OrderCard({Key? key, required this.order}) : super(key: key);

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.deepPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Order #${widget.order.orderId.substring(0, 8)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Placed at ${_formatTime(widget.order.timestamp)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        OrderStatusBadge(status: widget.order.status),
                        const SizedBox(height: 8),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 20,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isExpanded) ...[
                const Divider(height: 1),
                _buildOrderDetails(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...widget.order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '${item.quantity}x',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.name)),
                  Text(
                    '₹${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          _buildPriceRow('Subtotal', widget.order.subtotal),
          _buildPriceRow('Tax', widget.order.tax),
          _buildPriceRow(
            'Total',
            widget.order.total,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 16),
              const SizedBox(width: 4),
              Text(
                'Expected by ${_formatTime(widget.order.estimatedReadyTime)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {TextStyle? textStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('₹${amount.toStringAsFixed(2)}', style: textStyle),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
