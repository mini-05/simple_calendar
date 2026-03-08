// v4.5.0
// lib/models/models.dart
// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart'; // 💡 필수: debugPrint 및 Freezed 디버깅 지원
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';

// ── Enum 정의 ────────────────────────────────────────────────────

enum AppTheme { apple, samsung, naver, darkNeon, classicBlue, todoSky }

enum CalendarNavMode {
  arrow(label: '화살표 버튼'),
  swipeVertical(label: '상하 스와이프'),
  swipeHorizontal(label: '좌우 스와이프');

  const CalendarNavMode({required this.label});
  final String label;
}

enum WidgetTheme { flip, circle, classic, astronomical }

extension WidgetThemeExt on WidgetTheme {
  String get label => switch (this) {
    WidgetTheme.flip => 'Flip (블루)',
    WidgetTheme.circle => 'Circle (네온)',
    WidgetTheme.classic => 'Classic (그린)',
    WidgetTheme.astronomical => 'Astronomical (우주)',
  };
}

enum AlarmMode { silent, soundOnly, vibrationOnly, soundAndVibration }

extension AlarmModeExt on AlarmMode {
  String get label => switch (this) {
    AlarmMode.silent => '무음',
    AlarmMode.soundOnly => '소리',
    AlarmMode.vibrationOnly => '진동',
    AlarmMode.soundAndVibration => '소리+진동',
  };
}

enum NotificationSound {
  system(label: '기본 시스템 소리', fileName: ''),
  chime(label: '맑은 종소리', fileName: 'chime'),
  bell(label: '경쾌한 벨소리', fileName: 'bell'),
  bird(label: '새소리', fileName: 'bird'),
  waterDrop(label: '물방울', fileName: 'water_drop'),
  rain(label: '빗소리', fileName: 'rain'),
  pianoMelody(label: '피아노 멜로디', fileName: 'piano_melody'),
  wind(label: '바람 소리', fileName: 'wind'),
  wave(label: '파도 소리', fileName: 'wave'),
  custom(label: '🎵 내 휴대폰 음악', fileName: 'custom');

  const NotificationSound({required this.label, required this.fileName});
  final String label;
  final String fileName;
}

enum VibrationPattern {
  defaultPulse(label: '기본 진동', pattern: [0, 400, 200, 400]),
  heartbeat(label: '심장 박동', pattern: [0, 150, 150, 150, 800, 150, 150, 150]),
  crescendo(label: '크레센도', pattern: [0, 400, 300, 200, 150, 100, 100, 50, 50]),
  longPulse(label: '길게 한 번', pattern: [0, 800]),
  doublePulse(label: '짧게 두 번', pattern: [0, 150, 100, 150]),
  longThenDouble(label: '길게 후 짧게 두 번', pattern: [0, 600, 150, 150, 100, 150]),
  escalating(label: '점점 강해짐', pattern: [0, 100, 100, 200, 100, 300, 100, 400]),
  sos(
    label: 'SOS',
    pattern: [
      0,
      150,
      100,
      150,
      100,
      150,
      200,
      400,
      100,
      400,
      100,
      400,
      200,
      150,
      100,
      150,
      100,
      150,
    ],
  ),
  siren(label: '사이렌', pattern: [0, 500, 150, 300, 150, 500, 150, 300]);

  const VibrationPattern({required this.label, required this.pattern});
  final String label;
  final List<int> pattern;
  Int64List get patternInt64 => Int64List.fromList(pattern);
}

enum AlarmMinutes {
  none(label: '알림 없음', minutes: -1),
  atTime(label: '정각', minutes: 0),
  min5(label: '5분 전', minutes: 5),
  min10(label: '10분 전', minutes: 10),
  min30(label: '30분 전', minutes: 30),
  hour1(label: '1시간 전', minutes: 60),
  day1(label: '1일 전', minutes: 1440);

  const AlarmMinutes({required this.label, required this.minutes});
  final String label;
  final int minutes;
}

enum RecurrenceFrequency {
  daily(label: '매일'),
  weekly(label: '매주'),
  monthly(label: '매월'),
  yearly(label: '매년');

  const RecurrenceFrequency({required this.label});
  final String label;
}

const int defaultEventColor = 0xFF2196F3;

// ── 헬퍼 ────────────────────────────────────────────────────────

T _safeEnum<T>(List<T> values, int? raw, int fallback) {
  return values[(raw ?? fallback).clamp(0, values.length - 1)];
}

DateTime _safeParse(String? s) {
  return DateTime.tryParse(s ?? '') ?? DateTime.now();
}

// ── RecurrenceRule ───────────────────────────────────────────────

class RecurrenceRule {
  final RecurrenceFrequency frequency;
  final int interval;
  final DateTime? until;

  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.until,
  });

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.index,
      'interval': interval,
      'until': until?.toIso8601String(),
    };
  }

  factory RecurrenceRule.fromJson(Map<String, dynamic> j) {
    return RecurrenceRule(
      frequency: _safeEnum(
        RecurrenceFrequency.values,
        j['frequency'] as int?,
        0,
      ),
      interval: j['interval'] as int? ?? 1,
      until:
          j['until'] != null ? DateTime.tryParse(j['until'] as String) : null,
    );
  }

  List<DateTime> expand(
    DateTime start, {
    required DateTime from,
    required DateTime to,
  }) {
    final result = <DateTime>[];
    var cur = start;
    int count = 0;
    const int maxExpansions = 5000;

    while (count < maxExpansions) {
      if (until != null && cur.isAfter(until!)) break;
      if (cur.isAfter(to)) break;

      if (!cur.isBefore(from)) {
        result.add(cur);
      }
      cur = _advance(cur);
      count++;
    }

    if (count >= maxExpansions) {
      debugPrint('[RecurrenceRule] 경고: 최대 확장 한도 도달 (무한루프 방지 작동)');
    }
    return result;
  }

  DateTime _advance(DateTime d) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return d.add(Duration(days: interval));
      case RecurrenceFrequency.weekly:
        return d.add(Duration(days: 7 * interval));
      case RecurrenceFrequency.monthly:
        final lastDay = DateTime(d.year, d.month + interval + 1, 0).day;
        return DateTime(d.year, d.month + interval, d.day.clamp(1, lastDay));
      case RecurrenceFrequency.yearly:
        final lastDay = DateTime(d.year + interval, d.month + 1, 0).day;
        return DateTime(d.year + interval, d.month, d.day.clamp(1, lastDay));
    }
  }
}

// ── AppSettings ──────────────────────────────────────────────────

class AppSettings {
  final bool showLunarCalendar;
  final bool showHolidays;
  final bool masterEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool globalSilentMode;
  final NotificationSound soundOption;
  final VibrationPattern vibrationPattern;
  final String? customSoundPath;
  final AppTheme currentTheme;
  final CalendarNavMode calendarNavMode;
  final WidgetTheme dynamicWidgetTheme;
  final bool showSplash;
  final bool preventCapture;

  const AppSettings({
    this.showLunarCalendar = false,
    this.showHolidays = true,
    this.masterEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.globalSilentMode = false,
    this.soundOption = NotificationSound.system,
    this.vibrationPattern = VibrationPattern.heartbeat,
    this.customSoundPath,
    this.currentTheme = AppTheme.samsung,
    this.calendarNavMode = CalendarNavMode.swipeHorizontal,
    this.dynamicWidgetTheme = WidgetTheme.flip,
    this.showSplash = true,
    this.preventCapture = true,
  });

  AlarmMode get effectiveMode {
    if (globalSilentMode) return AlarmMode.silent;
    if (soundEnabled && vibrationEnabled) return AlarmMode.soundAndVibration;
    if (soundEnabled) return AlarmMode.soundOnly;
    if (vibrationEnabled) return AlarmMode.vibrationOnly;
    return AlarmMode.silent;
  }

  Map<String, dynamic> toJson() {
    return {
      'showLunarCalendar': showLunarCalendar,
      'showHolidays': showHolidays,
      'masterEnabled': masterEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'globalSilentMode': globalSilentMode,
      'soundOption': soundOption.index,
      'vibrationPattern': vibrationPattern.index,
      'customSoundPath': customSoundPath,
      'currentTheme': currentTheme.index,
      'calendarNavMode': calendarNavMode.index,
      'dynamicWidgetTheme': dynamicWidgetTheme.index,
      'showSplash': showSplash,
      'preventCapture': preventCapture,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    return AppSettings(
      showLunarCalendar: j['showLunarCalendar'] ?? false,
      showHolidays: j['showHolidays'] ?? true,
      masterEnabled: j['masterEnabled'] ?? true,
      soundEnabled: j['soundEnabled'] ?? true,
      vibrationEnabled: j['vibrationEnabled'] ?? true,
      globalSilentMode: j['globalSilentMode'] ?? false,
      soundOption: _safeEnum(
        NotificationSound.values,
        j['soundOption'] as int?,
        0,
      ),
      vibrationPattern: _safeEnum(
        VibrationPattern.values,
        j['vibrationPattern'] as int?,
        1,
      ),
      customSoundPath: j['customSoundPath'],
      currentTheme: _safeEnum(
        AppTheme.values,
        j['currentTheme'] as int?,
        AppTheme.samsung.index,
      ),
      calendarNavMode: _safeEnum(
        CalendarNavMode.values,
        j['calendarNavMode'] as int?,
        2,
      ),
      dynamicWidgetTheme: _safeEnum(
        WidgetTheme.values,
        j['dynamicWidgetTheme'] as int?,
        0,
      ),
      showSplash: j['showSplash'] ?? true,
      preventCapture: j['preventCapture'] ?? true,
    );
  }

  AppSettings copyWith({
    bool? showLunarCalendar,
    bool? showHolidays,
    bool? masterEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? globalSilentMode,
    NotificationSound? soundOption,
    VibrationPattern? vibrationPattern,
    String? customSoundPath,
    bool clearCustom = false,
    AppTheme? currentTheme,
    CalendarNavMode? calendarNavMode,
    WidgetTheme? dynamicWidgetTheme,
    bool? showSplash,
    bool? preventCapture,
  }) {
    return AppSettings(
      showLunarCalendar: showLunarCalendar ?? this.showLunarCalendar,
      showHolidays: showHolidays ?? this.showHolidays,
      masterEnabled: masterEnabled ?? this.masterEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      globalSilentMode: globalSilentMode ?? this.globalSilentMode,
      soundOption: soundOption ?? this.soundOption,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      customSoundPath:
          clearCustom ? null : (customSoundPath ?? this.customSoundPath),
      currentTheme: currentTheme ?? this.currentTheme,
      calendarNavMode: calendarNavMode ?? this.calendarNavMode,
      dynamicWidgetTheme: dynamicWidgetTheme ?? this.dynamicWidgetTheme,
      showSplash: showSplash ?? this.showSplash,
      preventCapture: preventCapture ?? this.preventCapture,
    );
  }
}

// ── CalendarEvent ────────────────────────────────────────────────

@freezed
abstract class CalendarEvent with _$CalendarEvent {
  const CalendarEvent._();

  const factory CalendarEvent({
    required int id,
    required String title,
    required String date,
    String? endDate,
    String? startTime,
    String? endTime,
    int? colorValue,
    @Default(false) bool isAllDay,
    @Default(true) bool isAlarmOn,
    @Default(AlarmMinutes.none) AlarmMinutes alarmMinutes,
    @Default(AlarmMode.soundAndVibration) AlarmMode eventAlarmMode,
    @Default(NotificationSound.system) NotificationSound soundOption,
    @Default(VibrationPattern.heartbeat) VibrationPattern vibrationPattern,
    String? customSoundPath,
    RecurrenceRule? recurrenceRule,
    int? parentId,
    @Default(false) bool isRecurrenceInstance,
  }) = _CalendarEvent;

  factory CalendarEvent.fromJson(Map<String, dynamic> j) {
    return CalendarEvent(
      id: j['id'] as int,
      title: j['title'] as String,
      date: j['date'] as String,
      endDate: j['endDate'] as String?,
      colorValue: j['colorValue'] as int?,
      isAllDay: j['isAllDay'] as bool? ?? false,
      startTime: j['startTime'] as String?,
      endTime: j['endTime'] as String?,
      alarmMinutes: _safeEnum(
        AlarmMinutes.values,
        j['alarmMinutes'] as int?,
        0,
      ),
      eventAlarmMode: _safeEnum(
        AlarmMode.values,
        j['eventAlarmMode'] as int?,
        AlarmMode.soundAndVibration.index,
      ),
      isAlarmOn: j['isAlarmOn'] as bool? ?? true,
      soundOption: _safeEnum(
        NotificationSound.values,
        j['soundOption'] as int?,
        0,
      ),
      vibrationPattern: _safeEnum(
        VibrationPattern.values,
        j['vibrationPattern'] as int?,
        1,
      ),
      customSoundPath: j['customSoundPath'] as String?,
      recurrenceRule:
          j['recurrenceRule'] != null
              ? RecurrenceRule.fromJson(
                j['recurrenceRule'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'endDate': endDate,
      'colorValue': colorValue,
      'isAllDay': isAllDay,
      'startTime': startTime,
      'endTime': endTime,
      'alarmMinutes': alarmMinutes.index,
      'eventAlarmMode': eventAlarmMode.index,
      'isAlarmOn': isAlarmOn,
      'soundOption': soundOption.index,
      'vibrationPattern': vibrationPattern.index,
      'customSoundPath': customSoundPath,
      'recurrenceRule': recurrenceRule?.toJson(),
    };
  }

  bool get isHoliday => id < 0;
  DateTime get startDt => _safeParse(date);
  DateTime get endDt => _safeParse(endDate ?? date);

  bool get isMultiDay =>
      startDt.year != endDt.year ||
      startDt.month != endDt.month ||
      startDt.day != endDt.day;

  bool get isToday {
    final now = DateTime.now();
    return startDt.year == now.year &&
        startDt.month == now.month &&
        startDt.day == now.day;
  }

  DateTime? get alarmDateTime {
    if (alarmMinutes == AlarmMinutes.none) return null;
    if (isAllDay) {
      return DateTime(
        startDt.year,
        startDt.month,
        startDt.day,
        9,
        0,
      ).subtract(Duration(minutes: alarmMinutes.minutes));
    }
    if (startTime == null) return null;
    final parts = startTime!.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(
      startDt.year,
      startDt.month,
      startDt.day,
      h,
      m,
    ).subtract(Duration(minutes: alarmMinutes.minutes));
  }
}
