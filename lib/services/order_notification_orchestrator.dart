import 'dart:async';
import 'dart:collection';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/order.dart' as model;
import '../models/notification_preferences.dart';
import 'notification_preferences_service.dart';

enum OrderAlertType {
  newOrder,
  orderReady,
  orderUpdated,
  orderCancelled,
  customerRequest,
}

class OrderNotificationOrchestrator {
  OrderNotificationOrchestrator._();
  static final OrderNotificationOrchestrator instance =
      OrderNotificationOrchestrator._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FlutterTts _tts = FlutterTts();
  final NotificationPreferencesService _preferencesService =
      NotificationPreferencesService();
  final Queue<String> _speechQueue = Queue<String>();
  DateTime? _lastSpeechTime;
  String? _lastSpeechText;

  NotificationPreferences _preferences = const NotificationPreferences();
  Timer? _repeatTimer;
  bool _isSpeaking = false;
  bool _isInitialized = false;

  static const AndroidNotificationChannel _alarmChannel =
      AndroidNotificationChannel(
        'orders_alarm',
        'Order Alarm',
        description: 'Critical kitchen and waiter order alarms',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  Future<void> initialize({String role = 'captain'}) async {
    _preferences = await _preferencesService.load();

    if (_isInitialized || kIsWeb) {
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: android),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_alarmChannel);
    await _tts.awaitSpeakCompletion(true);
    _isInitialized = true;
  }

  NotificationPreferences get preferences => _preferences;

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    _preferences = preferences;
    await _preferencesService.save(preferences);
  }

  Future<void> handleForegroundOrderEvent({
    required OrderAlertType type,
    required model.Order order,
    String? speechOverride,
  }) async {
    final summary = _buildSummary(order);
    await _showHeadsUp(order, summary, type);

    switch (type) {
      case OrderAlertType.newOrder:
        await _runAlarmLoop();
        await _speakIfNeeded(speechOverride ?? _buildSpeech(order));
        break;
      case OrderAlertType.orderReady:
        await _playTone(repeats: 3);
        await _speakIfNeeded('Order ready for ${order.tableName ?? "pickup"}');
        break;
      case OrderAlertType.customerRequest:
        await _playTone(repeats: 2);
        break;
      case OrderAlertType.orderUpdated:
      case OrderAlertType.orderCancelled:
        await _playTone(repeats: 1);
        break;
    }
  }

  Future<void> acknowledge() async {
    _repeatTimer?.cancel();
    await _audioPlayer.stop();
  }

  Future<void> snooze([int? seconds]) async {
    await acknowledge();
    final snoozeSeconds = seconds ?? _preferences.snoozeSeconds;
    _repeatTimer = Timer(Duration(seconds: snoozeSeconds), _runAlarmLoop);
  }

  Future<void> _runAlarmLoop() async {
    // Always clear any existing loop before deciding single vs repeat playback.
    _repeatTimer?.cancel();
    _repeatTimer = null;

    if (!_shouldPlaySound || !_preferences.repeatAlarm) {
      await _playTone(repeats: 1);
      return;
    }

    await _playTone(repeats: 1);
    _repeatTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      await _playTone(repeats: 1);
    });
  }

  Future<void> _playTone({required int repeats}) async {
    if (!_shouldPlaySound) return;
    await _audioPlayer.setVolume(_preferences.alarmVolume.clamp(0, 1));
    for (var index = 0; index < repeats; index++) {
      await _audioPlayer.stop();
      await _audioPlayer.play(
        UrlSource(
          'https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3',
        ),
        mode: PlayerMode.mediaPlayer,
      );
      await Future<void>.delayed(const Duration(milliseconds: 1800));
    }
  }

  Future<void> _showHeadsUp(
    model.Order order,
    String summary,
    OrderAlertType type,
  ) async {
    if (!_isInitialized || kIsWeb) return;

    final title = switch (type) {
      OrderAlertType.newOrder => 'New Order ${order.id.substring(0, 8)}',
      OrderAlertType.orderReady => 'Order Ready ${order.id.substring(0, 8)}',
      OrderAlertType.orderUpdated =>
        'Order Updated ${order.id.substring(0, 8)}',
      OrderAlertType.orderCancelled =>
        'Order Cancelled ${order.id.substring(0, 8)}',
      OrderAlertType.customerRequest => 'Customer Request',
    };
    await _localNotifications.show(
      order.id.hashCode,
      title,
      summary,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _alarmChannel.id,
          _alarmChannel.name,
          channelDescription: _alarmChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          ticker: 'scanserve_order_alert',
        ),
      ),
      payload: order.id,
    );
  }

  String _buildSummary(model.Order order) {
    final itemSummary = order.items.take(3).map((item) => item.name).join(', ');
    return '${order.tableName ?? order.tableId ?? "Order"} • $itemSummary';
  }

  String _buildSpeech(model.Order order) {
    final items = order.items
        .map((item) {
          final spice = item.selectedSpiceLevel == null
              ? ''
              : ' ${item.selectedSpiceLevel}';
          return '${item.quantity} ${_normalizeForSpeech(item.name)}$spice';
        })
        .join(', ');
    return '$items for ${order.tableName ?? "pickup"}';
  }

  String _normalizeForSpeech(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return raw;

    final looksAllCaps =
        trimmed == trimmed.toUpperCase() &&
        RegExp(r'[A-Z]').hasMatch(trimmed) &&
        !RegExp(r'[a-z]').hasMatch(trimmed);

    if (!looksAllCaps) return trimmed;

    // Avoid TTS spelling letter-by-letter for uppercase menu names like "LASSI".
    return trimmed
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<void> _speakIfNeeded(String text) async {
    if (!_shouldSpeak || text.trim().isEmpty) return;

    // P1-6: Deduplicate — ignore same text queued within 500ms
    final now = DateTime.now();
    if (_lastSpeechText == text &&
        _lastSpeechTime != null &&
        now.difference(_lastSpeechTime!).inMilliseconds < 500) {
      return;
    }
    _lastSpeechText = text;
    _lastSpeechTime = now;

    _speechQueue.add(text);
    if (_isSpeaking)
      return; // P1-6: Single queue — don't start a second speaker

    _isSpeaking = true;
    try {
      while (_speechQueue.isNotEmpty) {
        final next = _speechQueue.removeFirst();
        await _tts.setSpeechRate(_preferences.voiceSpeed.clamp(0.2, 0.8));
        await _tts.setLanguage(_preferences.languageCode);
        await _tts.speak(next);
      }
    } finally {
      _isSpeaking = false;
    }
  }

  bool get _shouldPlaySound =>
      _preferences.mode == NotificationMode.soundOnly ||
      _preferences.mode == NotificationMode.soundAndVoice;

  bool get _shouldSpeak =>
      _preferences.mode == NotificationMode.voiceOnly ||
      _preferences.mode == NotificationMode.soundAndVoice;
}
