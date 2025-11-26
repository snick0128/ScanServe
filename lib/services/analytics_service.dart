import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, double>> getDailyRevenue(String tenantId, {int days = 7}) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
      
      final snapshot = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('status', whereIn: ['completed', 'served'])
          .get();

      // Group by date
      final Map<String, double> revenueByDate = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final dateKey = '${timestamp.day}/${timestamp.month}';
        final total = (data['total'] ?? 0).toDouble();
        
        revenueByDate[dateKey] = (revenueByDate[dateKey] ?? 0) + total;
      }

      return revenueByDate;
    } catch (e) {
      print('Error fetching daily revenue: $e');
      return {};
    }
  }

  Future<Map<String, int>> getTopSellingItems(String tenantId, {int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('orders')
          .where('status', whereIn: ['completed', 'served'])
          .get();

      // Count items
      final Map<String, int> itemCounts = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final items = data['items'] as List<dynamic>? ?? [];
        
        for (var item in items) {
          final itemName = item['name'] ?? 'Unknown';
          final quantity = item['quantity'] ?? 1;
          itemCounts[itemName] = (itemCounts[itemName] ?? 0) + (quantity as int);
        }
      }

      // Sort and limit
      final sorted = itemCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return Map.fromEntries(sorted.take(limit));
    } catch (e) {
      print('Error fetching top selling items: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getOverallStats(String tenantId) async {
    try {
      final snapshot = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('orders')
          .get();

      int totalOrders = snapshot.docs.length;
      double totalRevenue = 0;
      int completedOrders = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'];
        final total = (data['total'] ?? 0).toDouble();
        
        totalRevenue += total;
        if (status == 'completed' || status == 'served') {
          completedOrders++;
        }
      }

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'completedOrders': completedOrders,
        'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
      };
    } catch (e) {
      print('Error fetching overall stats: $e');
      return {
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'completedOrders': 0,
        'averageOrderValue': 0.0,
      };
    }
  }
}
