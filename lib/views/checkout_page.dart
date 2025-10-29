import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scan_serve/utils/snackbar_helper.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../models/order_details.dart';
import '../services/payment_service.dart';
import '../services/order_service.dart';
import '../services/guest_session_service.dart';

class CheckoutPage extends StatefulWidget {
  final String tenantId;
  final OrderType orderType;
  final String? tableId;

  const CheckoutPage({
    Key? key,
    required this.tenantId,
    required this.orderType,
    this.tableId,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _paymentService = PaymentService();
  final _orderService = OrderService();
  final _guestSession = GuestSessionService();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.upi;
  bool _isProcessingPayment = false;
  String? _orderId;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final orderController = context.watch<OrderController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        elevation: 2,
        shadowColor: Colors.deepPurple.withOpacity(0.1),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final isMobile = screenWidth < 600;
          final isTablet = screenWidth >= 600 && screenWidth < 1200;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight,
                maxWidth: isTablet ? 800 : (isMobile ? screenWidth : 1200),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 16,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Order Summary Section
                    _buildOrderSummary(cart, isMobile),

                    // Customer Information Section
                    _buildCustomerInfoForm(isMobile),

                    // Payment Method Section
                    _buildPaymentMethodSection(isMobile),

                    // Checkout Button
                    if (widget.orderType == OrderType.dineIn)
                      _buildDineInButtons(cart, orderController, isMobile)
                    else
                      _buildCheckoutButton(cart, orderController, isMobile),

                    // Bottom spacing
                    SizedBox(height: isMobile ? 16 : 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(CartController cart, bool isMobile) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _orderService.getTenantSettings(widget.tenantId),
      builder: (context, snapshot) {
        final settings = snapshot.data ?? {};
        final taxRate = settings['taxRate'] as double? ?? 0.18;
        final tax = cart.totalAmount * taxRate;
        final total = cart.totalAmount + tax;

        return Container(
          margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: Colors.deepPurple,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...cart.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.item.name}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '₹${(item.item.price * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      '₹${cart.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tax (${(taxRate * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      '₹${tax.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerInfoForm(bool isMobile) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: Colors.deepPurple, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Customer Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter your full name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.person_outline),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: isMobile ? 12 : 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: isMobile ? 12 : 14),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  hintText: '+91 9876543210',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.phone),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: isMobile ? 12 : 14,
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(bool isMobile) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.deepPurple, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...PaymentMethod.values.map(
              (method) => _buildPaymentMethodTile(method, isMobile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method, bool isMobile) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedPaymentMethod == method
              ? Colors.deepPurple
              : Colors.grey[300]!,
          width: _selectedPaymentMethod == method ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: _selectedPaymentMethod == method
            ? Colors.deepPurple.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          _getPaymentMethodIcon(method),
          color: _selectedPaymentMethod == method
              ? Colors.deepPurple
              : Colors.grey[600],
        ),
        title: Text(
          method.displayName,
          style: TextStyle(
            fontWeight: _selectedPaymentMethod == method
                ? FontWeight.bold
                : FontWeight.normal,
            color: _selectedPaymentMethod == method
                ? Colors.deepPurple
                : Colors.black87,
          ),
        ),
        trailing: _selectedPaymentMethod == method
            ? Icon(Icons.check_circle, color: Colors.deepPurple)
            : Icon(Icons.circle_outlined, color: Colors.grey[400]),
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
      ),
    );
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.upi:
        return Icons.account_balance_wallet;
    }
  }

  Widget _buildCheckoutButton(
    CartController cart,
    OrderController orderController,
    bool isMobile,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: isMobile ? 50 : 56,
        child: ElevatedButton(
          onPressed: _isProcessingPayment || cart.items.isEmpty
              ? null
              : () => _processCheckout(cart, orderController),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isProcessingPayment
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Complete Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _processCheckout(
    CartController cart,
    OrderController orderController,
  ) async {
    if (!_formKey.currentState!.validate()) {
      SnackbarHelper.showTopSnackBar(
        context,
        'Please fill in all required fields',
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Get guest ID
      final guestId = await _guestSession.getGuestId();

      // Get tenant settings for tax calculation
      final settings = await _orderService.getTenantSettings(widget.tenantId);
      final taxRate = settings['taxRate'] as double? ?? 0.18;

      // Create order
      _orderId = await _orderService.createOrder(
        tenantId: widget.tenantId,
        guestId: guestId,
        orderType: widget.orderType,
        tableId: widget.tableId,
        cartItems: cart.items,
        notes: 'Order placed via checkout',
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );

      // Process payment
      final paymentId = await _paymentService.processPayment(
        orderId: _orderId!,
        tenantId: widget.tenantId,
        paymentMethod: _selectedPaymentMethod,
        amount: cart.totalAmount + (cart.totalAmount * taxRate),
        customerId: guestId,
        tableId: widget.tableId,
      );

      // Clear cart
      cart.clear();

      // Show success message
      if (mounted) {
        SnackbarHelper.showTopSnackBar(
          context,
          'Order #${_orderId} placed successfully!',
        );

        // Navigate back to home or order list
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showTopSnackBar(context, 'Error processing order: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  Widget _buildDineInButtons(
    CartController cart,
    OrderController orderController,
    bool isMobile,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Send to Kitchen Button
          SizedBox(
            width: double.infinity,
            height: isMobile ? 48 : 54,
            child: ElevatedButton(
              onPressed: _isProcessingPayment || cart.items.isEmpty
                  ? null
                  : () => _sendToKitchen(cart, orderController),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isProcessingPayment
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.orange, Colors.orangeAccent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Send to Kitchen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          SizedBox(height: isMobile ? 12 : 16),

          // Checkout Button
          SizedBox(
            width: double.infinity,
            height: isMobile ? 48 : 54,
            child: ElevatedButton(
              onPressed: _isProcessingPayment || cart.items.isEmpty
                  ? null
                  : () => _processCheckout(cart, orderController),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isProcessingPayment
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendToKitchen(
    CartController cart,
    OrderController orderController,
  ) async {
    if (!_formKey.currentState!.validate()) {
      SnackbarHelper.showTopSnackBar(
        context,
        'Please fill in all required fields',
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Get guest ID
      final guestId = await _guestSession.getGuestId();

      // Get tenant settings for tax calculation
      final settings = await _orderService.getTenantSettings(widget.tenantId);
      final taxRate = settings['taxRate'] as double? ?? 0.18;

      // Create order and send to kitchen
      _orderId = await _orderService.createOrder(
        tenantId: widget.tenantId,
        guestId: guestId,
        orderType: widget.orderType,
        tableId: widget.tableId,
        cartItems: cart.items,
        notes: 'Order sent to kitchen - ${widget.tableId}',
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        paymentStatus:
            PaymentStatus.pending, // No payment yet for send to kitchen
        paymentMethod: PaymentMethod.cash, // Default for kitchen orders
      );

      // Clear cart
      cart.clear();

      // Show success message
      if (mounted) {
        SnackbarHelper.showTopSnackBar(
          context,
          'Order sent to kitchen! Table: ${widget.tableId}',
          duration: const Duration(seconds: 4),
        );

        // Navigate back to home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showTopSnackBar(
          context,
          'Error sending order to kitchen: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }
}
