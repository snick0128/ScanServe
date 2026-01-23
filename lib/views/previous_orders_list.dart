import 'package:flutter/material.dart';
import '../models/order_details.dart';
import 'package:intl/intl.dart';
import 'shimmer_loading.dart';
import '../services/wait_time_service.dart';
import '../theme/app_theme.dart';

class PreviousOrdersList extends StatefulWidget {
  final List<OrderDetails> orders;
  final bool isMobile;
  final bool isTablet;

  const PreviousOrdersList({
    Key? key,
    required this.orders,
    this.isMobile = false,
    this.isTablet = false,
  }) : super(key: key);

  @override
  State<PreviousOrdersList> createState() => _PreviousOrdersListState();
}

class _PreviousOrdersListState extends State<PreviousOrdersList> {
  final WaitTimeService _waitTimeService = WaitTimeService();
  int _totalWaitTime = 0;
  String? expandedOrderId;

  @override
  void initState() {
    super.initState();
    _calculateTotalWaitTime();
  }

  @override
  void didUpdateWidget(PreviousOrdersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orders != widget.orders) {
      _calculateTotalWaitTime();
    }
  }

  void _calculateTotalWaitTime() {
    int totalWaitTime = 0;
    for (final order in widget.orders) {
      if (order.status == OrderStatus.pending ||
          order.status == OrderStatus.preparing) {
        totalWaitTime += order.estimatedWaitTime;
      }
    }
    setState(() {
      _totalWaitTime = totalWaitTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Live Total wait time summary
        StreamBuilder<int>(
          stream: _waitTimeService.getTotalWaitTimeStream(
            widget.orders.isNotEmpty ? widget.orders.first.tenantId : '',
            widget.orders.isNotEmpty ? widget.orders.first.tableId ?? '' : '',
          ),
          builder: (context, snapshot) {
            final currentWaitTime = snapshot.data ?? _totalWaitTime;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 12 : 16,
                vertical: 8,
              ),
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
                child: Padding(
                  padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: widget.isMobile ? 20 : 24,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Total wait time: ${_waitTimeService.formatWaitTime(currentWaitTime)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: widget.isMobile ? 14 : 16,
                            color: AppTheme.primaryText,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Previous orders list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 8 : 16),
          itemCount: widget.orders.length,
          itemBuilder: (context, index) {
            final order = widget.orders[index];
            final isExpanded = order.orderId == expandedOrderId;

            return Card(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      'Order #${order.orderId.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    subtitle: Text(
                      '${DateFormat.jm().format(order.timestamp)} - ${order.status.displayName}',
                      style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${order.total.toInt()}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: AppTheme.secondaryText,
                          ),
                          onPressed: () {
                            setState(() {
                              expandedOrderId = isExpanded ? null : order.orderId;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.quantity}x ${item.name}',
                                    style: TextStyle(color: AppTheme.primaryText, fontSize: 13),
                                  ),
                                  Text(
                                    '₹${item.total.toInt()}',
                                    style: TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(color: AppTheme.borderColor),
                          ),
                          _buildPriceRow('Subtotal', order.subtotal),
                          _buildPriceRow('Tax', order.tax),
                          const Divider(color: AppTheme.borderColor),
                          _buildPriceRow(
                            'Total',
                            order.total,
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppTheme.primaryText : AppTheme.secondaryText,
            ),
          ),
          Text(
            '₹${amount.toInt()}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppTheme.primaryColor : AppTheme.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
