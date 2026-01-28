import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../theme/admin_theme.dart';
import '../../../services/bill_service.dart';

class BillDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> bill;
  final String tenantId;

  const BillDetailsScreen({super.key, required this.bill, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    final createdAt = (bill['createdAt'] as Timestamp).toDate();
    final items = (bill['orderDetails'] as List? ?? []).expand((order) => (order['items'] as List? ?? [])).toList();

    return Scaffold(
      backgroundColor: AdminTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text('Bill #${bill['billId']?.toString().substring(0, 8) ?? 'N/A'}'),
        backgroundColor: Colors.white,
        foregroundColor: AdminTheme.primaryText,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Ionicons.print_outline),
            onPressed: () => _printBill(context),
            tooltip: 'Print Receipt',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RECEIPT', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AdminTheme.primaryColor)),
                        const SizedBox(height: 8),
                        Text('Bill ID: ${bill['billId']}', style: const TextStyle(color: AdminTheme.secondaryText)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('SCAN & SERVE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(DateFormat('MMM d, yyyy • h:mm a').format(createdAt), style: const TextStyle(color: AdminTheme.secondaryText)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn('TABLE', bill['tableId'] ?? 'N/A'),
                    _buildInfoColumn('CUSTOMER', bill['customerName'] ?? 'Guest'),
                    _buildInfoColumn('PAYMENT', (bill['paymentMethod'] ?? 'CASH').toString().toUpperCase()),
                    _buildInfoColumn('STATUS', 'SETTLED', color: AdminTheme.success),
                  ],
                ),
                const SizedBox(height: 48),
                const Text('ORDER SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 1)),
                const Divider(height: 32),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Qty: ${item['quantity']}', style: const TextStyle(color: AdminTheme.secondaryText, fontSize: 14)),
                            ],
                          ),
                        ),
                        Text('₹${item['total']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 48),
                _buildTotalRow('Subtotal', bill['subtotal']),
                _buildTotalRow('Tax', bill['tax']),
                if ((bill['discountAmount'] ?? 0) > 0)
                  _buildTotalRow('Discount', -(bill['discountAmount'] as num), color: AdminTheme.success),
                const Divider(height: 48, thickness: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL AMOUNT', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('₹${bill['finalTotal']}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AdminTheme.primaryColor)),
                  ],
                ),
                const SizedBox(height: 64),
                const Center(
                  child: Text('THANK YOU FOR YOUR PATRONAGE!', style: TextStyle(color: AdminTheme.secondaryText, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? AdminTheme.primaryText)),
      ],
    );
  }

  Widget _buildTotalRow(String label, dynamic value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AdminTheme.secondaryText)),
          Text(
            value is num ? '₹${value.toStringAsFixed(2)}' : '₹$value',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _printBill(BuildContext context) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('SCAN & SERVE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text('REPRINT RECEIPT', style: const pw.TextStyle(fontSize: 10))),
              pw.Divider(),
              pw.Text('Bill ID: ${bill['billId'].toString().substring(0, 8)}'),
              pw.Text('Table: ${bill['tableId']}'),
              pw.Text('Date: ${DateFormat('dd/MM/yyyy h:mm a').format((bill['createdAt'] as Timestamp).toDate())}'),
              pw.Divider(),
              pw.Table.fromTextArray(
                context: context,
                data: [
                  ['Item', 'Qty', 'Amt'],
                  ...(bill['orderDetails'] as List).expand((order) => (order['items'] as List).map((i) => [
                    i['name'],
                    i['quantity'].toString(),
                    i['total'].toString(),
                  ])),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:'),
                  pw.Text('Rs. ${bill['subtotal']}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tax:'),
                  pw.Text('Rs. ${bill['tax']}'),
                ],
              ),
              if ((bill['discountAmount'] ?? 0) > 0)
                 pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:'),
                    pw.Text('-Rs. ${bill['discountAmount']}'),
                  ],
                ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('FINAL TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs. ${bill['finalTotal']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('THANK YOU! VISIT AGAIN', style: const pw.TextStyle(fontSize: 8))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
