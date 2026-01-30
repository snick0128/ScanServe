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
import 'bill_details_screen.dart';
import 'package:scan_serve/utils/screen_scale.dart';

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
    final isMobile = MediaQuery.of(context).size.width < 1100;
    return Scaffold(
      backgroundColor: AdminTheme.scaffoldBackground,
      body: Consumer<BillsProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: EdgeInsets.all(isMobile ? 12.w : 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(provider, isMobile),
                SizedBox(height: isMobile ? 12.h : 24.h),
                Expanded(
                  child: isMobile 
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildKPICards(provider, isMobile),
                            SizedBox(height: 24.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Pending Settlement', 
                                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
                                TextButton.icon(
                                  onPressed: () => _showHistoryDialog(context, provider),
                                  icon: Icon(Ionicons.time_outline, size: 16.w),
                                  label: Text('History', style: TextStyle(fontSize: 12.sp)),
                                  style: TextButton.styleFrom(foregroundColor: AdminTheme.primaryColor),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            _buildPendingBillsTable(provider),
                            SizedBox(height: 24.h),
                            _buildBulkOperations(provider, isMobile),
                          ],
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Pending Settlement', 
                                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
                                    TextButton.icon(
                                      onPressed: () => _showHistoryDialog(context, provider),
                                      icon: Icon(Ionicons.time_outline, size: 18.w),
                                      label: Text('View All History', style: TextStyle(fontSize: 14.sp)),
                                      style: TextButton.styleFrom(foregroundColor: AdminTheme.primaryColor),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                Expanded(child: _buildPendingBillsTable(provider)),
                                SizedBox(height: 24.h),
                                _buildBulkOperations(provider, false),
                              ],
                            ),
                          ),
                          SizedBox(width: 32.w),
                          SizedBox(
                            width: 300.w,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildKPICards(provider, false),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BillsProvider provider, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Billing',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
              ),
              IconButton(
                onPressed: () => provider.refreshBills(),
                icon: Icon(Ionicons.refresh_outline, size: 20.w),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: AdminTheme.cardBackground,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AdminTheme.dividerColor),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search table or bill ID...',
                prefixIcon: Icon(Ionicons.search_outline, size: 18.w),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Billing & Payments',
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: AdminTheme.primaryText,
              ),
            ),
            Text(
              'Live financial control panel',
              style: TextStyle(color: AdminTheme.secondaryText, fontSize: 14.sp),
            ),
          ],
        ),
        SizedBox(width: 48.w),
        Expanded(
          child: Container(
            constraints: BoxConstraints(maxWidth: 400.w),
            height: 48.h,
            decoration: BoxDecoration(
              color: AdminTheme.cardBackground,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AdminTheme.dividerColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4.w, offset: const Offset(0, 2)),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by table, bill ID, or session...',
                hintStyle: TextStyle(color: AdminTheme.secondaryText, fontSize: 13.sp),
                prefixIcon: Icon(Ionicons.search_outline, size: 18.w, color: AdminTheme.secondaryText),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
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
              style: TextStyle(fontWeight: FontWeight.w600, color: AdminTheme.primaryText, fontSize: 14.sp),
            ),
            Text(
              DateFormat('h:mm:ss a').format(_now),
              style: TextStyle(color: AdminTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18.sp),
            ),
          ],
        ),
        SizedBox(width: 24.w),
          IconButton(
          onPressed: () {
            provider.refreshBills();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Billing data refreshed')),
            );
          },
          icon: Icon(Ionicons.refresh_outline, size: 20.w),
          style: IconButton.styleFrom(
            backgroundColor: AdminTheme.cardBackground,
            side: const BorderSide(color: AdminTheme.dividerColor),
          ),
        ),
      ],
    );
  }

  Widget _buildKPICards(BillsProvider provider, bool isMobile) {
    if (isMobile) {
      return Row(
        children: [
          Expanded(
            child: _buildKPICard(
              'Pending',
              '₹${NumberFormat('#,##,###').format(provider.totalPendingAmount)}',
              '${provider.activeSessionsCount} items',
              Ionicons.wallet_outline,
              AdminTheme.critical,
              isMobile: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKPICard(
              'Sales',
              '₹${NumberFormat('#,##,###').format(provider.completedTodayVolume)}',
              '${provider.completedTodayCount} sets',
              Ionicons.checkmark_circle_outline,
              AdminTheme.success,
              isMobile: true,
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _buildKPICard(
          'Total Pending Amount',
          '₹${NumberFormat('#,##,###.00').format(provider.totalPendingAmount)}',
          provider.pendingTrend,
          Ionicons.wallet_outline,
          AdminTheme.critical,
        ),
        const SizedBox(height: 24),
        _buildKPICard(
          'Active Sessions',
          provider.activeSessionsCount.toString(),
          'All tables requiring checkout',
          Ionicons.time_outline,
          AdminTheme.warning,
        ),
        const SizedBox(height: 24),
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

  Widget _buildKPICard(String title, String value, String subtitle, IconData icon, Color color, {bool isMobile = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 12 : 24),
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
              Text(title, style: TextStyle(color: AdminTheme.secondaryText, fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: isMobile ? 18 : 22),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(color: AdminTheme.primaryText, fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: subtitle.contains('+') ? AdminTheme.success : AdminTheme.secondaryText, fontSize: isMobile ? 9 : 11, fontWeight: FontWeight.bold)),
        ],
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
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BillDetailsScreen(bill: bill, tenantId: widget.tenantId),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AdminTheme.dividerColor)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AdminTheme.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Ionicons.receipt_outline, color: AdminTheme.primaryColor, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bill #${bill['billId']?.toString().substring(0, 8) ?? 'N/A'}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
                                  ),
                                  Text(
                                    'Table: ${bill['tableId']} • ${DateFormat('MMM d, h:mm a').format((bill['createdAt'] as Timestamp).toDate())}',
                                    style: const TextStyle(fontSize: 12, color: AdminTheme.secondaryText),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${bill['finalTotal']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AdminTheme.primaryText),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Ionicons.chevron_forward, size: 16, color: AdminTheme.secondaryText),
                          ],
                        ),
                      ),
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

    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          final diff = _now.difference(session.sessionStartedAt);
          final mins = diff.inMinutes;
          
          Color statusColor = AdminTheme.success;
          if (mins > 30) statusColor = AdminTheme.critical;
          else if (mins > 10) statusColor = AdminTheme.warning;

          return Card(
            margin: EdgeInsets.only(bottom: 12.h),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(color: AdminTheme.dividerColor),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8.w, height: 8.w,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                          ),
                          SizedBox(width: 8.w),
                          Text(session.tableName ?? 'T-#', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                        ],
                      ),
                      Text('₹${NumberFormat('#,##,###.00').format(session.totalAmount)}', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryColor, fontSize: 16.sp)),
                    ],
                  ),
                  Divider(height: 24.h),
                  Row(
                    children: [
                      Icon(Ionicons.person_outline, size: 14.w, color: AdminTheme.secondaryText),
                      SizedBox(width: 8.w),
                      Text(session.customerName ?? 'Guest User', 
                        style: TextStyle(fontSize: 13.sp, color: AdminTheme.primaryText)),
                      const Spacer(),
                      Icon(Ionicons.time_outline, size: 14.w, color: AdminTheme.secondaryText),
                      SizedBox(width: 8.w),
                      Text('$mins mins', 
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13.sp)),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleMarkAsPaid(context, provider, session),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            elevation: 0,
                          ),
                          child: Text('Mark as Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      IconButton(
                        onPressed: () => _confirmCancelSession(context, provider, session),
                        icon: Icon(Ionicons.close_circle_outline, color: AdminTheme.critical, size: 20.w),
                        style: IconButton.styleFrom(
                          backgroundColor: AdminTheme.critical.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
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
          columnSpacing: 64,
          columns: const [
            DataColumn(label: Text('TABLE #', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, fontSize: 14))),
            DataColumn(label: Text('CUSTOMER / SESSION', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, fontSize: 14))),
            DataColumn(label: Text('BILL AMOUNT', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, fontSize: 14))),
            DataColumn(label: Text('TIME ELAPSED', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, fontSize: 14))),
            DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.secondaryText, fontSize: 14))),
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
              DataCell(Text('₹${NumberFormat('#,##,###.00').format(session.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryText, fontSize: 15))),
              DataCell(Text('$mins mins', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 15))),
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

  Widget _buildBulkOperations(BillsProvider provider, bool isMobile) {
    final isAdmin = context.read<AdminAuthProvider>().role == 'admin';
    
    if (isMobile) {
      return Column(
        children: [
          OutlinedButton.icon(
            onPressed: isAdmin ? () => _confirmBulkClose(context, provider) : null,
            icon: const Icon(Ionicons.layers_outline, size: 18),
            label: const Text('Bulk Close All'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: AdminTheme.critical,
              side: const BorderSide(color: AdminTheme.critical),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _generateDailyReport(provider),
            icon: const Icon(Ionicons.document_text_outline, size: 18),
            label: const Text('Daily Report'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AdminTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }
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
