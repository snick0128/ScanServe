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
        title: const Text('Your Order'),
        elevation: 0,
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
                        if (snapshot.connectionState == ConnectionState.waiting) {
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
                    Divider(
                      thickness: 1,
                      height: 1,
                      color: Colors.grey[300],
                    ),
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
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
            borderRadius: isMobile
                ? const BorderRadius.vertical(top: Radius.circular(16))
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
              Divider(
                height: 24,
                thickness: 1,
                color: Colors.grey[300],
              ),
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
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              ElevatedButton(
                onPressed: subtotal > 0
                    ? () async {
                        if (!context.mounted) return;
                        try {
                          final guestId = await guestSession.getGuestId();
                          final avgPrepTime =
                              await orderService.getTenantPrepTime(tenantId);

                          await orderService.placeOrder(
                            tenantId: tenantId,
                            guestId: guestId,
                            type: orderController.currentOrderType,
                            tableId: orderController.currentSession?.tableId,
                            items: cartController.items,
                            avgPrepTime: avgPrepTime,
                          );

                          cartController.clear();

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order placed successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error placing order: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    : null,
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFF914D),
                        Color(0xFFFF6E40),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 14 : 16,
                    horizontal: 32,
                  ),
                  child: const Text(
                    'Place Order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
