import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../providers/analytics_provider.dart';

class ExportService {
  static Future<void> exportAnalyticsToPdf(AnalyticsProvider provider) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final fmt = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Operational Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(fmt.format(now)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Report Period: ${provider.dateFilter}', style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 32),
            
            // KPIs
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildKPICard('Total Revenue', 'Rs. ${provider.totalRevenue.toStringAsFixed(2)}'),
                _buildKPICard('Total Orders', provider.totalOrders.toString()),
                _buildKPICard('Avg Order Value', 'Rs. ${provider.avgOrderValue.toStringAsFixed(2)}'),
              ],
            ),
            pw.SizedBox(height: 48),

            // Top Items Table
            pw.Text('Top Performing Items', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Item Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Units Sold', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Revenue (Rs.)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...provider.topItems.map((item) => pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['name'].toString())),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['units'].toString())),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['revenue'].toStringAsFixed(2))),
                  ],
                )),
              ],
            ),
            
            pw.SizedBox(height: 48),
            
            // Category Distribution
            pw.Text('Category Distribution', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Column(
              children: provider.categorySales.entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(e.key),
                    pw.Text('Rs. ${e.value.toStringAsFixed(2)}'),
                  ],
                ),
              )).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'ScanServe_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _buildKPICard(String label, String value) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 8),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
