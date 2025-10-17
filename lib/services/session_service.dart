import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Keys for local storage
  static const String _orderTypeKey = 'order_type';
  static const String _tableIdKey = 'table_id';

  /// Get the last used order type from local storage
  Future<OrderType?> getLastOrderType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderTypeString = prefs.getString(_orderTypeKey);
      if (orderTypeString != null) {
        return OrderType.values.firstWhere(
          (type) => type.name == orderTypeString,
          orElse: () => OrderType.parcel,
        );
      }
      return null;
    } catch (e) {
      print('Error getting last order type: $e');
      return null;
    }
  }

  /// Save the order type to local storage
  Future<void> saveOrderType(OrderType orderType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_orderTypeKey, orderType.name);
    } catch (e) {
      print('Error saving order type: $e');
    }
  }

  /// Get the last used table ID from local storage
  Future<String?> getLastTableId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tableIdKey);
    } catch (e) {
      print('Error getting last table ID: $e');
      return null;
    }
  }

  /// Save the table ID to local storage
  Future<void> saveTableId(String tableId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tableIdKey, tableId);
    } catch (e) {
      print('Error saving table ID: $e');
    }
  }

  /// Clear all session data
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_orderTypeKey);
      await prefs.remove(_tableIdKey);
    } catch (e) {
      print('Error clearing session: $e');
    }
  }

  /// Create a guest session in Firestore
  Future<String> createGuestSession(String tenantId) async {
    try {
      final guestId = DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore.collection('guest_sessions').doc(guestId).set({
        'guestId': guestId,
        'tenantId': tenantId,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      return guestId;
    } catch (e) {
      print('Error creating guest session: $e');
      rethrow;
    }
  }

  /// Update guest session with order type
  Future<void> updateGuestSession(String guestId, OrderType orderType, {String? tableId}) async {
    try {
      final updateData = {
        'orderType': orderType.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (tableId != null) {
        updateData['tableId'] = tableId;
      }

      await _firestore.collection('guest_sessions').doc(guestId).update(updateData);
    } catch (e) {
      print('Error updating guest session: $e');
    }
  }

  /// Get guest session data
  Future<Map<String, dynamic>?> getGuestSession(String guestId) async {
    try {
      final doc = await _firestore.collection('guest_sessions').doc(guestId).get();
      return doc.data();
    } catch (e) {
      print('Error getting guest session: $e');
      return null;
    }
  }
}
