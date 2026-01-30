import 'package:shared_preferences/shared_preferences.dart';

/// Order Confirmation Tracker
/// 
/// Prevents duplicate orders on page refresh by tracking successfully placed orders.
/// Uses localStorage to persist across app restarts/refreshes.
class OrderConfirmationTracker {
  static const String _keyPrefix = 'order_confirmed_';
  static const Duration _confirmationTTL = Duration(hours: 24);

  /// Mark an order as confirmed (successfully placed)
  static Future<void> markOrderConfirmed({
    required String tenantId,
    required String? tableId,
    required String orderId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _generateKey(tenantId, tableId);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    await prefs.setString(key, '$orderId|$timestamp');
    print('✅ Order confirmed: $orderId for $key');
  }

  /// Check if an order was recently confirmed for this session
  static Future<String?> getConfirmedOrderId({
    required String tenantId,
    required String? tableId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _generateKey(tenantId, tableId);
    final value = prefs.getString(key);
    
    if (value == null) return null;

    try {
      final parts = value.split('|');
      if (parts.length != 2) return null;

      final orderId = parts[0];
      final timestamp = int.parse(parts[1]);
      final confirmedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      
      // Check if confirmation is still valid (within TTL)
      if (DateTime.now().difference(confirmedAt) > _confirmationTTL) {
        await clearConfirmation(tenantId: tenantId, tableId: tableId);
        return null;
      }

      return orderId;
    } catch (e) {
      print('Error parsing confirmation: $e');
      return null;
    }
  }

  /// Clear order confirmation (when starting new session or after payment)
  static Future<void> clearConfirmation({
    required String tenantId,
    required String? tableId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _generateKey(tenantId, tableId);
    await prefs.remove(key);
    print('🗑️ Cleared order confirmation for $key');
  }

  /// Check if cart should be cleared (order was confirmed)
  static Future<bool> shouldClearCart({
    required String tenantId,
    required String? tableId,
  }) async {
    final confirmedOrderId = await getConfirmedOrderId(
      tenantId: tenantId,
      tableId: tableId,
    );
    return confirmedOrderId != null;
  }

  static String _generateKey(String tenantId, String? tableId) {
    return '$_keyPrefix${tenantId}_${tableId ?? 'parcel'}';
  }

  /// Cleanup old confirmations (call periodically)
  static Future<void> cleanupOldConfirmations() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    
    for (final key in keys) {
      final value = prefs.getString(key);
      if (value == null) continue;

      try {
        final parts = value.split('|');
        if (parts.length != 2) continue;

        final timestamp = int.parse(parts[1]);
        final confirmedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
        
        if (DateTime.now().difference(confirmedAt) > _confirmationTTL) {
          await prefs.remove(key);
          print('🗑️ Cleaned up old confirmation: $key');
        }
      } catch (e) {
        // Invalid format, remove it
        await prefs.remove(key);
      }
    }
  }
}
