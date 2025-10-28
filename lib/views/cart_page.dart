import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scan_serve/models/order_model.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../models/order_details.dart';
import '../services/order_service.dart';
import '../services/guest_session_service.dart';
import 'previous_orders_list.dart';
import 'cart_item_list.dart';

class CartPage extends StatelessWidget {
  final String tenantId;

  const CartPage({Key? key, required this.tenantId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderController = context.watch<OrderController>();
    final cartController = context.watch<CartController>();
    final orderService = OrderService();
    final guestSession = GuestSessionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Order',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        elevation: 2,
        shadowColor: Colors.deepPurple.withOpacity(0.1),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isMobile = screenWidth < 600;
          final isTablet = screenWidth >= 600 && screenWidth < 1200;
          final isDesktop = screenWidth >= 1200;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1200 : (isTablet ? 800 : screenWidth),
              ),
              child: Column(
                children: [
                  // Previous orders for dine-in
                  if (orderController.currentOrderType == OrderType.dineIn) ...[
                    StreamBuilder<List<OrderDetails>>(
                      stream: orderService.getTableOrders(
                        tenantId,
                        orderController.currentSession?.tableId ?? '',
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            height: 100,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final orders = snapshot.data!;
                        return PreviousOrdersList(
                          orders: orders,
                          isMobile: isMobile,
                          isTablet: isTablet,
                        );
                      },
                    ),
                    Divider(thickness: 1, height: 1, color: Colors.grey[300]),
                  ],

                  // Current cart items
                  Expanded(
                    child: CartItemList(
                      items: cartController.items,
                      onUpdateQuantity: cartController.updateQuantity,
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                  ),

                  // Order summary
                  _OrderSummary(
                    subtotal: cartController.totalAmount,
                    tenantId: tenantId,
                    cartController: cartController,
                    isMobile: isMobile,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final double subtotal;
  final String tenantId;
  final CartController cartController;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  const _OrderSummary({
    Key? key,
    required this.subtotal,
    required this.tenantId,
    required this.cartController,
    this.isMobile = false,
    this.isTablet = false,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();
    final orderController = context.read<OrderController>();
    final guestSession = GuestSessionService();

    return FutureBuilder<Map<String, dynamic>>(
      future: orderService.getTenantSettings(tenantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: isMobile ? 120 : 140,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }

        final settings = snapshot.data ?? {};
        final taxRate = settings['taxRate'] as double? ?? 0.18; // Default tax
        final tax = subtotal * taxRate;
        final total = subtotal + tax;

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -8),
                spreadRadius: 2,
              ),
            ],
            borderRadius: isMobile
                ? const BorderRadius.vertical(top: Radius.circular(20))
                : BorderRadius.zero,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '₹${subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tax (${(taxRate * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '₹${tax.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Divider(height: 24, thickness: 1, color: Colors.grey[300]),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              // Show different buttons based on order type
              if (orderController.currentOrderType == OrderType.dineIn)
                // Dine-in: Two buttons side by side
                Row(
                  children: [
                    // Send to Kitchen button (only enabled if cart has items)
                    Expanded(
                      child: _buildButton(
                        context: context,
                        text: 'Send to Kitchen',
                        gradient: const LinearGradient(
                          colors: [Colors.orange, Colors.orangeAccent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        shadowColor: Colors.orange,
                        isEnabled: cartController.itemCount > 0,
                        isMobile: isMobile,
                        fontSize: 13,
                        onPressed: () async {
                          if (!context.mounted) return;
                          try {
                            final guestId = await guestSession.getGuestId();
                            await orderService.createOrder(
                              tenantId: tenantId,
                              guestId: guestId,
                              orderType: orderController.currentOrderType,
                              tableId: orderController.currentSession?.tableId,
                              cartItems: cartController.items,
                              notes: 'Sent to kitchen - payment pending',
                            );
                            cartController.clear();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order sent to kitchen!'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.of(context).pop();
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Pay Now button (mandatory payment)
                    Expanded(
                      child: _buildButton(
                        context: context,
                        text: 'Pay Now',
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        shadowColor: Colors.deepPurple,
                        isEnabled: subtotal > 0,
                        isMobile: isMobile,
                        fontSize: 13,
                        onPressed: () {
                          // Navigate to checkout page - payment required
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
                        },
                      ),
                    ),
                  ],
                )
              else
                // Parcel: Single button (full width)
                _buildButton(
                  context: context,
                  text: 'Pay & Place Order',
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  shadowColor: Colors.deepPurple,
                  isEnabled: subtotal > 0,
                  isMobile: isMobile,
                  fontSize: 14,
                  onPressed: () {
                    // Navigate to checkout page - payment required
                    Navigator.pushNamed(
                      context,
                      '/checkout',
                      arguments: {
                        'tenantId': tenantId,
                        'orderType': orderController.currentOrderType,
                        'tableId': null,
                        'requirePayment': true,
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String text,
    required LinearGradient gradient,
    required Color shadowColor,
    required bool isEnabled,
    required bool isMobile,
    required VoidCallback onPressed,
    double fontSize = 16,
  }) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 14 : 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ).copyWith(
        backgroundColor: MaterialStateProperty.all(Colors.transparent),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 16 : 18,
          horizontal: 32,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
