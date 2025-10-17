import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/order_details.dart';
import '../models/order_model.dart';

class WaitTimeService {
  static final WaitTimeService _instance = WaitTimeService._internal();

  factory WaitTimeService() {
    return _instance;
  }

  WaitTimeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream for real-time wait time calculation
  Stream<int> getTotalWaitTimeStream(String tenantId, String tableId) {
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('orders')
        .where('tableId', isEqualTo: tableId)
        .where('type', isEqualTo: OrderType.dineIn.name)
        .where('status', whereIn: [
          OrderStatus.pending.name,
          OrderStatus.preparing.name,
        ])
        .snapshots()
        .map((snapshot) {
          int totalWaitTime = 0;
          for (final doc in snapshot.docs) {
            final order = OrderDetails.fromMap(doc.data());
            if (order.status == OrderStatus.pending ||
                order.status == OrderStatus.preparing) {
              totalWaitTime += order.estimatedWaitTime;
            }
          }
          return totalWaitTime;
        });
  }

  // Get current total wait time (synchronous)
  Future<int> getCurrentTotalWaitTime(String tenantId, String tableId) async {
    try {
      final snapshot = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('orders')
          .where('tableId', isEqualTo: tableId)
          .where('type', isEqualTo: OrderType.dineIn.name)
          .where('status', whereIn: [
            OrderStatus.pending.name,
            OrderStatus.preparing.name,
          ])
          .get();

      int totalWaitTime = 0;
      for (final doc in snapshot.docs) {
        final order = OrderDetails.fromMap(doc.data());
        if (order.status == OrderStatus.pending ||
            order.status == OrderStatus.preparing) {
          totalWaitTime += order.estimatedWaitTime;
        }
      }
      return totalWaitTime;
    } catch (e) {
      debugPrint('Error calculating total wait time: $e');
      return 0;
    }
  }

  // Update wait time for a specific order (useful for Cloud Functions integration)
  Future<void> updateOrderWaitTime(String tenantId, String orderId, int newWaitTime) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('orders')
          .doc(orderId)
          .update({
            'estimatedWaitTime': newWaitTime,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error updating order wait time: $e');
      rethrow;
    }
  }

  // Calculate estimated ready time for an order
  DateTime calculateEstimatedReadyTime(DateTime orderTime, int waitTimeMinutes) {
    return orderTime.add(Duration(minutes: waitTimeMinutes));
  }

  // Get formatted wait time string
  String formatWaitTime(int totalMinutes) {
    if (totalMinutes == 0) {
      return 'Ready now';
    } else if (totalMinutes < 60) {
      return '$totalMinutes min';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }

  // Get wait time color based on duration
  Color getWaitTimeColor(int totalMinutes) {
    if (totalMinutes <= 15) {
      return Colors.green;
    } else if (totalMinutes <= 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
