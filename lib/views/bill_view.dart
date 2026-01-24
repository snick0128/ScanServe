import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/order_details.dart';
import '../theme/app_theme.dart';

class BillView extends StatelessWidget {
  final List<OrderDetails> orders;
  final String? tableName;

  const BillView({Key? key, required this.orders, this.tableName}) : super(key: key);

  double get subtotal => orders.fold(0, (sum, order) => sum + order.subtotal);
  double get tax => orders.fold(0, (sum, order) => sum + order.tax);
  double get total => orders.fold(0, (sum, order) => sum + order.total);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('BILL DETAILS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryText,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              // Simulate print success
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preparing bill for printing...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(Icons.restaurant, size: 48, color: AppTheme.primaryColor),
                  const SizedBox(height: 12),
                  Text(
                    'Scan & Serve',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (tableName != null)
                    Text(
                      tableName!,
                      style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.secondaryText),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now()),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'ORDER SUMMARY',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.secondaryText, letterSpacing: 1),
            ),
            const Divider(height: 24),
            ...orders.expand((order) => order.items).map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.name)),
                  Text('₹${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
            const Divider(height: 32),
            _buildPriceRow('Subtotal', subtotal),
            _buildPriceRow('Taxes', tax),
            const Divider(height: 32),
            _buildPriceRow(
              'TOTAL AMOUNT', 
              total, 
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700]),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                   // Logic for print
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Print dialog opened')),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text('PRINT BILL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style?.copyWith(color: AppTheme.secondaryText) ?? const TextStyle(color: AppTheme.secondaryText)),
          Text('₹${amount.toStringAsFixed(0)}', style: style ?? const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
