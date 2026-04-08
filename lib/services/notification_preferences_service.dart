import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_preferences.dart';

class NotificationPreferencesService {
  static const _storageKey = 'notification_preferences_v1';

  Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const NotificationPreferences();
    }

    try {
      return NotificationPreferences.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const NotificationPreferences();
    }
  }

  Future<void> save(NotificationPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(preferences.toMap()));
  }
}
