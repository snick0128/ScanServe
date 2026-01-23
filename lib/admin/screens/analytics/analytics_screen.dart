import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/analytics_provider.dart';
import '../../services/export_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/all_items_performance_dialog.dart';

class AnalyticsScreen extends StatefulWidget {
  final String tenantId;
  const AnalyticsScreen({super.key, required this.tenantId});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AdminTheme.primaryColor));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(provider),
                const SizedBox(height: 32),
                _buildKPISection(provider),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildRevenueChart(provider)),
                    const SizedBox(width: 32),
                    Expanded(flex: 1, child: _buildTopItems(provider)),
                  ],
                ),
                const SizedBox(height: 32),
                _buildCategoryDistribution(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AnalyticsProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Operational Reports',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
            ),
            const SizedBox(height: 4),
            Text(
              'View performance metrics and analytics for your restaurant.',
              style: TextStyle(color: AdminTheme.secondaryText, fontSize: 16),
            ),
          ],
        ),
        Row(
          children: [
            _buildDateFilter(provider),
            const SizedBox(width: 16),
            _buildExportButton(provider),
          ],
        ),
      ],
    );
  }

  Widget _buildDateFilter(AnalyticsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Today', 'Week', 'Month'].map((f) {
          final isSelected = provider.dateFilter == f;
          return GestureDetector(
            onTap: () => provider.setDateFilter(f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: isSelected ? AdminTheme.primaryText : AdminTheme.secondaryText,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExportButton(AnalyticsProvider provider) {
    return ElevatedButton.icon(
      onPressed: () => ExportService.exportAnalyticsToPdf(provider),
      icon: const Icon(Ionicons.download_outline, size: 20),
      label: const Text('Export Report'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AdminTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildKPISection(AnalyticsProvider provider) {
    return Row(
      children: [
        _buildKPICard('Total Revenue', '₹${NumberFormat('#,##,###').format(provider.totalRevenue)}', provider.revenueTrend, Ionicons.cash_outline),
        const SizedBox(width: 24),
        _buildKPICard('Total Orders', provider.totalOrders.toString(), provider.ordersTrend, Ionicons.cart_outline),
        const SizedBox(width: 24),
        _buildKPICard('Avg Order Value', '₹${provider.avgOrderValue.toStringAsFixed(2)}', provider.aovTrend, Ionicons.analytics_outline),
        const SizedBox(width: 24),
        _buildKPICard('Active Tables', provider.activeTablesCount.toString(), provider.tablesTrend, Ionicons.restaurant_outline),
      ],
    );
  }

  Widget _buildKPICard(String label, String value, double trend, IconData icon) {
    final isPositive = trend >= 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F3F4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AdminTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: AdminTheme.primaryColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? AdminTheme.success : AdminTheme.critical).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}$trend%',
                    style: TextStyle(
                      color: isPositive ? AdminTheme.success : AdminTheme.critical,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(label, style: const TextStyle(fontSize: 14, color: AdminTheme.secondaryText)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AdminTheme.primaryText)),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(AnalyticsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(32),
      height: 450,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F3F4)),
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
                  const Text('Daily Revenue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Hourly performance analysis', style: TextStyle(color: AdminTheme.secondaryText, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: AdminTheme.primaryColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('REVENUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 4,
                      getTitlesWidget: (val, meta) {
                        String text = '';
                        int hour = val.toInt();
                        if (hour == 8) text = '08 AM';
                        if (hour == 12) text = '12 PM';
                        if (hour == 16) text = '04 PM';
                        if (hour == 20) text = '08 PM';
                        return Text(text, style: const TextStyle(color: AdminTheme.secondaryText, fontSize: 11));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (val, meta) {
                        return Text('₹${val.toInt()}', style: const TextStyle(color: AdminTheme.secondaryText, fontSize: 11));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: provider.hourlyRevenue.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: AdminTheme.primaryColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AdminTheme.primaryColor.withOpacity(0.2), AdminTheme.primaryColor.withOpacity(0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AdminTheme.primaryText,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '₹${NumberFormat('#,###').format(spot.y)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItems(AnalyticsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(32),
      height: 450,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F3F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Performing Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Most popular orders today', style: TextStyle(color: AdminTheme.secondaryText, fontSize: 13)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: provider.topItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final item = provider.topItems[index];
                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: item['imageUrl'] != null
                          ? Image.network(item['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                          : Container(color: const Color(0xFFF1F3F4), width: 50, height: 50),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('${item['units']} units sold', style: TextStyle(color: AdminTheme.secondaryText, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${NumberFormat('#,###').format(item['revenue'])}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.primaryColor)),
                        if (index == 0) ...[
                          const SizedBox(height: 4),
                          const Text('Top Choice', style: TextStyle(color: AdminTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AllItemsPerformanceDialog(items: provider.topItems),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFF1F3F4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View All Items', style: TextStyle(color: AdminTheme.primaryText, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution(AnalyticsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F3F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Category Distribution', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () {}, icon: const Icon(Ionicons.ellipsis_horizontal, color: AdminTheme.secondaryText)),
            ],
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 8,
                        centerSpaceRadius: 60,
                        sections: _buildPieSections(provider),
                      ),
                    ),
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('100%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('TOTAL', style: TextStyle(fontSize: 10, color: AdminTheme.secondaryText, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 80),
              Expanded(
                child: Wrap(
                  spacing: 48,
                  runSpacing: 24,
                  children: provider.categorySales.entries.map((e) {
                    final index = provider.categorySales.keys.toList().indexOf(e.key);
                    final color = _getCategoryColor(index);
                    final percentage = (e.value / provider.totalRevenue * 100).toInt();
                    return SizedBox(
                      width: 280,
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('$percentage% of total sales', style: TextStyle(color: AdminTheme.secondaryText, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('₹${NumberFormat('#,###').format(e.value)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(AnalyticsProvider provider) {
    if (provider.totalRevenue == 0) return [];
    return provider.categorySales.entries.map((e) {
      final index = provider.categorySales.keys.toList().indexOf(e.key);
      return PieChartSectionData(
        color: _getCategoryColor(index),
        value: e.value,
        title: '',
        radius: 20,
      );
    }).toList();
  }

  Color _getCategoryColor(int index) {
    final colors = [
      AdminTheme.primaryColor,
      const Color(0xFFFBB03B),
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
    ];
    return colors[index % colors.length];
  }
}
