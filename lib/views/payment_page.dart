import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../services/bill_request_service.dart';
import '../services/guest_session_service.dart';
import '../utils/snackbar_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/customer_details_bottom_sheet.dart';
import '../utils/haptic_helper.dart';
import 'upi_payment_page.dart';
import 'bill_view.dart';

class PaymentPage extends StatefulWidget {
  final String tenantId;

  const PaymentPage({Key? key, required this.tenantId}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _billRequestService = BillRequestService();
  final _guestSession = GuestSessionService();
  bool _isRequestingBill = false;
  String? _selectedMethod;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'upi', 'name': 'UPI', 'icon': Icons.account_balance_wallet_outlined},
    {'id': 'cards', 'name': 'Credit / Debit Cards', 'icon': Icons.credit_card_outlined},
    {'id': 'wallets', 'name': 'Wallets', 'icon': Icons.account_balance_wallet_outlined},
    {'id': 'netbanking', 'name': 'Net Banking', 'icon': Icons.account_balance_outlined},
  ];

  Future<void> _handleRequestBill() async {
    final orderController = context.read<OrderController>();
    if (orderController.activeOrders.isEmpty) {
      SnackbarHelper.showTopSnackBar(context, 'No active orders found.');
      return;
    }

    final isParcel = orderController.activeOrders.first.type == OrderType.parcel;

    try {
      final profile = await _guestSession.getGuestProfile();
      final session = await _guestSession.getCurrentSession();
      final tenantId = session['tenantId'];
      final tableId = session['tableId'];

      if (tenantId == null) {
        SnackbarHelper.showTopSnackBar(context, 'Unable to proceed - session not found');
        return;
      }

      final guestId = await _guestSession.getGuestId();
      
      // Only check for pending requests if it's Dine-in "Request Bill"
      if (!isParcel) {
        final hasPending = await _billRequestService.hasPendingBillRequest(
          tenantId: tenantId,
          guestId: guestId,
        );

        if (hasPending) {
          SnackbarHelper.showTopSnackBar(context, 'You already have a pending bill request');
          return;
        }
      }

      final customerDetails = await CustomerDetailsBottomSheet.show(
        context: context,
        existingProfile: profile,
        orderType: orderController.activeOrders.first.type,
        title: isParcel ? 'Pay at Counter' : 'Request Bill',
        submitButtonText: isParcel ? 'Confirm' : 'Request Bill',
      );

      if (customerDetails == null) return;

      setState(() => _isRequestingBill = true);

      final orderIds = orderController.activeOrders
          .map((order) => order.orderId)
          .toList();
      
      final tableName = orderController.activeOrders.isNotEmpty 
          ? orderController.activeOrders.first.tableName 
          : (tableId != null ? 'Table $tableId' : null);

      if (!isParcel) {
        await _billRequestService.createBillRequest(
          tenantId: tenantId,
          guestId: guestId,
          customerName: customerDetails.name,
          customerPhone: customerDetails.phone,
          tableId: tableId,
          tableName: tableName,
          orderIds: orderIds,
        );
      }

      await _guestSession.updateGuestProfile(
        name: customerDetails.name,
        phone: customerDetails.phone,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                Icon(
                  isParcel ? Icons.store_outlined : Icons.person_outline, 
                  color: AppTheme.primaryColor, 
                  size: 48
                ),
                const SizedBox(height: 16),
                Text(
                  isParcel ? 'Visit Counter' : 'Bill Requested!',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              isParcel
                  ? 'Please visit the counter to pay. The staff will mark your order as paid after receiving the payment.'
                  : 'Our waiter will be at your table shortly with the bill. You can pay them directly in cash.',
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
        SnackbarHelper.showTopSnackBar(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingBill = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Options',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final method = _paymentMethods[index];
                final isSelected = _selectedMethod == method['id'];

                return GestureDetector(
                  onTap: () {
                    HapticHelper.light();
                    setState(() {
                      _selectedMethod = method['id'];
                    });
                    
                    // Navigate to dedicated screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UPIPaymentPage(methodName: method['name']),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          method['icon'],
                          color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryText,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          method['name'],
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppTheme.primaryColor : AppTheme.primaryText,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryColor,
                          )
                        else
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.borderColor, width: 2),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildBottomCTA(),
        ],
      ),
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isRequestingBill ? null : _handleRequestBill,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isRequestingBill
              ? const CircularProgressIndicator(color: Colors.white)
              : Consumer<OrderController>(
                  builder: (context, orderController, child) {
                    final isParcel = orderController.activeOrders.isNotEmpty && 
                        orderController.activeOrders.first.type == OrderType.parcel;
                    return Text(
                      isParcel ? 'Pay at Counter' : 'Request Bill',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
