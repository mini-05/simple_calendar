// ignore_for_file: curly_braces_in_flow_control_structures
// v3.6.2
import 'dart:typed_data';

enum AppTheme { apple, samsung, naver, darkNeon, classicBlue, todoSky }

enum CalendarNavMode {
  arrow(label: '화살표 버튼'),
  swipeVertical(label: '상하 스와이프'),
  swipeHorizontal(label: '좌우 스와이프');

  const CalendarNavMode({required this.label});
  final String label;
}

enum AlarmMode { silent, soundOnly, vibrationOnly, soundAndVibration }

const int defaultEventColor = 0xFF2196F3;

extension AlarmModeExt on AlarmMode {
  String get label {
    switch (this) {
      case AlarmMode.silent:
        return '무음';
      case AlarmMode.soundOnly:
        return '소리';
      case AlarmMode.vibrationOnly:
        return '진동';
      case AlarmMode.soundAndVibration:
        return '소리+진동';
    }
  }
}

enum NotificationSound {
  system(label: '기본 시스템 소리', fileName: ''),
  chime(label: '맑은 종소리', fileName: 'chime'),
  bell(label: '경쾌한 벨소리', fileName: 'bell'),
  bird(label: '새소리', fileName: 'bird'),
  custom(label: '🎵 내 휴대폰 음악', fileName: 'custom');

  const NotificationSound({required this.label, required this.fileName});
  final String label;
  final String fileName;
}

enum VibrationPattern {
  defaultPulse(label: '기본 진동', pattern: [0, 400, 200, 400]),
  heartbeat(label: '심장 박동', pattern: [0, 150, 150, 150, 800, 150, 150, 150]),
  crescendo(label: '크레센도', pattern: [0, 400, 300, 200, 150, 100, 100, 50, 50]),
  longPulse(label: '길게 한 번', pattern: [0, 800]);

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

T _safeEnum<T>(List<T> values, int? raw, int fallback) {
  return values[(raw ?? fallback).clamp(0, values.length - 1)];
}

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
    this.calendarNavMode = CalendarNavMode.arrow,
  });

  AlarmMode get effectiveMode {
    if (globalSilentMode) {
      return AlarmMode.silent;
    }
    if (soundEnabled && vibrationEnabled) {
      return AlarmMode.soundAndVibration;
    }
    if (soundEnabled) {
      return AlarmMode.soundOnly;
    }
    if (vibrationEnabled) {
      return AlarmMode.vibrationOnly;
    }
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
      soundOption:
          _safeEnum(NotificationSound.values, j['soundOption'] as int?, 0),
      vibrationPattern:
          _safeEnum(VibrationPattern.values, j['vibrationPattern'] as int?, 1),
      customSoundPath: j['customSoundPath'],
      currentTheme: _safeEnum(
          AppTheme.values, j['currentTheme'] as int?, AppTheme.samsung.index),
      calendarNavMode:
          _safeEnum(CalendarNavMode.values, j['calendarNavMode'] as int?, 0),
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
    );
  }
}

class CalendarEvent {
  final int id;
  final String title;
  final String date;
  final String? endDate;
  final String? startTime;
  final String? endTime;
  final int? colorValue;
  final bool isAllDay;
  final bool isAlarmOn;
  final AlarmMinutes alarmMinutes;
  final AlarmMode eventAlarmMode;
  final NotificationSound soundOption;
  final VibrationPattern vibrationPattern;
  final String? customSoundPath;
  final DateTime startDt;
  final DateTime endDt;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    this.endDate,
    this.colorValue,
    this.isAllDay = false,
    this.startTime,
    this.endTime,
    this.alarmMinutes = AlarmMinutes.none,
    this.eventAlarmMode = AlarmMode.soundAndVibration,
    this.isAlarmOn = true,
    this.soundOption = NotificationSound.system,
    this.vibrationPattern = VibrationPattern.heartbeat,
    this.customSoundPath,
  })  : startDt = DateTime.parse(date),
        endDt =
            endDate != null ? DateTime.parse(endDate) : DateTime.parse(date);

  bool get isHoliday {
    return id < 0;
  }

  DateTime? get alarmDateTime {
    if (alarmMinutes == AlarmMinutes.none) {
      return null;
    }
    if (isAllDay) {
      return DateTime(startDt.year, startDt.month, startDt.day, 9, 0)
          .subtract(Duration(minutes: alarmMinutes.minutes));
    }
    if (startTime == null) {
      return null;
    }
    final parts = startTime!.split(':');
    return DateTime(
      startDt.year,
      startDt.month,
      startDt.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    ).subtract(Duration(minutes: alarmMinutes.minutes));
  }

  bool get isMultiDay {
    return startDt.year != endDt.year ||
        startDt.month != endDt.month ||
        startDt.day != endDt.day;
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
    };
  }

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
      alarmMinutes:
          _safeEnum(AlarmMinutes.values, j['alarmMinutes'] as int?, 0),
      eventAlarmMode: _safeEnum(AlarmMode.values, j['eventAlarmMode'] as int?,
          AlarmMode.soundAndVibration.index),
      isAlarmOn: j['isAlarmOn'] as bool? ?? true,
      soundOption:
          _safeEnum(NotificationSound.values, j['soundOption'] as int?, 0),
      vibrationPattern:
          _safeEnum(VibrationPattern.values, j['vibrationPattern'] as int?, 1),
      customSoundPath: j['customSoundPath'] as String?,
    );
  }

  CalendarEvent copyWith({
    int? id,
    String? title,
    String? date,
    String? endDate,
    int? colorValue,
    bool? isAllDay,
    String? startTime,
    String? endTime,
    AlarmMinutes? alarmMinutes,
    AlarmMode? eventAlarmMode,
    bool? isAlarmOn,
    NotificationSound? soundOption,
    VibrationPattern? vibrationPattern,
    String? customSoundPath,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      colorValue: colorValue ?? this.colorValue,
      isAllDay: isAllDay ?? this.isAllDay,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      alarmMinutes: alarmMinutes ?? this.alarmMinutes,
      eventAlarmMode: eventAlarmMode ?? this.eventAlarmMode,
      isAlarmOn: isAlarmOn ?? this.isAlarmOn,
      soundOption: soundOption ?? this.soundOption,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      customSoundPath: customSoundPath ?? this.customSoundPath,
    );
  }
}
