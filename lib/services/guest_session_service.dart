import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/guest_profile_model.dart';

/// Guest Session Service
/// 
/// Manages persistent guest identification across browser tabs and sessions.
/// Uses SharedPreferences to store a single UUID per device/browser.
/// This ensures that one device always has the same guestId, even when
/// opening multiple tabs or refreshing the page.
/// 
/// Also manages guest profile (name + phone) to prevent duplicate customer
/// records and enable prefilling of customer details.
class GuestSessionService {
  static const String _guestIdKey = 'guest_id';
  static const String _currentTenantKey = 'current_tenant';
  static const String _currentTableKey = 'current_table';
  static const String _guestProfileKey = 'guest_profile';

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
    await prefs.remove(_guestProfileKey);
    print('🗑️ Cleared guest session - new guestId will be created on next load');
  }

  // ============================================================
  // GUEST PROFILE MANAGEMENT
  // ============================================================

  /// Save guest profile to local storage
  /// This stores customer name and phone to prevent duplicate records
  /// and enable prefilling of customer details
  Future<void> saveGuestProfile(GuestProfile profile) async {
    final prefs = await _prefs;
    await prefs.setString(_guestProfileKey, profile.toJsonString());
    print('💾 Saved guest profile: ${profile.name}');
  }

  /// Get saved guest profile from local storage
  /// Returns null if no profile exists
  Future<GuestProfile?> getGuestProfile() async {
    final prefs = await _prefs;
    final profileJson = prefs.getString(_guestProfileKey);
    
    if (profileJson == null) {
      print('📭 No guest profile found');
      return null;
    }

    try {
      final profile = GuestProfile.fromJsonString(profileJson);
      print('📬 Retrieved guest profile: ${profile.name}');
      return profile;
    } catch (e) {
      print('❌ Error parsing guest profile: $e');
      return null;
    }
  }

  /// Update guest profile with new name and/or phone
  /// Creates a new profile if none exists
  Future<void> updateGuestProfile({
    required String name,
    String? phone,
  }) async {
    final guestId = await getGuestId();
    final existingProfile = await getGuestProfile();

    final updatedProfile = existingProfile?.copyWith(
      name: name,
      phone: phone,
    ) ?? GuestProfile.create(
      guestId: guestId,
      name: name,
      phone: phone,
    );

    await saveGuestProfile(updatedProfile);
  }

  /// Check if a guest profile exists
  Future<bool> hasGuestProfile() async {
    final prefs = await _prefs;
    return prefs.containsKey(_guestProfileKey);
  }

  /// Clear only the guest profile (keeps guestId and session)
  Future<void> clearGuestProfile() async {
    final prefs = await _prefs;
    await prefs.remove(_guestProfileKey);
    print('🗑️ Cleared guest profile');
  }
}
