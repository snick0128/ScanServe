import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../services/bill_service.dart';

class BillsScreen extends StatelessWidget {
  final String tenantId;
  final BillService _billService = BillService();

  BillsScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'All Bills',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Add filters if needed
              ],
            ),
          ),
          
          // Bills List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _billService.getBills(tenantId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bills = snapshot.data ?? [];

                if (bills.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No bills generated yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    return _buildBillCard(context, bill);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, Map<String, dynamic> bill) {
    final createdAt = (bill['createdAt'] as dynamic)?.toDate() ?? DateTime.now();
    final billId = bill['billId'] ?? 'Unknown';
    final total = (bill['finalTotal'] ?? 0).toDouble();
    final tableId = bill['tableId'] ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bill #$billId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Table: $tableId • ${DateFormat('MMM d, y • h:mm a').format(createdAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _generateAndDownloadPdf(context, bill),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndDownloadPdf(BuildContext context, Map<String, dynamic> bill) async {
    try {
      final pdf = pw.Document();
      
      // Load a font that supports the Rupee symbol
      final font = await PdfGoogleFonts.notoSansDevanagariRegular();
      final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();

      final billId = bill['billId'] ?? 'Unknown';
      final createdAt = (bill['createdAt'] as dynamic)?.toDate() ?? DateTime.now();
      final tableId = bill['tableId'] ?? 'Unknown';
      final subtotal = (bill['subtotal'] ?? 0).toDouble();
      final tax = (bill['tax'] ?? 0).toDouble();
      final discount = (bill['discount'] ?? 0).toDouble();
      final discountAmount = (bill['discountAmount'] ?? 0).toDouble();
      final finalTotal = (bill['finalTotal'] ?? 0).toDouble();
      final orderDetails = (bill['orderDetails'] as List<dynamic>? ?? []);

      pdf.addPage(
        pw.Page(
          theme: pw.ThemeData.withFont(
            base: font,
            bold: boldFont,
          ),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('ScanServe Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Bill #$billId', style: const pw.TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Date: ${DateFormat('MMM d, y').format(createdAt)}'),
                        pw.Text('Time: ${DateFormat('h:mm a').format(createdAt)}'),
                        pw.Text('Table: $tableId'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Table.fromTextArray(
                  context: context,
                  border: null,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                  },
                  headers: ['Item', 'Qty', 'Price', 'Total'],
                  data: orderDetails.expand((order) {
                    final items = (order['items'] as List<dynamic>? ?? []);
                    return items.map((item) {
                      return [
                        item['name'],
                        item['quantity'].toString(),
                        '${(item['price'] as num).toStringAsFixed(2)}',
                        '${(item['total'] as num).toStringAsFixed(2)}',
                      ];
                    });
                  }).toList(),
                ),
                pw.Divider(),
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 14)),
                          pw.SizedBox(width: 20),
                          pw.Text('${subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('Tax:', style: const pw.TextStyle(fontSize: 14)),
                          pw.SizedBox(width: 20),
                          pw.Text('${tax.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
                        ],
                      ),
                      if (discount > 0) ...[
                        pw.SizedBox(height: 5),
                        pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text('Discount ($discount%):', style: const pw.TextStyle(fontSize: 14, color: PdfColors.green)),
                            pw.SizedBox(width: 20),
                            pw.Text('-${discountAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14, color: PdfColors.green)),
                          ],
                        ),
                      ],
                      pw.SizedBox(height: 10),
                      pw.Divider(),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('Total:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(width: 20),
                          pw.Text('${finalTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Center(
                  child: pw.Text('Thank you for dining with us!', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                ),
              ],
            );
          },
        ),
      );

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'bill_$billId.pdf');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e\nTry restarting the app if this persists.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
