import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  final String tenantId;

  const AnalyticsScreen({super.key, required this.tenantId});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  Map<String, double> _dailyRevenue = {};
  Map<String, int> _topItems = {};
  Map<String, dynamic> _stats = {};
  
  // Time filter: 'today', 'week', 'month'
  String _selectedTimeFilter = 'week';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Calculate date range based on filter
      final now = DateTime.now();
      DateTime startDate;
      
      switch (_selectedTimeFilter) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = now.subtract(const Duration(days: 30));
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }
      
      final revenue = await _analyticsService.getDailyRevenue(widget.tenantId);
      final items = await _analyticsService.getTopSellingItems(widget.tenantId);
      final stats = await _analyticsService.getOverallStats(widget.tenantId);
      
      setState(() {
        _dailyRevenue = revenue;
        _topItems = items;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _getFilterLabel() {
    switch (_selectedTimeFilter) {
      case 'today':
        return 'Today';
      case 'week':
        return 'Last 7 Days';
      case 'month':
        return 'Last 30 Days';
      default:
        return 'Last 7 Days';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Filter Chips
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'Time Period:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: const Text('Today'),
                        selected: _selectedTimeFilter == 'today',
                        onSelected: (selected) {
                          setState(() {
                            _selectedTimeFilter = 'today';
                            _loadData();
                          });
                        },
                        selectedColor: Colors.blue.withOpacity(0.3),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Last 7 Days'),
                        selected: _selectedTimeFilter == 'week',
                        onSelected: (selected) {
                          setState(() {
                            _selectedTimeFilter = 'week';
                            _loadData();
                          });
                        },
                        selectedColor: Colors.blue.withOpacity(0.3),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Last 30 Days'),
                        selected: _selectedTimeFilter == 'month',
                        onSelected: (selected) {
                          setState(() {
                            _selectedTimeFilter = 'month';
                            _loadData();
                          });
                        },
                        selectedColor: Colors.blue.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stats Cards
              if (isMobile)
                Column(
                  children: [
                    _buildStatCard(
                      'Total Orders',
                      '${_stats['totalOrders'] ?? 0}',
                      Icons.shopping_cart,
                      Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Total Revenue',
                      '₹${(_stats['totalRevenue'] ?? 0).toStringAsFixed(0)}',
                      Icons.currency_rupee,
                      Colors.green,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Avg Order Value',
                      '₹${(_stats['averageOrderValue'] ?? 0).toStringAsFixed(0)}',
                      Icons.trending_up,
                      Colors.orange,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Orders',
                        '${_stats['totalOrders'] ?? 0}',
                        Icons.shopping_cart,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Total Revenue',
                        '₹${(_stats['totalRevenue'] ?? 0).toStringAsFixed(0)}',
                        Icons.currency_rupee,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Avg Order Value',
                        '₹${(_stats['averageOrderValue'] ?? 0).toStringAsFixed(0)}',
                        Icons.trending_up,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),

              // Revenue Chart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Revenue Trend (${_getFilterLabel()})',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (_dailyRevenue.isNotEmpty)
                    Text(
                      '₹${_dailyRevenue.values.reduce((a, b) => a + b).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: _dailyRevenue.isEmpty
                    ? const Center(child: Text('No revenue data available'))
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _dailyRevenue.values.isEmpty ? 100 : _dailyRevenue.values.reduce((a, b) => a > b ? a : b) * 1.2,
                          barGroups: _dailyRevenue.entries.map((entry) {
                            final index = _dailyRevenue.keys.toList().indexOf(entry.key);
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value,
                                  color: Colors.blue,
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ],
                            );
                          }).toList(),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '₹${value.toInt()}',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final keys = _dailyRevenue.keys.toList();
                                  if (value.toInt() >= 0 && value.toInt() < keys.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        keys[value.toInt()],
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: _dailyRevenue.values.isEmpty 
                              ? 20 
                              : (_dailyRevenue.values.reduce((a, b) => a > b ? a : b) * 1.2) / 5,
                          ),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final keys = _dailyRevenue.keys.toList();
                                return BarTooltipItem(
                                  '${keys[group.x.toInt()]}\n₹${rod.toY.toStringAsFixed(0)}',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 32),

              // Top Items
              const Text(
                'Top Selling Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              if (_topItems.isEmpty)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(child: Text('No sales data available')),
                )
              else
                isMobile
                    ? Column(
                        children: [
                          Container(
                            height: 300,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: PieChart(
                              PieChartData(
                                sections: _topItems.entries.map((entry) {
                                  final index = _topItems.keys.toList().indexOf(entry.key);
                                  final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
                                  return PieChartSectionData(
                                    value: entry.value.toDouble(),
                                    title: '${entry.value}',
                                    color: colors[index % colors.length],
                                    radius: 100,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  );
                                }).toList(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 300,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              itemCount: _topItems.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final entry = _topItems.entries.elementAt(index);
                                final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colors[index % colors.length].withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '#${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: colors[index % colors.length],
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    entry.key,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  trailing: Text(
                                    '${entry.value} sold',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pie Chart
                          Expanded(
                            child: Container(
                              height: 300,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: PieChart(
                                PieChartData(
                                  sections: _topItems.entries.map((entry) {
                                    final index = _topItems.keys.toList().indexOf(entry.key);
                                    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
                                    return PieChartSectionData(
                                      value: entry.value.toDouble(),
                                      title: '${entry.value}',
                                      color: colors[index % colors.length],
                                      radius: 100,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    );
                                  }).toList(),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // List
                          Expanded(
                            child: Container(
                              height: 300,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: ListView.separated(
                                itemCount: _topItems.length,
                                separatorBuilder: (context, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  final entry = _topItems.entries.elementAt(index);
                                  final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: colors[index % colors.length].withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '#${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: colors[index % colors.length],
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      entry.key,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    trailing: Text(
                                      '${entry.value} sold',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
