import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Guest Session Service
/// 
/// Manages persistent guest identification across browser tabs and sessions.
/// Uses SharedPreferences to store a single UUID per device/browser.
/// This ensures that one device always has the same guestId, even when
/// opening multiple tabs or refreshing the page.
class GuestSessionService {
  static const String _guestIdKey = 'guest_id';
  static const String _currentTenantKey = 'current_tenant';
  static const String _currentTableKey = 'current_table';

  final _prefs = SharedPreferences.getInstance();
  final _uuid = const Uuid();

  /// Get or create a persistent guest ID
  /// This ID is stored in SharedPreferences and persists across:
  /// - Multiple browser tabs
  /// - Page refreshes
  /// - App restarts
  /// Returns the same UUID for the same device/browser
  Future<String> getOrCreateGuestId() async {
    final prefs = await _prefs;
    String? guestId = prefs.getString(_guestIdKey);

    if (guestId == null) {
      guestId = _uuid.v4();
      await prefs.setString(_guestIdKey, guestId);
      print('🆕 Created new persistent guestId: $guestId');
    } else {
      print('♻️ Retrieved existing guestId: $guestId');
    }

    return guestId;
  }

  Future<String> getGuestId() async {
    return getOrCreateGuestId();
  }

  Future<void> startSession({required String tenantId, String? tableId}) async {
    final prefs = await _prefs;
    await prefs.setString(_currentTenantKey, tenantId);
    if (tableId != null) {
      await prefs.setString(_currentTableKey, tableId);
    }
  }

  Future<Map<String, String?>> getCurrentSession() async {
    final prefs = await _prefs;
    return {
      'tenantId': prefs.getString(_currentTenantKey),
      'tableId': prefs.getString(_currentTableKey),
      'guestId': prefs.getString(_guestIdKey),
    };
  }

  Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_currentTenantKey);
    await prefs.remove(_currentTableKey);
  }

  /// Clear the guest ID and all session data
  /// This will force creation of a new guestId on next app load
  /// Use this for testing or when user wants to start completely fresh
  Future<void> clearGuestId() async {
    final prefs = await _prefs;
    await prefs.remove(_guestIdKey);
    await prefs.remove(_currentTenantKey);
    await prefs.remove(_currentTableKey);
    print('🗑️ Cleared guest session - new guestId will be created on next load');
  }
}
