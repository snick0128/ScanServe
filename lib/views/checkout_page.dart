import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scan_serve/utils/snackbar_helper.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../models/order.dart' as model;
import '../models/order_model.dart' as orm;
import '../services/payment_service.dart';
import '../services/order_service.dart';
import '../services/guest_session_service.dart';

class CheckoutPage extends StatefulWidget {
  final String tenantId;
  final String orderType; // 'dineIn' or 'parcel'
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

  model.PaymentStatus _paymentStatus = model.PaymentStatus.pending;
  bool _isProcessing = false;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _loadGuestProfile();
  }

  /// Load saved guest profile and prefill form fields
  Future<void> _loadGuestProfile() async {
    final profile = await _guestSession.getGuestProfile();
    if (profile != null && mounted) {
      setState(() {
        _nameController.text = profile.name;
        _phoneController.text = profile.phone ?? '';
      });
      print('✅ Prefilled customer details from saved profile');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processCheckout(CartController cart, OrderController orderController) async {
    if (_isProcessing) return; // Immediate duplicate prevention

    if (!_formKey.currentState!.validate()) {
      SnackbarHelper.showTopSnackBar(context, 'Please fill in all required fields');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final guestId = await _guestSession.getGuestId();

      // Create order
      _orderId = await _orderService.createOrder(
        tenantId: widget.tenantId,
        guestId: guestId,
        orderType: widget.orderType == 'dineIn' ? orm.OrderType.dineIn : orm.OrderType.parcel,
        tableId: widget.tableId,
        cartItems: cart.items,
        notes: 'Order placed via checkout',
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        paymentStatus: model.PaymentStatus.pending,
      );

      // Trigger payment UI/logic
      final settings = await _orderService.getTenantSettings(widget.tenantId);
      final taxRate = (settings['taxRate'] as num?)?.toDouble() ?? 0.18;
      final total = cart.totalAmount * (1 + taxRate);

      // Save guest profile for CRM
      await _guestSession.updateGuestProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );

      cart.clear();

      if (mounted) {
        SnackbarHelper.showTopSnackBar(context, 'Order placed successfully!');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showTopSnackBar(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendToKitchen(CartController cart, OrderController orderController) async {
    if (_isProcessing) return;

    if (!_formKey.currentState!.validate()) {
      SnackbarHelper.showTopSnackBar(context, 'Please fill in all required fields');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final guestId = await _guestSession.getGuestId();

      _orderId = await _orderService.createOrder(
        tenantId: widget.tenantId,
        guestId: guestId,
        orderType: orm.OrderType.dineIn,
        tableId: widget.tableId,
        cartItems: cart.items,
        notes: 'Dine-in order sent to kitchen',
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );

      await _guestSession.updateGuestProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );

      cart.clear();

      if (mounted) {
        SnackbarHelper.showTopSnackBar(context, 'Sent to kitchen!');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showTopSnackBar(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final orderController = context.watch<OrderController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildOrderSummary(cart),
              _buildCustomerInfoForm(),
              const SizedBox(height: 24),
              if (_isProcessing)
                const CircularProgressIndicator()
              else if (widget.orderType == 'dineIn')
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        onPressed: cart.items.isEmpty ? null : () => _sendToKitchen(cart, orderController),
                        child: const Text('Send to Kitchen (Add-on)'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: cart.items.isEmpty ? null : () => _processCheckout(cart, orderController),
                        child: const Text('Proceed to Payment'),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cart.items.isEmpty ? null : () => _processCheckout(cart, orderController),
                    child: const Text('Complete Order'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartController cart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...cart.items.map((i) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('${i.quantity}x ${i.item.name}'), Text('₹${i.item.price * i.quantity}')],
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('₹${cart.totalAmount}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name *'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }
}
