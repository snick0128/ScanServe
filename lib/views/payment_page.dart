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
  // Feature toggle for online payments
  static const bool _enableOnlinePayments = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'cash', 'name': 'Cash at Counter', 'icon': Icons.store_outlined},
    {'id': 'bill', 'name': 'Request Bill', 'icon': Icons.receipt_long_outlined},
  ];

  Future<void> _handleRequestBill({bool isCashAtCounter = false}) async {
    final orderController = context.read<OrderController>();
    if (orderController.activeOrders.isEmpty) {
      SnackbarHelper.showTopSnackBar(context, 'No active orders found.');
      return;
    }

    final isParcel = orderController.activeOrders.first.type == OrderType.parcel;

    try {
      final session = await _guestSession.getCurrentSession();
      final tenantId = session['tenantId'];
      final tableId = session['tableId'];

      if (tenantId == null) {
        SnackbarHelper.showTopSnackBar(context, 'Unable to proceed - session not found');
        return;
      }

      final guestId = await _guestSession.getGuestId();
      final profile = await _guestSession.getGuestProfile();
      
      // Only check for pending requests if it's Dine-in
      if (!isParcel) {
        final hasPending = await _billRequestService.hasPendingBillRequest(
          tenantId: tenantId,
          guestId: guestId,
        );

        if (hasPending) {
          SnackbarHelper.showTopSnackBar(context, 'You already have a pending request');
          return;
        }
      }

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
          customerName: profile?.name ?? 'Guest',
          customerPhone: profile?.phone,
          tableId: tableId,
          tableName: tableName,
          orderIds: orderIds,
          isCashAtCounter: isCashAtCounter,
        );
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          'Settlement Options',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isRequestingBill 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
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
                  _handleRequestBill(isCashAtCounter: method['id'] == 'cash');
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(24),
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          method['icon'],
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method['name'],
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              method['id'] == 'cash' 
                                ? 'Pay directly at the bill counter' 
                                : 'Request bill at your table',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppTheme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.borderColor,
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


