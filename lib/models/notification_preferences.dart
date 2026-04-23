enum NotificationMode { soundOnly, voiceOnly, soundAndVoice }

class NotificationPreferences {
  final NotificationMode mode;
  final double voiceSpeed;
  final String languageCode;
  final bool readItems;
  final bool repeatAlarm;
  final double alarmVolume;
  final int snoozeSeconds;

  const NotificationPreferences({
    this.mode = NotificationMode.soundAndVoice,
    this.voiceSpeed = 0.5,
    this.languageCode = 'en-IN',
    this.readItems = true,
    this.repeatAlarm = false,
    this.alarmVolume = 1,
    this.snoozeSeconds = 10,
  });

  Map<String, dynamic> toMap() {
    return {
      'mode': mode.name,
      'voiceSpeed': voiceSpeed,
      'languageCode': languageCode,
      'readItems': readItems,
      'repeatAlarm': repeatAlarm,
      'alarmVolume': alarmVolume,
      'snoozeSeconds': snoozeSeconds,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      mode: NotificationMode.values.firstWhere(
        (value) => value.name == map['mode'],
        orElse: () => NotificationMode.soundAndVoice,
      ),
      voiceSpeed: (map['voiceSpeed'] as num?)?.toDouble() ?? 0.5,
      languageCode: map['languageCode']?.toString() ?? 'en-IN',
      readItems: map['readItems'] != false,
      repeatAlarm: map['repeatAlarm'] == true,
      alarmVolume: (map['alarmVolume'] as num?)?.toDouble() ?? 1,
      snoozeSeconds: (map['snoozeSeconds'] as num?)?.toInt() ?? 10,
    );
  }

  NotificationPreferences copyWith({
    NotificationMode? mode,
    double? voiceSpeed,
    String? languageCode,
    bool? readItems,
    bool? repeatAlarm,
    double? alarmVolume,
    int? snoozeSeconds,
  }) {
    return NotificationPreferences(
      mode: mode ?? this.mode,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
      languageCode: languageCode ?? this.languageCode,
      readItems: readItems ?? this.readItems,
      repeatAlarm: repeatAlarm ?? this.repeatAlarm,
      alarmVolume: alarmVolume ?? this.alarmVolume,
      snoozeSeconds: snoozeSeconds ?? this.snoozeSeconds,
    );
  }
}
