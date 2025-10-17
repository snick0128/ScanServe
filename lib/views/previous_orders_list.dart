import 'package:flutter/material.dart';
import '../models/order_details.dart';
import 'package:intl/intl.dart';
import 'shimmer_loading.dart';
import '../services/wait_time_service.dart';

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
        // Live Total wait time summary with real-time updates
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
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: widget.isMobile ? 20 : 24,
                        color: _waitTimeService.getWaitTimeColor(currentWaitTime),
                      ),
                      SizedBox(width: widget.isMobile ? 6 : 8),
                      Expanded(
                        child: Text(
                          'Total wait time: ${_waitTimeService.formatWaitTime(currentWaitTime)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: widget.isMobile ? 14 : 16,
                            color: _waitTimeService.getWaitTimeColor(currentWaitTime),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.isMobile ? 8 : 12,
                          vertical: widget.isMobile ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: _waitTimeService.getWaitTimeColor(currentWaitTime).withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: widget.isMobile ? 10 : 12,
                            fontWeight: FontWeight.bold,
                            color: _waitTimeService.getWaitTimeColor(currentWaitTime),
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
              elevation: 2,
              margin: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 4 : 8,
                vertical: widget.isMobile ? 4 : 6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Order header
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 12 : 16,
                      vertical: widget.isMobile ? 8 : 12,
                    ),
                    title: Text(
                      'Order #${order.orderId.substring(0, 8)}',
                      style: TextStyle(
                        fontSize: widget.isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${DateFormat.jm().format(order.timestamp)} - ${order.status.displayName}',
                      style: TextStyle(
                        fontSize: widget.isMobile ? 12 : 14,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${order.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: widget.isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        IconButton(
                          iconSize: widget.isMobile ? 20 : 24,
                          icon: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                          ),
                          onPressed: () {
                            setState(() {
                              expandedOrderId = isExpanded
                                  ? null
                                  : order.orderId;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Expanded order details
                  if (isExpanded)
                    Padding(
                      padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Items list
                          ...order.items.map(
                            (item) => Padding(
                              padding: EdgeInsets.symmetric(vertical: widget.isMobile ? 2 : 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.quantity}x ${item.name}',
                                    style: TextStyle(
                                      fontSize: widget.isMobile ? 14 : 16,
                                    ),
                                  ),
                                  Text(
                                    '₹${item.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: widget.isMobile ? 14 : 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(
                            height: 16,
                            thickness: 1,
                            color: Colors.grey[300],
                          ),
                          // Order summary
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal',
                                style: TextStyle(
                                  fontSize: widget.isMobile ? 14 : 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '₹${order.subtotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: widget.isMobile ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: widget.isMobile ? 2 : 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tax',
                                style: TextStyle(
                                  fontSize: widget.isMobile ? 14 : 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '₹${order.tax.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: widget.isMobile ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            height: 16,
                            thickness: 1,
                            color: Colors.grey[300],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: widget.isMobile ? 14 : 16,
                                ),
                              ),
                              Text(
                                '₹${order.total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: widget.isMobile ? 14 : 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          if (order.status == OrderStatus.pending ||
                              order.status == OrderStatus.preparing) ...[
                            Divider(
                              height: 16,
                              thickness: 1,
                              color: Colors.grey[300],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: widget.isMobile ? 16 : 18,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: widget.isMobile ? 4 : 6),
                                Text(
                                  'Ready by ${DateFormat.jm().format(order.estimatedReadyTime)}',
                                  style: TextStyle(
                                    fontSize: widget.isMobile ? 12 : 14,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
}
