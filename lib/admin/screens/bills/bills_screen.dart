import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../theme/admin_theme.dart';
import '../../providers/bills_provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../../services/bill_service.dart';

class BillsScreen extends StatefulWidget {
  final String tenantId;

  const BillsScreen({super.key, required this.tenantId});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _timer;
  DateTime _now = DateTime.now();
  String? _processingTableId;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.scaffoldBackground,
      body: Consumer<BillsProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(provider),
                const SizedBox(height: 24),
                _buildKPICards(provider),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showHistoryDialog(context, provider),
                      icon: const Icon(Ionicons.time_outline, size: 18),
                      label: const Text('View All History'),
                      style: TextButton.styleFrom(foregroundColor: AdminTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildPendingBillsTable(provider)),
                const SizedBox(height: 24),
                _buildBulkOperations(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BillsProvider provider) {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Billing & Payments',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AdminTheme.primaryText,
              ),
            ),
            Text(
              'Live financial control panel',
              style: TextStyle(color: AdminTheme.secondaryText, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(width: 48),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            height: 44,
            decoration: BoxDecoration(
              color: AdminTheme.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AdminTheme.dividerColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search by table, bill ID, or session...',
                hintStyle: TextStyle(color: AdminTheme.secondaryText, fontSize: 13),
                prefixIcon: Icon(Ionicons.search_outline, size: 18, color: AdminTheme.secondaryText),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('EEEE, MMM d').format(_now),
              style: const TextStyle(fontWeight: FontWeight.w600, color: AdminTheme.primaryText),
            ),
            Text(
              DateFormat('h:mm:ss a').format(_now),
              style: const TextStyle(color: AdminTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(width: 24),
          IconButton(
          onPressed: () {
            provider.refreshBills();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Billing data refreshed')),
            );
          },
          icon: const Icon(Ionicons.refresh_outline),
          style: IconButton.styleFrom(
            backgroundColor: AdminTheme.cardBackground,
            side: const BorderSide(color: AdminTheme.dividerColor),
          ),
        ),
      ],
    );
  }

  Widget _buildKPICards(BillsProvider provider) {
    return Row(
      children: [
        _buildKPICard(
          'Total Pending Amount',
          '₹${NumberFormat('#,##,###.00').format(provider.totalPendingAmount)}',
          provider.pendingTrend,
          Ionicons.wallet_outline,
          AdminTheme.critical,
        ),
        const SizedBox(width: 24),
        _buildKPICard(
          'Active Sessions',
          provider.activeSessionsCount.toString(),
          'All tables requiring checkout',
          Ionicons.time_outline,
          AdminTheme.warning,
        ),
        const SizedBox(width: 24),
        _buildKPICard(
          'Completed Today',
          provider.completedTodayCount.toString(),
          'Total: ₹${NumberFormat('#,##,###').format(provider.completedTodayVolume)}',
          Ionicons.checkmark_circle_outline,
          AdminTheme.success,
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, String subtitle, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AdminTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTheme.primaryColor.withOpacity(0.1), width: 1.5),
          boxShadow: [
            BoxShadow(color: AdminTheme.primaryColor.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: AdminTheme.secondaryText, fontSize: 14, fontWeight: FontWeight.w600)),
                Icon(icon, color: color, size: 22),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: AdminTheme.primaryText, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: subtitle.contains('+') ? AdminTheme.success : AdminTheme.secondaryText, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, BillsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Billing History'),
        content: SizedBox(
          width: 650,
          height: 500,
          child: provider.allBills.isEmpty 
              ? const Center(child: Text('No history found'))
              : ListView.builder(
                  itemCount: provider.allBills.length,
                  itemBuilder: (context, index) {
                    final bill = provider.allBills[index];
                    return ExpansionTile(
                      leading: const Icon(Ionicons.receipt_outline, color: AdminTheme.primaryColor),
                      title: Text('Bill #${bill['billId']?.toString().substring(0, 8) ?? 'N/A'}'),
                      subtitle: Text('Table: ${bill['tableId']} • ${DateFormat('MMM d, h:mm a').format((bill['createdAt'] as Timestamp).toDate())}'),
                      trailing: Text('₹${bill['finalTotal']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      childrenPadding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AdminTheme.scaffoldBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Settled By:', style: TextStyle(fontSize: 12, color: AdminTheme.secondaryText)),
                                  Text(bill['customerName'] ?? 'Guest', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(),
                              ...((bill['orderDetails'] as List? ?? []).expand((order) => (order['items'] as List? ?? [])).map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${item['quantity']}x ${item['name']}', style: const TextStyle(fontSize: 12)),
                                    Text('₹${item['total']}', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ))),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _printSingleBill(bill['billId']),
                                    icon: const Icon(Ionicons.print_outline, size: 16),
                                    label: const Text('Reprint Receipt'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AdminTheme.primaryColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildPendingBillsTable(BillsProvider provider) {
    final sessions = provider.activeSessions
        .where((s) => s.tableName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? true)
        .toList();

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.receipt_outline, size: 48, color: AdminTheme.secondaryText.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No pending bills available', style: TextStyle(color: AdminTheme.secondaryText)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 56,
          dataRowHeight: 72,
          horizontalMargin: 24,
          headingRowColor: MaterialStateProperty.all(AdminTheme.scaffoldBackground),
          columns: const [
            DataColumn(label: Text('TABLE #', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, fontSize: 12))),
            DataColumn(label: Text('CUSTOMER / SESSION', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, fontSize: 12))),
            DataColumn(label: Text('BILL AMOUNT', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, fontSize: 12))),
            DataColumn(label: Text('TIME ELAPSED', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, fontSize: 12))),
            DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, fontSize: 12))),
          ],
          rows: sessions.map((session) {
            final diff = _now.difference(session.sessionStartedAt);
            final mins = diff.inMinutes;
            
            Color statusColor = AdminTheme.success;
            if (mins > 30) {
              statusColor = AdminTheme.critical;
            } else if (mins > 10) {
              statusColor = AdminTheme.warning;
            }

            return DataRow(cells: [
              DataCell(Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Text(session.tableName ?? 'T-#', style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
                ],
              )),
              DataCell(Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.customerName ?? 'Guest User', style: const TextStyle(fontWeight: FontWeight.w600, color: AdminTheme.primaryText)),
                  Text(session.guestId?.substring(0, 8).toUpperCase() ?? 'SID-0000', style: const TextStyle(fontSize: 11, color: AdminTheme.secondaryText)),
                ],
              )),
              DataCell(Text('₹${NumberFormat('#,##,###.00').format(session.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryText))),
              DataCell(Text('$mins mins', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold))),
              DataCell(Row(
                children: [
                   _processingTableId == session.tableId 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : ElevatedButton(
                        onPressed: () => _handleMarkAsPaid(context, provider, session),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Mark as Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _confirmCancelSession(context, provider, session),
                    icon: const Icon(Ionicons.close_circle_outline, color: AdminTheme.critical, size: 20),
                    tooltip: 'Cancel Session',
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  void _confirmCancelSession(BuildContext context, BillsProvider provider, dynamic session) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel / Close Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to cancel the session for table ${session.tableName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason mandatory (e.g. Mistake, Void)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                // Handle cancellation logic
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.critical),
            child: const Text('Confirm Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkOperations(BillsProvider provider) {
    final isAdmin = context.read<AdminAuthProvider>().role == 'admin';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.primaryColor.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Ionicons.shield_checkmark_outline, color: AdminTheme.primaryColor),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Manual Reconciliation', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
              Text('Admin-only bulk checkout operations', style: TextStyle(fontSize: 12, color: AdminTheme.secondaryText)),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: isAdmin ? () => _confirmBulkClose(context, provider) : null,
            icon: const Icon(Ionicons.layers_outline, size: 18),
            label: const Text('Bulk Close Sessions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminTheme.critical,
              side: const BorderSide(color: AdminTheme.critical),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _generateDailyReport(provider),
            icon: const Icon(Ionicons.document_text_outline, size: 18),
            label: const Text('Generate Daily Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBulkClose(BuildContext context, BillsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Close All Sessions'),
        content: Text('This will mark all ${provider.activeSessionsCount} active tables as PAID and clear the dashboard. This action is irreversible. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.bulkCloseSessions();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All sessions closed successfully')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.critical),
            child: const Text('YES, CLOSE ALL'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateDailyReport(BillsProvider provider) async {
    final pdf = pw.Document();
    final today = DateTime.now();
    final bills = provider.allBills.where((b) {
      final date = (b['createdAt'] as Timestamp).toDate();
      return date.day == today.day && date.month == today.month && date.year == today.year;
    }).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Daily Revenue Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('Date: ${DateFormat('dd MMMM yyyy').format(today)}'),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Bills: ${bills.length}'),
                  pw.Text('Total Volume: Rs. ${NumberFormat('#,##,###.00').format(provider.completedTodayVolume)}'),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Bill ID', 'Table', 'Time', 'Amount'],
                  ...bills.map((b) => [
                    b['billId'].toString().substring(0, 8),
                    b['tableId'].toString(),
                    DateFormat('h:mm a').format((b['createdAt'] as Timestamp).toDate()),
                    'Rs. ${b['finalTotal']}'
                  ]),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _handleMarkAsPaid(BuildContext context, BillsProvider provider, dynamic session) async {
    setState(() => _processingTableId = session.tableId);
    try {
      final billId = await provider.markAsPaid(session.tableId, session.orderIds);
      if (mounted && billId != null) {
        _showSuccessAndPrintDialog(context, billId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminTheme.critical));
      }
    } finally {
      if (mounted) setState(() => _processingTableId = null);
    }
  }

  void _showSuccessAndPrintDialog(BuildContext context, String billId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Ionicons.checkmark_circle, color: AdminTheme.success),
            SizedBox(width: 12),
            Text('Payment Successful'),
          ],
        ),
        content: const Text('The session has been settled. Table is now available. Would you like to print the receipt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _printSingleBill(billId);
            },
            icon: const Icon(Ionicons.print_outline),
            label: const Text('Print Receipt'),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Future<void> _printSingleBill(String billId) async {
    final billService = BillService();
    final bill = await billService.getBill(widget.tenantId, billId);
    if (bill == null) return;

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('SCAN & SERVE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text('GUEST RECEIPT', style: const pw.TextStyle(fontSize: 10))),
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
