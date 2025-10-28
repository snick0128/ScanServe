import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../services/tenant_service.dart';
import 'order_type_dialog.dart';
import 'cart_page.dart';

class ViewOrderBar extends StatelessWidget {
  final String tenantId;

  const ViewOrderBar({Key? key, required this.tenantId}) : super(key: key);

  void _showOrderTypeSnackBar(BuildContext context, OrderType type) {
    final orderController = context.read<OrderController>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              type == OrderType.dineIn
                  ? Icons.restaurant
                  : Icons.takeout_dining,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Order type set to ${type.displayName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final newType = await showDialog<OrderType>(
                  context: context,
                  builder: (_) => OrderTypeDialog(initialType: type),
                );
                if (newType != null && newType != type) {
                  await orderController.createOrderSession(
                    newType,
                    tenantId: tenantId,
                  );
                  _showOrderTypeSnackBar(context, newType);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'CHANGE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        backgroundColor: type == OrderType.dineIn
            ? Colors.orange.shade700
            : Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final cart = context.watch<CartController>();
    final orderController = context.watch<OrderController>();

    // Check if there are pending orders
    final hasPendingOrders = orderController.activeOrders.isNotEmpty;
    final cartIsEmpty = cart.itemCount == 0;

    // Don't show the bar if cart is empty AND no pending orders
    if (cartIsEmpty && !hasPendingOrders) {
      return const SizedBox.shrink();
    }

    // Determine button text and action
    final bool showPayNow = cartIsEmpty && hasPendingOrders;
    final String buttonText = showPayNow ? 'Pay Now' : 'View Order (₹${cart.totalAmount.toStringAsFixed(2)})';
    final IconData buttonIcon = showPayNow ? Icons.payment : Icons.shopping_cart;

    return Container(
      margin: const EdgeInsets.only(bottom: 15, left: 15, right: 15),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? (screenWidth - 600) / 2 : 16,
        vertical: 8, // Reduced from 16 to 8
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(50), // Pill-shaped
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final orderController = context.read<OrderController>();

            // Show order type selection if not already selected
            if (orderController.currentOrderType == null) {
              final selectedType = await showDialog<OrderType>(
                context: context,
                barrierDismissible: false,
                builder: (_) => OrderTypeDialog(
                  initialType: orderController.currentOrderType,
                ),
              );

              if (selectedType != null) {
                await orderController.createOrderSession(
                  selectedType,
                  tenantId: tenantId,
                );
                _showOrderTypeSnackBar(context, selectedType);
              }
            }

            // If showing Pay Now (cart empty but has pending orders), go to checkout
            if (showPayNow) {
              Navigator.pushNamed(
                context,
                '/checkout',
                arguments: {
                  'tenantId': tenantId,
                  'orderType': orderController.currentOrderType,
                  'tableId': orderController.currentSession?.tableId,
                  'requirePayment': true,
                },
              );
            } else {
              // Otherwise go to cart page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(
                    tenantId: orderController.currentSession!.tenantId,
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(50),
          splashColor: Theme.of(context).colorScheme.onPrimary.withAlpha(30),
          highlightColor: Theme.of(context).colorScheme.onPrimary.withAlpha(20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
            ), // Reduced from 16 to 8
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  buttonIcon,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 18, // Slightly smaller
                ),
                const SizedBox(width: 6), // Reduced from 8 to 6
                Text(
                  buttonText,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 14, // Reduced from 16 to 14
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!showPayNow) ...[
                  const SizedBox(width: 6), // Reduced from 8 to 6
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cart.itemCount.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11, // Reduced from 12 to 11
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
