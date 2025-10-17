import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class GuestSessionService {
  static const String _guestIdKey = 'guest_id';
  static const String _currentTenantKey = 'current_tenant';
  static const String _currentTableKey = 'current_table';

  final _prefs = SharedPreferences.getInstance();
  final _uuid = const Uuid();

  Future<String> getOrCreateGuestId() async {
    final prefs = await _prefs;
    String? guestId = prefs.getString(_guestIdKey);

    if (guestId == null) {
      guestId = _uuid.v4();
      await prefs.setString(_guestIdKey, guestId);
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
}
