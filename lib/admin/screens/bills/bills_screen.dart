import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
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
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _generateAndDownloadPdf(context, bill),
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Print / PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _shareToWhatsApp(context, bill),
                      icon: const Icon(Icons.share, color: Colors.green),
                      tooltip: 'Share on WhatsApp',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareToWhatsApp(BuildContext context, Map<String, dynamic> bill) async {
    final phone = bill['customerPhone'];
    final billId = bill['billId'] ?? 'Unknown';
    final total = (bill['finalTotal'] ?? 0).toDouble();
    final tableId = bill['tableId'] ?? 'Unknown';

    String message = "Hello! Here is your bill summary from ScanServe:\n\n"
        "Bill ID: #$billId\n"
        "Table: $tableId\n"
        "Total Amount: ₹${total.toStringAsFixed(2)}\n\n"
        "Thank you for dining with us!";

    if (phone == null || phone.toString().isEmpty) {
      // Prompt for phone number if not available
      final result = await _showPhonePrompt(context);
      if (result != null && result.isNotEmpty) {
        _launchWhatsApp(result, message);
      }
    } else {
      _launchWhatsApp(phone.toString(), message);
    }
  }

  Future<void> _launchWhatsApp(String phone, String message) async {
    // Clean phone number: remove non-numeric except +
    String cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!cleanedPhone.startsWith('+')) {
      // Default to India prefix if no prefix (assuming common target)
      // You can adjust this or make it configurable
      if (cleanedPhone.length == 10) {
        cleanedPhone = '91$cleanedPhone';
      }
    }

    final url = "https://wa.me/$cleanedPhone?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  Future<String?> _showPhonePrompt(BuildContext context) async {
    String phoneNumber = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter WhatsApp Number'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'e.g., 919876543210',
            labelText: 'Phone Number with country code',
          ),
          onChanged: (value) => phoneNumber = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, phoneNumber),
            child: const Text('Share'),
          ),
        ],
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

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'bill_$billId',
      );
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
