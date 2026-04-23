import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BillPrintBuilder {
  static Future<pw.Document> build({
    required Map<String, dynamic> bill,
    String taxLabel = 'GST',
    String receiptTitle = 'GUEST RECEIPT',
    Map<String, dynamic>? templateSettings,
  }) async {
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();

    final billId = (bill['billId'] ?? 'Unknown').toString();
    final createdAt =
        (bill['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final tableId = (bill['tableId'] ?? 'Unknown').toString();
    final paymentMethod = (bill['paymentMethod'] ?? 'Cash').toString();
    final customerName = (bill['customerName'] ?? '').toString();
    final customerPhone = (bill['customerPhone'] ?? '').toString();

    final subtotal = _toDouble(bill['subtotal']);
    final tax = _toDouble(bill['tax']);
    final discountAmount = _toDouble(bill['discountAmount']);
    final finalTotal = _toDouble(bill['finalTotal']);
    final taxRate = _resolveTaxRate(bill, subtotal);
    final template = templateSettings ?? const <String, dynamic>{};
    final restaurantName = _readString(
      template,
      'restaurantName',
      fallback: 'SCAN SERVE',
    );
    final restaurantAddress = _readString(template, 'address');
    final restaurantPhone = _readString(template, 'phone');
    final restaurantGstin = _readString(template, 'gstin');
    final restaurantFssai = _readString(template, 'fssai');
    final footerMessage = _readString(
      template,
      'footerMessage',
      fallback: 'THANK YOU. VISIT AGAIN.',
    );
    final showTable = _readBool(template, 'showTable', fallback: true);
    final showPaymentMethod = _readBool(
      template,
      'showPaymentMethod',
      fallback: true,
    );
    final showCustomerDetails = _readBool(
      template,
      'showCustomerDetails',
      fallback: true,
    );

    final items = _extractItems(bill['orderDetails']);

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  restaurantName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  receiptTitle,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              if (restaurantAddress.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    restaurantAddress,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              if (restaurantPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'Phone: $restaurantPhone',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              if (restaurantGstin.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'GSTIN: $restaurantGstin',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              if (restaurantFssai.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'FSSAI: $restaurantFssai',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              pw.SizedBox(height: 6),
              _dashedDivider(),
              pw.SizedBox(height: 4),
              _keyValue('Bill', '#${_shortId(billId)}'),
              if (showTable) _keyValue('Table', tableId),
              _keyValue('Date', DateFormat('dd MMM yyyy').format(createdAt)),
              _keyValue('Time', DateFormat('h:mm a').format(createdAt)),
              if (showPaymentMethod) _keyValue('Payment', paymentMethod),
              if (showCustomerDetails && customerName.isNotEmpty)
                _keyValue('Guest', customerName),
              if (showCustomerDetails && customerPhone.isNotEmpty)
                _keyValue('Phone', customerPhone),
              pw.SizedBox(height: 6),
              _dashedDivider(),
              pw.SizedBox(height: 6),
              _itemsHeader(),
              pw.SizedBox(height: 4),
              for (final item in items) _itemRow(item),
              pw.SizedBox(height: 6),
              _dashedDivider(),
              pw.SizedBox(height: 6),
              _amountRow('Subtotal', subtotal),
              _amountRow(
                '${_cleanLabel(taxLabel)} ${_formatPercent(taxRate)}',
                tax,
              ),
              if (discountAmount > 0)
                _amountRow('Discount', -discountAmount, isDiscount: true),
              pw.SizedBox(height: 4),
              _dashedDivider(),
              pw.SizedBox(height: 6),
              _totalRow('TOTAL', finalTotal),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  footerMessage.toUpperCase(),
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc;
  }

  static List<_BillItem> _extractItems(dynamic raw) {
    if (raw is! List) return [];
    if (raw.isEmpty) return [];

    final first = raw.first;
    if (first is Map && first.containsKey('items')) {
      final List<_BillItem> items = [];
      for (final order in raw) {
        final orderItems = (order['items'] as List?) ?? const [];
        for (final item in orderItems) {
          items.add(_BillItem.fromMap(item));
        }
      }
      return items;
    }

    return raw.map((e) => _BillItem.fromMap(e)).toList();
  }

  static double _resolveTaxRate(Map<String, dynamic> bill, double subtotal) {
    final rate = bill['taxRate'];
    if (rate is num && rate >= 0) return rate.toDouble();
    if (subtotal <= 0) return 0;
    return _toDouble(bill['tax']) / subtotal;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static String _shortId(String id) {
    return id.length > 8 ? id.substring(0, 8) : id;
  }

  static String _cleanLabel(String label) {
    final trimmed = label.trim();
    return trimmed.isEmpty ? 'GST' : trimmed.toUpperCase();
  }

  static String _readString(
    Map<String, dynamic> source,
    String key, {
    String fallback = '',
  }) {
    final value = source[key];
    if (value is! String) return fallback;
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static bool _readBool(
    Map<String, dynamic> source,
    String key, {
    required bool fallback,
  }) {
    final value = source[key];
    if (value is bool) return value;
    return fallback;
  }

  static String _formatPercent(double value) {
    final pct = value * 100;
    final isInt = pct % 1 == 0;
    return '(${pct.toStringAsFixed(isInt ? 0 : 2)}%)';
  }

  static pw.Widget _dashedDivider() {
    return pw.Container(
      height: 1,
      child: pw.Row(
        children: List.generate(
          30,
          (i) => pw.Expanded(
            child: pw.Container(
              height: 1,
              color: i.isEven ? PdfColors.grey700 : PdfColors.white,
            ),
          ),
        ),
      ),
    );
  }

  static pw.Widget _keyValue(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  static pw.Widget _itemsHeader() {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 7,
          child: pw.Text(
            'Item',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Qty',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
        pw.Expanded(
          flex: 3,
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Amt',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _itemRow(_BillItem item) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 7,
              child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  item.quantity.toString(),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  _money(item.total),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ),
          ],
        ),
        if (item.price > 0)
          pw.Row(
            children: [
              pw.Expanded(
                flex: 7,
                child: pw.Text(
                  '₹${item.price.toStringAsFixed(2)} each',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.Expanded(flex: 5, child: pw.SizedBox()),
            ],
          ),
        pw.SizedBox(height: 2),
      ],
    );
  }

  static pw.Widget _amountRow(
    String label,
    double value, {
    bool isDiscount = false,
  }) {
    final color = isDiscount ? PdfColors.green700 : PdfColors.black;
    final display = value < 0 ? '-${_money(value.abs())}' : _money(value);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        pw.Text(display, style: pw.TextStyle(fontSize: 9, color: color)),
      ],
    );
  }

  static pw.Widget _totalRow(String label, double value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          _money(value),
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static String _money(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }
}

class _BillItem {
  final String name;
  final int quantity;
  final double price;
  final double total;

  _BillItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory _BillItem.fromMap(Map<String, dynamic> map) {
    final qty = (map['quantity'] as num?)?.toInt() ?? 1;
    final price = (map['price'] as num?)?.toDouble() ?? 0.0;
    final total = (map['total'] as num?)?.toDouble() ?? (price * qty);
    return _BillItem(
      name: (map['name'] ?? '').toString(),
      quantity: qty,
      price: price,
      total: total,
    );
  }
}
