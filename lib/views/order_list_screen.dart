import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scan_serve/models/order_model.dart';
import 'package:scan_serve/utils/snackbar_helper.dart';
import '../controllers/order_controller.dart';
import '../models/order_details.dart';
import '../services/bill_request_service.dart';
import '../services/guest_session_service.dart';
import '../widgets/customer_details_bottom_sheet.dart';
import 'components/order_status_badge.dart';
import '../theme/app_theme.dart';
import 'bill_view.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({Key? key}) : super(key: key);

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final _billRequestService = BillRequestService();
  final _guestSession = GuestSessionService();
  bool _isRequestingBill = false;
  int _selectedTabIndex = 0; // 0 for Current, 1 for Past

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('MY ORDERS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        titleTextStyle: TextStyle(
          color: AppTheme.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.borderColor.withOpacity(0.6),
          ),
        ),
      ),
      body: Consumer<OrderController>(
        builder: (context, orderController, child) {
          final isDineIn = orderController.currentOrderType == OrderType.dineIn;
          
          if (orderController.activeOrders.isEmpty && orderController.pastOrders.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              if (isDineIn) _buildSegmentedFilter(),
              Expanded(
                child: isDineIn 
                    ? _buildDineInContent(orderController)
                    : _buildParcelContent(orderController),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSegmentedFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabButton(0, 'Current Orders'),
          _buildTabButton(1, 'Past Orders'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppTheme.primaryColor : const Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDineInContent(OrderController orderController) {
    final orders = _selectedTabIndex == 0 
        ? orderController.activeOrders 
        : orderController.pastOrders;
    
    final filteredOrders = orders.where((o) => o.type == OrderType.dineIn).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTabIndex == 0 ? Icons.restaurant_outlined : Icons.history_rounded,
              size: 64,
              color: const Color(0xFFE5E5EA),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedTabIndex == 0 ? 'No active orders' : 'No past orders yet',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: const Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 0),
      children: [
        if (_selectedTabIndex == 0) _buildTotalWaitTime(orderController),
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildOrderSection(
            _selectedTabIndex == 0 ? 'ACTIVE PREPARATIONS' : 'COMPLETED ORDERS',
            filteredOrders,
          ),
        ),
      ],
    );
  }

  Widget _buildParcelContent(OrderController orderController) {
    // For parcel, combine both active and past, or just show past as per requirement
    // "for parcel only one section orders all past orders will appear there"
    // We'll show all parcel orders in one list
    final allParcelOrders = [
      ...orderController.activeOrders.where((o) => o.type == OrderType.parcel),
      ...orderController.pastOrders.where((o) => o.type == OrderType.parcel),
    ];
    
    // Sort combined list by date
    allParcelOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (allParcelOrders.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOrderSection('MY PARCEL ORDERS', allParcelOrders),
      ],
    );
  }
  Widget _buildRequestBillButton(OrderController orderController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _isRequestingBill
                      ? null
                      : () => _handleRequestBill(orderController, isCashAtCounter: true),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Cash at Counter',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),

              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isRequestingBill
                      ? null
                      : () => _handleRequestBill(orderController),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
          ],
        ),
      ),
    );
  }

  Future<void> _handleRequestBill(OrderController orderController, {bool isCashAtCounter = false}) async {
    try {
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

      final guestId = await _guestSession.getGuestId();
      final profile = await _guestSession.getGuestProfile();
      
      final hasPending = await _billRequestService.hasPendingBillRequest(
        tenantId: tenantId,
        guestId: guestId,
      );

      if (hasPending) {
        SnackbarHelper.showTopSnackBar(
          context,
          'You already have a pending request',
        );
        return;
      }

      setState(() => _isRequestingBill = true);


      final orderIds = orderController.activeOrders
          .map((order) => order.orderId)
          .toList();
      
      final tableName = orderController.activeOrders.isNotEmpty 
          ? orderController.activeOrders.first.tableName 
          : (tableId != null ? 'Table $tableId' : null);

      await _billRequestService.createBillRequest(
        tenantId: tenantId,
        guestId: guestId,
        customerName: profile?.name ?? 'Guest',
        customerPhone: profile?.phone,
        tableId: tableId,
        tableName: tableName,
        orderIds: orderIds,
        isCashAtCounter: isCashAtCounter,
      );


      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: Column(
              children: [
                Icon(
                  isCashAtCounter ? Icons.store_outlined : Icons.receipt_long_outlined, 
                  color: AppTheme.primaryColor, 
                  size: 48
                ),
                const SizedBox(height: 16),
                Text(
                  isCashAtCounter ? 'Cash at Counter' : 'Bill Requested',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              isCashAtCounter
                  ? 'Please pay at the counter. Admin has been notified of your request.'
                  : 'Bill requested. Please wait for confirmation. A staff member will assist you shortly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BillView(
                        orders: orderController.activeOrders,
                        tableName: tableName,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Got it',
                  style: GoogleFonts.outfit(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showTopSnackBar(
          context,
          'Error: $e',
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.searchBarBackground,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Orders Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t placed any orders yet.\nBrowse the menu and place your first order!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Browse Menu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            'Expected wait time: $totalWaitMinutes minutes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryText,
            letterSpacing: 1.1,
          ),
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppTheme.borderColor),
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
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${widget.order.orderId.substring(0, 8).toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.primaryText,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Placed at ${_formatTime(widget.order.timestamp)}',
                            style: TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 12,
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
                          color: AppTheme.secondaryText,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isExpanded) ...[
                Divider(height: 1, color: AppTheme.borderColor),
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
                    style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.name, style: TextStyle(color: AppTheme.primaryText))),
                  Text(
                    '₹${item.total.toStringAsFixed(0)}',
                    style: TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Divider(color: AppTheme.borderColor),
          _buildPriceRow('Subtotal', widget.order.subtotal),
          _buildPriceRow('Tax', widget.order.tax),
          _buildPriceRow(
            'Total',
            widget.order.total,
            textStyle: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryText, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: AppTheme.secondaryText),
              const SizedBox(width: 4),
              Text(
                'Expected by ${_formatTime(widget.order.estimatedReadyTime)}',
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 13, fontWeight: FontWeight.w500),
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
          Text(label, style: TextStyle(color: AppTheme.secondaryText)),
          Text('₹${amount.toStringAsFixed(0)}', style: textStyle ?? TextStyle(color: AppTheme.primaryText)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
