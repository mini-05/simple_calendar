// ignore_for_file: curly_braces_in_flow_control_structures
// =============================================================
// My Calendar App — main.dart (Military Grade Secure Edition v2.6.1)
// Updated : 2026-02-24
//
// [v2.6.1 주요 업데이트 사항]
// 1. FIX: Windows 환경 테스트 시 발생하는 Notification 에러 방어 로직 추가 (Platform 확인)
// 2. STABILITY: 데스크톱/웹 환경에서 앱이 크래시 나지 않고 UI 테스트가 가능하도록 Bypass 적용
// =============================================================

import 'dart:io'
    show Platform; // 💡 [v2.6.1] 실행 환경(Windows, Android 등) 확인을 위해 추가
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:lunar/lunar.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ⚙️ 앱 전체 설정 & 모델
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
enum AlarmMode { silent, soundOnly, vibrationOnly, soundAndVibration }

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
  custom(label: '🎵 내 휴대폰 음악 사용', fileName: 'custom');

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

class AppSettings {
  final bool showLunarCalendar;
  final bool masterEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool globalSilentMode;
  final NotificationSound soundOption;
  final VibrationPattern vibrationPattern;
  final String? customSoundPath;
  final String? lastCustomChannelId;
  final AppTheme currentTheme;

  const AppSettings({
    this.showLunarCalendar = false,
    this.masterEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.globalSilentMode = false,
    this.soundOption = NotificationSound.system,
    this.vibrationPattern = VibrationPattern.heartbeat,
    this.customSoundPath,
    this.lastCustomChannelId,
    this.currentTheme = AppTheme.samsung,
  });

  AlarmMode get effectiveMode {
    if (globalSilentMode) return AlarmMode.silent;
    if (soundEnabled && vibrationEnabled) return AlarmMode.soundAndVibration;
    if (soundEnabled) return AlarmMode.soundOnly;
    if (vibrationEnabled) return AlarmMode.vibrationOnly;
    return AlarmMode.silent;
  }

  Map<String, dynamic> toJson() => {
        'showLunarCalendar': showLunarCalendar,
        'masterEnabled': masterEnabled,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'globalSilentMode': globalSilentMode,
        'soundOption': soundOption.index,
        'vibrationPattern': vibrationPattern.index,
        'customSoundPath': customSoundPath,
        'lastCustomChannelId': lastCustomChannelId,
        'currentTheme': currentTheme.index,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        showLunarCalendar: j['showLunarCalendar'] ?? false,
        masterEnabled: j['masterEnabled'] ?? true,
        soundEnabled: j['soundEnabled'] ?? true,
        vibrationEnabled: j['vibrationEnabled'] ?? true,
        globalSilentMode: j['globalSilentMode'] ?? false,
        soundOption: NotificationSound.values[j['soundOption'] ?? 0],
        vibrationPattern: VibrationPattern.values[j['vibrationPattern'] ?? 1],
        customSoundPath: j['customSoundPath'],
        lastCustomChannelId: j['lastCustomChannelId'],
        currentTheme:
            AppTheme.values[j['currentTheme'] ?? AppTheme.samsung.index],
      );

  AppSettings copyWith({
    bool? showLunarCalendar,
    bool? masterEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? globalSilentMode,
    NotificationSound? soundOption,
    VibrationPattern? vibrationPattern,
    String? customSoundPath,
    String? lastCustomChannelId,
    bool clearCustom = false,
    AppTheme? currentTheme,
  }) =>
      AppSettings(
        showLunarCalendar: showLunarCalendar ?? this.showLunarCalendar,
        masterEnabled: masterEnabled ?? this.masterEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
        globalSilentMode: globalSilentMode ?? this.globalSilentMode,
        soundOption: soundOption ?? this.soundOption,
        vibrationPattern: vibrationPattern ?? this.vibrationPattern,
        customSoundPath:
            clearCustom ? null : (customSoundPath ?? this.customSoundPath),
        lastCustomChannelId: clearCustom
            ? null
            : (lastCustomChannelId ?? this.lastCustomChannelId),
        currentTheme: currentTheme ?? this.currentTheme,
      );
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

class CalendarEvent {
  final int id;
  final String title;
  final String date;
  final String? endDate;
  final int? colorValue;
  final bool isAllDay;
  final String? startTime;
  final String? endTime;
  final AlarmMinutes alarmMinutes;
  final AlarmMode eventAlarmMode;
  final bool isAlarmOn;
  final DateTime startDt;
  final DateTime endDt;

  CalendarEvent(
      {required this.id,
      required this.title,
      required this.date,
      this.endDate,
      this.colorValue,
      this.isAllDay = false,
      this.startTime,
      this.endTime,
      this.alarmMinutes = AlarmMinutes.none,
      this.eventAlarmMode = AlarmMode.soundAndVibration,
      this.isAlarmOn = true})
      : startDt = DateTime.parse(date),
        endDt =
            endDate != null ? DateTime.parse(endDate) : DateTime.parse(date);

  DateTime? get alarmDateTime {
    if (alarmMinutes == AlarmMinutes.none) return null;
    if (isAllDay)
      return DateTime(startDt.year, startDt.month, startDt.day, 9, 0)
          .subtract(Duration(minutes: alarmMinutes.minutes));
    if (startTime == null) return null;
    final parts = startTime!.split(':');
    return DateTime(startDt.year, startDt.month, startDt.day,
            int.parse(parts[0]), int.parse(parts[1]))
        .subtract(Duration(minutes: alarmMinutes.minutes));
  }

  Map<String, dynamic> toJson() => {
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
        'isAlarmOn': isAlarmOn
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
      id: json['id'] as int,
      title: json['title'] as String,
      date: json['date'] as String,
      endDate: json['endDate'] as String?,
      colorValue: json['colorValue'] as int?,
      isAllDay: json['isAllDay'] as bool? ?? false,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      alarmMinutes: AlarmMinutes.values[(json['alarmMinutes'] as int?) ?? 0],
      eventAlarmMode: AlarmMode.values[(json['eventAlarmMode'] as int?) ??
          AlarmMode.soundAndVibration.index],
      isAlarmOn: json['isAlarmOn'] as bool? ?? true);

  CalendarEvent copyWith(
      {int? id,
      String? title,
      String? date,
      String? endDate,
      int? colorValue,
      bool? isAllDay,
      String? startTime,
      String? endTime,
      AlarmMinutes? alarmMinutes,
      AlarmMode? eventAlarmMode,
      bool? isAlarmOn}) {
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
        isAlarmOn: isAlarmOn ?? this.isAlarmOn);
  }
}

void _log(String msg) {
  if (!kReleaseMode) debugPrint(msg);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🔔 알림 서비스 (플랫폼 방어 로직 적용)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // 💡 [v2.6.1] 모바일(Android/iOS)인지 확인하는 헬퍼 속성
  static bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> init() async {
    if (!_isMobile) {
      _log('[NotifSvc] 데스크톱 환경에서는 알림 초기화를 건너뜁니다.');
      return;
    }

    tz_data.initializeTimeZones();
    try {
      final String tzName =
          (await FlutterTimezone.getLocalTimezone()).toString();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    }
    await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings()));
    await _registerStaticChannels();
  }

  static Future<void> _registerStaticChannels() async {
    if (!_isMobile) return;
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (impl == null) return;
    await impl.createNotificationChannel(const AndroidNotificationChannel(
        'cal_silent', '무음 알림',
        importance: Importance.low, playSound: false, enableVibration: false));
    await impl.createNotificationChannel(const AndroidNotificationChannel(
        'cal_vibration', '진동 알림',
        importance: Importance.high, playSound: false, enableVibration: true));

    for (final s in NotificationSound.values) {
      if (s == NotificationSound.custom) continue;
      final sound = s == NotificationSound.system
          ? null
          : RawResourceAndroidNotificationSound(s.fileName);
      await impl.createNotificationChannel(AndroidNotificationChannel(
          'cal_snd_${s.name}', '소리 (${s.label})',
          importance: Importance.high, playSound: true, sound: sound));
      await impl.createNotificationChannel(AndroidNotificationChannel(
          'cal_sv_${s.name}', '소리+진동 (${s.label})',
          importance: Importance.high,
          playSound: true,
          sound: sound,
          enableVibration: true));
    }
  }

  static Future<String?> setupCustomChannel(
      AppSettings settings, AlarmMode mode) async {
    if (!_isMobile) return null;
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (impl == null || settings.customSoundPath == null) return null;
    final newChannelId =
        'cal_custom_${settings.customSoundPath.hashCode}_${mode.index}';
    final androidSound =
        UriAndroidNotificationSound('file://${settings.customSoundPath}');
    final hasVib = mode == AlarmMode.soundAndVibration;

    await impl.createNotificationChannel(AndroidNotificationChannel(
      newChannelId,
      '내 휴대폰 음악 알림',
      importance: Importance.high,
      playSound: true,
      sound: androidSound,
      enableVibration: hasVib,
      vibrationPattern: hasVib ? settings.vibrationPattern.patternInt64 : null,
    ));
    return newChannelId;
  }

  static Future<void> scheduleEventAlarm(
      {required CalendarEvent event, required AppSettings settings}) async {
    if (!_isMobile) {
      _log('[NotifSvc] 데스크톱 환경 - 예약 알림 무시 (title: ${event.title})');
      return;
    }
    if (!settings.masterEnabled ||
        !event.isAlarmOn ||
        event.alarmDateTime == null ||
        event.alarmDateTime!.isBefore(DateTime.now())) return;

    try {
      final mode =
          settings.globalSilentMode ? AlarmMode.silent : event.eventAlarmMode;
      String channelId = 'cal_silent';
      AndroidNotificationSound? snd;

      if (mode == AlarmMode.silent) {
        channelId = 'cal_silent';
      } else if (mode == AlarmMode.vibrationOnly) {
        channelId = 'cal_vibration';
      } else {
        if (settings.soundOption == NotificationSound.custom &&
            settings.customSoundPath != null) {
          channelId =
              (await setupCustomChannel(settings, mode)) ?? 'cal_silent';
          snd =
              UriAndroidNotificationSound('file://${settings.customSoundPath}');
        } else {
          channelId = mode == AlarmMode.soundAndVibration
              ? 'cal_sv_${settings.soundOption.name}'
              : 'cal_snd_${settings.soundOption.name}';
          if (settings.soundOption != NotificationSound.system) {
            snd = RawResourceAndroidNotificationSound(
                settings.soundOption.fileName);
          }
        }
      }

      Int64List? vib;
      if (mode == AlarmMode.vibrationOnly ||
          mode == AlarmMode.soundAndVibration)
        vib = settings.vibrationPattern.patternInt64;

      final androidDetails = AndroidNotificationDetails(channelId, '캘린더 알림',
          importance:
              mode == AlarmMode.silent ? Importance.low : Importance.high,
          priority: Priority.high,
          sound: snd,
          playSound:
              snd != null || settings.soundOption == NotificationSound.system,
          enableVibration: vib != null,
          vibrationPattern: vib,
          silent: mode == AlarmMode.silent);

      await _plugin.zonedSchedule(
          event.id,
          '📅 일정 알림',
          event.title,
          tz.TZDateTime.from(event.alarmDateTime!, tz.local),
          NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime);
    } catch (e) {
      _log('[NotifSvc] 알림 스케줄 실패: $e');
    }
  }

  static Future<void> cancelAlarm(int id) async {
    if (!_isMobile) return;
    await _plugin.cancel(id);
  }

  static Future<void> showTestNotification(
      AppSettings settings, AlarmMode testMode) async {
    if (!_isMobile) {
      _log('[NotifSvc] 데스크톱 환경 - 테스트 알림 무시');
      return;
    }
    try {
      String channelId = 'cal_silent';
      AndroidNotificationSound? snd;
      if (testMode == AlarmMode.silent) {
        channelId = 'cal_silent';
      } else if (testMode == AlarmMode.vibrationOnly) {
        channelId = 'cal_vibration';
      } else {
        if (settings.soundOption == NotificationSound.custom &&
            settings.customSoundPath != null) {
          channelId =
              (await setupCustomChannel(settings, testMode)) ?? 'cal_silent';
          snd =
              UriAndroidNotificationSound('file://${settings.customSoundPath}');
        } else {
          channelId = testMode == AlarmMode.soundAndVibration
              ? 'cal_sv_${settings.soundOption.name}'
              : 'cal_snd_${settings.soundOption.name}';
          if (settings.soundOption != NotificationSound.system)
            snd = RawResourceAndroidNotificationSound(
                settings.soundOption.fileName);
        }
      }
      Int64List? vib;
      if (testMode == AlarmMode.vibrationOnly ||
          testMode == AlarmMode.soundAndVibration)
        vib = settings.vibrationPattern.patternInt64;
      final androidDetails = AndroidNotificationDetails(channelId, '테스트 알림',
          importance:
              testMode == AlarmMode.silent ? Importance.low : Importance.high,
          priority: Priority.high,
          sound: snd,
          playSound:
              snd != null || settings.soundOption == NotificationSound.system,
          enableVibration: vib != null,
          vibrationPattern: vib,
          silent: testMode == AlarmMode.silent);
      await _plugin.show(9999, '🔔 테스트 알림', '이 일정의 알림은 이렇게 울립니다.',
          NotificationDetails(android: androidDetails));
    } catch (e) {
      _log('Test Notification Error: $e');
    }
  }

  static Future<void> requestPermissions() async {
    if (!_isMobile) return;
    final audioStatus = await Permission.audio.request();
    if (!audioStatus.isGranted) await Permission.storage.request();
    await Permission.notification.request();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestExactAlarmsPermission();
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🛡️ 보안 스토리지
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true));

class AppSettingsStorage {
  static String get _key => String.fromCharCodes([
        97,
        112,
        112,
        95,
        115,
        101,
        116,
        116,
        105,
        110,
        103,
        115,
        95,
        101,
        110,
        99,
        114,
        121,
        112,
        116,
        101,
        100,
        95,
        118,
        49
      ]);
  static Future<AppSettings> load() async {
    final raw = await _secureStorage.read(key: _key);
    if (raw != null) {
      try {
        return AppSettings.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    return const AppSettings();
  }

  static Future<void> save(AppSettings s) async {
    await _secureStorage.write(key: _key, value: jsonEncode(s.toJson()));
  }
}

class EventStorage {
  static String get _eventsKey => String.fromCharCodes([
        99,
        97,
        108,
        101,
        110,
        100,
        97,
        114,
        95,
        101,
        118,
        101,
        110,
        116,
        115,
        95,
        101,
        110,
        99,
        114,
        121,
        112,
        116,
        101,
        100,
        95,
        118,
        49
      ]);
  static Future<List<CalendarEvent>> loadAll() async {
    final raw = await _secureStorage.read(key: _eventsKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<CalendarEvent> events) async {
    await _secureStorage.write(
        key: _eventsKey,
        value: jsonEncode(events.map((e) => e.toJson()).toList()));
  }

  static int generateId() => DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🎨 테마 모델
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
enum AppTheme { apple, samsung, naver, darkNeon, classicBlue, todoSky }

class CalendarThemeData {
  final String name;
  final String emoji;
  final Color scaffoldBg;
  final Color appBarBg;
  final Color appBarText;
  final Color calendarBg;
  final int primaryAccentInt;
  final Color secondaryAccent;
  final Color cardBg;
  final Color cardBorder;
  final Color eventTitleText;
  final Color eventSubText;
  final Color iconBg;
  final Color iconColor;
  final Color sectionLabelText;
  final Color? bottomPanelBg;
  final bool isDark;
  const CalendarThemeData(
      {required this.name,
      required this.emoji,
      required this.scaffoldBg,
      required this.appBarBg,
      required this.appBarText,
      required this.calendarBg,
      required this.primaryAccentInt,
      required this.secondaryAccent,
      required this.cardBg,
      required this.cardBorder,
      required this.eventTitleText,
      required this.eventSubText,
      required this.iconBg,
      required this.iconColor,
      required this.sectionLabelText,
      this.bottomPanelBg,
      this.isDark = false});
  Color get primaryAccent => Color(primaryAccentInt);
}

const themeSamsung = CalendarThemeData(
    name: '삼성 캘린더',
    emoji: '📱',
    scaffoldBg: Color(0xFFF2F2F2),
    appBarBg: Color(0xFFF2F2F2),
    appBarText: Color(0xFF222222),
    calendarBg: Colors.white,
    primaryAccentInt: 0xFF2196F3,
    secondaryAccent: Color(0xFFBBDEF0),
    cardBg: Colors.white,
    cardBorder: Colors.transparent,
    eventTitleText: Color(0xFF222222),
    eventSubText: Color(0xFF666666),
    iconBg: Color(0xFFE3F2FD),
    iconColor: Color(0xFF2196F3),
    sectionLabelText: Color(0xFF444444));
const themeApple = CalendarThemeData(
    name: '애플 캘린더',
    emoji: '🍎',
    scaffoldBg: Color(0xFFF8F9FF),
    appBarBg: Colors.white,
    appBarText: Color(0xFF1A1A2E),
    calendarBg: Colors.white,
    primaryAccentInt: 0xFFFA233B,
    secondaryAccent: Color(0xFFFFD1D6),
    cardBg: Colors.white,
    cardBorder: Colors.transparent,
    eventTitleText: Color(0xFF1A1A2E),
    eventSubText: Color(0xFF888888),
    iconBg: Color(0xFFFFF0F1),
    iconColor: Color(0xFFFA233B),
    sectionLabelText: Color(0xFF1A1A2E));
const themeNaver = CalendarThemeData(
    name: '네이버 캘린더',
    emoji: '🇳',
    scaffoldBg: Colors.white,
    appBarBg: Colors.white,
    appBarText: Colors.black,
    calendarBg: Colors.white,
    primaryAccentInt: 0xFF03C75A,
    secondaryAccent: Color(0xFFD4F5E1),
    cardBg: Color(0xFFF9F9F9),
    cardBorder: Colors.transparent,
    eventTitleText: Colors.black87,
    eventSubText: Colors.black54,
    iconBg: Color(0xFFE6F9ED),
    iconColor: Color(0xFF03C75A),
    sectionLabelText: Colors.black);
const themeDarkNeon = CalendarThemeData(
    name: '다크 네온',
    emoji: '🌙',
    scaffoldBg: Color(0xFF1E1B2E),
    appBarBg: Color(0xFF1E1B2E),
    appBarText: Colors.white,
    calendarBg: Color(0xFF2A2640),
    primaryAccentInt: 0xFF9C6FE4,
    secondaryAccent: Color(0xFF00D4FF),
    cardBg: Color(0xFF2A2640),
    cardBorder: Color(0xFF3D3760),
    eventTitleText: Colors.white,
    eventSubText: Color(0xFF9E9BB8),
    iconBg: Color(0xFF3D3760),
    iconColor: Color(0xFF9C6FE4),
    sectionLabelText: Colors.white,
    isDark: true);
const themeClassicBlue = CalendarThemeData(
    name: '클래식 블루',
    emoji: '☁️',
    scaffoldBg: Color(0xFFF8F9FF),
    appBarBg: Colors.white,
    appBarText: Color(0xFF1A1A2E),
    calendarBg: Colors.white,
    primaryAccentInt: 0xFF4A90D9,
    secondaryAccent: Color(0xFFDDEEFF),
    cardBg: Colors.white,
    cardBorder: Color(0xFFEEEEEE),
    eventTitleText: Color(0xFF1A1A2E),
    eventSubText: Color(0xFF888888),
    iconBg: Color(0xFFEEF4FF),
    iconColor: Color(0xFF4A90D9),
    sectionLabelText: Color(0xFF1A1A2E));
const themeTodoSky = CalendarThemeData(
    name: '투두 스카이',
    emoji: '✅',
    scaffoldBg: Colors.white,
    appBarBg: Colors.white,
    appBarText: Color(0xFF2D3142),
    calendarBg: Colors.white,
    primaryAccentInt: 0xFFEF6C6C,
    secondaryAccent: Color(0xFFF5E6E6),
    cardBg: Color(0xFF3A3F5C),
    cardBorder: Color(0xFF4A5073),
    eventTitleText: Colors.white,
    eventSubText: Color(0xFFADB5D0),
    iconBg: Color(0xFF4A5073),
    iconColor: Color(0xFFEF6C6C),
    sectionLabelText: Colors.white,
    bottomPanelBg: Color(0xFF2D3142));
const Map<AppTheme, CalendarThemeData> themeMap = {
  AppTheme.samsung: themeSamsung,
  AppTheme.apple: themeApple,
  AppTheme.naver: themeNaver,
  AppTheme.darkNeon: themeDarkNeon,
  AppTheme.classicBlue: themeClassicBlue,
  AppTheme.todoSky: themeTodoSky
};
const int defaultEventColor = 0xFF2196F3;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MyCalendarApp());
}

class MyCalendarApp extends StatelessWidget {
  const MyCalendarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'My Calendar',
        theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate
        ],
        supportedLocales: const [Locale('ko', 'KR')],
        locale: const Locale('ko', 'KR'),
        home: const CalendarScreen(),
        debugShowCheckedModeBanner: false);
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📱 메인 화면 UI
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  AppSettings _appSettings = const AppSettings();
  AppTheme get _currentTheme => _appSettings.currentTheme;
  CalendarThemeData get th => themeMap[_currentTheme]!;
  bool get _showTextInside =>
      _currentTheme == AppTheme.samsung || _currentTheme == AppTheme.naver;
  bool get _isTodoSky => _currentTheme == AppTheme.todoSky;

  List<CalendarEvent> _allEvents = [];
  Map<String, List<CalendarEvent>> _eventsByDate = {};
  List<CalendarEvent> _selectedEvents = [];
  final Map<String, String> _lunarCache = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initialLoad();
    _loadAppSettings();
    NotificationService.requestPermissions();
  }

  Future<void> _loadAppSettings() async {
    final s = await AppSettingsStorage.load();
    if (mounted)
      setState(() {
        _appSettings = s;
      });
  }

  Future<void> _initialLoad() async {
    final all = await EventStorage.loadAll();
    _rebuildIndex(all, firstLoad: true);
  }

  void _rebuildIndex(List<CalendarEvent> all, {bool firstLoad = false}) {
    all.sort((a, b) {
      final dc = a.date.compareTo(b.date);
      if (dc != 0) return dc;
      if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
      if (!a.isAllDay) {
        final tc = (a.startTime ?? '00:00').compareTo(b.startTime ?? '00:00');
        if (tc != 0) return tc;
      }
      return a.title.compareTo(b.title);
    });
    final map = <String, List<CalendarEvent>>{};
    for (final e in all) {
      DateTime cur = DateTime(e.startDt.year, e.startDt.month, e.startDt.day);
      final end = DateTime(e.endDt.year, e.endDt.month, e.endDt.day);
      while (!cur.isAfter(end)) {
        (map[_dateKey(cur)] ??= []).add(e);
        cur = cur.add(const Duration(days: 1));
      }
    }
    final selKey = _dateKey(_selectedDay ?? _focusedDay);
    if (mounted)
      setState(() {
        _allEvents = all;
        _eventsByDate = map;
        _selectedEvents = map[selKey] ?? [];
        if (firstLoad) _isLoading = false;
      });
  }

  Future<void> _rescheduleAllAlarms() async {
    for (final e in _allEvents) {
      if (e.alarmDateTime != null && e.alarmDateTime!.isAfter(DateTime.now())) {
        if (e.isAlarmOn) {
          await NotificationService.scheduleEventAlarm(
              event: e, settings: _appSettings);
        } else {
          await NotificationService.cancelAlarm(e.id);
        }
      }
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  List<CalendarEvent> _getEventsForDay(DateTime day) =>
      _eventsByDate[_dateKey(day)] ?? [];
  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
      _selectedEvents = _eventsByDate[_dateKey(selected)] ?? [];
    });
  }

  String _formatHHmm(String hhmm) {
    final p = hhmm.split(':');
    if (p.length != 2) return '';
    final h = int.parse(p[0]);
    final m = int.parse(p[1]);
    final period = h < 12 ? '오전' : '오후';
    final disp = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $disp:${m.toString().padLeft(2, '0')}';
  }

  String _formatDateKorean(DateTime d) {
    const wd = ['월', '화', '수', '목', '금', '토', '일'];
    return '${d.year}년 ${d.month}월 ${d.day}일 (${wd[d.weekday - 1]})';
  }

  String _makeTimeString(CalendarEvent e) {
    final same = e.startDt.year == e.endDt.year &&
        e.startDt.month == e.endDt.month &&
        e.startDt.day == e.endDt.day;
    if (e.isAllDay) {
      if (same) return '하루 종일';
      return '${e.startDt.month}.${e.startDt.day} ~ ${e.endDt.month}.${e.endDt.day}';
    }
    final sT = _formatHHmm(e.startTime ?? '00:00');
    final eT = _formatHHmm(e.endTime ?? '00:00');
    if (same) return '$sT ~ $eT';
    return '${e.startDt.month}.${e.startDt.day} $sT ~ ${e.endDt.month}.${e.endDt.day} $eT';
  }

  void _showThemePicker() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: th.isDark ? const Color(0xFF2A2640) : Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.6,
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2)))),
                      Text('테마 선택',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: th.isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E))),
                      const SizedBox(height: 16),
                      Expanded(
                          child: ListView(
                              children: AppTheme.values.map((t) {
                        final data = themeMap[t]!;
                        final isSel = _currentTheme == t;
                        return GestureDetector(
                            onTap: () async {
                              final updated =
                                  _appSettings.copyWith(currentTheme: t);
                              setState(() {
                                _appSettings = updated;
                              });
                              await AppSettingsStorage.save(updated);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                    color: isSel
                                        ? data.primaryAccent
                                            .withValues(alpha: 0.15)
                                        : (th.isDark
                                            ? const Color(0xFF3D3760)
                                            : const Color(0xFFF5F5F5)),
                                    borderRadius: BorderRadius.circular(14),
                                    border: isSel
                                        ? Border.all(
                                            color: data.primaryAccent, width: 2)
                                        : null),
                                child: Row(children: [
                                  _colorDot(data.scaffoldBg),
                                  _colorDot(data.primaryAccent),
                                  const SizedBox(width: 12),
                                  Text('${data.emoji}  ${data.name}',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: th.isDark
                                              ? Colors.white
                                              : const Color(0xFF1A1A2E))),
                                  const Spacer(),
                                  if (isSel)
                                    Icon(Icons.check_circle,
                                        color: data.primaryAccent, size: 22)
                                ])));
                      }).toList()))
                    ]))));
  }

  Widget _colorDot(Color color) => Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.3), width: 1)));
  void _showAppSettingsSheet() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: th.isDark ? const Color(0xFF2A2640) : Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => _AppSettingsSheet(
            initial: _appSettings,
            isDark: th.isDark,
            accent: th.primaryAccent,
            onChanged: (updated) async {
              setState(() => _appSettings = updated);
              await AppSettingsStorage.save(updated);
              await _rescheduleAllAlarms();
            }));
  }

  Widget _buildColorPicker(ValueNotifier<int> colorNotifier) {
    const opts = [
      defaultEventColor,
      0xFFE57373,
      0xFF81C784,
      0xFFFFB74D,
      0xFFBA68C8
    ];
    return ValueListenableBuilder<int>(
        valueListenable: colorNotifier,
        builder: (_, sel, __) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: opts.map((v) {
              final isSel = sel == v;
              return GestureDetector(
                  onTap: () => colorNotifier.value = v,
                  child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: Color(v),
                          shape: BoxShape.circle,
                          border: isSel
                              ? Border.all(
                                  color:
                                      th.isDark ? Colors.white : Colors.black54,
                                  width: 3)
                              : null),
                      child: isSel
                          ? const Icon(Icons.check,
                              size: 22, color: Colors.white)
                          : null));
            }).toList()));
  }

  void _applyDateTimeCorrection(
      ValueNotifier<DateTime> sD,
      ValueNotifier<DateTime> sT,
      ValueNotifier<DateTime> eD,
      ValueNotifier<DateTime> eT,
      bool isAllDay) {
    final startDt = DateTime(sD.value.year, sD.value.month, sD.value.day,
        sT.value.hour, sT.value.minute);
    final endDt = DateTime(eD.value.year, eD.value.month, eD.value.day,
        eT.value.hour, eT.value.minute);
    if (endDt.isBefore(startDt)) {
      if (isAllDay) {
        eD.value = sD.value;
      } else {
        final newEnd = startDt.add(const Duration(hours: 1));
        eD.value = newEnd;
        eT.value = DateTime(2000, 1, 1, newEnd.hour, newEnd.minute);
      }
    }
  }

  void _showEventDialog({CalendarEvent? existingEvent}) {
    final isEdit = existingEvent != null;
    final ctrl = TextEditingController(text: isEdit ? existingEvent.title : '');
    final startDateN = ValueNotifier<DateTime>(
        isEdit ? existingEvent.startDt : (_selectedDay ?? DateTime.now()));
    final endDateN = ValueNotifier<DateTime>(
        isEdit ? existingEvent.endDt : startDateN.value);
    final isAllDayN =
        ValueNotifier<bool>(isEdit ? existingEvent.isAllDay : false);
    DateTime t0 = DateTime.now();
    DateTime t1 = t0.add(const Duration(hours: 1));
    if (isEdit &&
        existingEvent.startTime != null &&
        existingEvent.endTime != null) {
      final sp = existingEvent.startTime!.split(':');
      final ep = existingEvent.endTime!.split(':');
      t0 = DateTime(2000, 1, 1, int.parse(sp[0]), int.parse(sp[1]));
      t1 = DateTime(2000, 1, 1, int.parse(ep[0]), int.parse(ep[1]));
    }
    final startTimeN = ValueNotifier<DateTime>(t0);
    final endTimeN = ValueNotifier<DateTime>(t1);
    final colorN =
        ValueNotifier<int>(existingEvent?.colorValue ?? defaultEventColor);
    final alarmN = ValueNotifier<AlarmMinutes>(
        isEdit ? existingEvent.alarmMinutes : AlarmMinutes.none);
    final alarmModeN = ValueNotifier<AlarmMode>(
        isEdit ? existingEvent.eventAlarmMode : AlarmMode.soundAndVibration);

    showDialog(
        context: context,
        builder: (dlgCtx) => AlertDialog(
                backgroundColor:
                    th.isDark ? const Color(0xFF2A2640) : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text(isEdit ? '✏️ 일정 수정' : '✨ 새 일정 추가',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: th.isDark ? Colors.white : Colors.black)),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: ctrl,
                      autofocus: true,
                      maxLength: 100,
                      style: TextStyle(
                          color: th.isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                          hintText: '일정을 입력하세요',
                          hintStyle: TextStyle(
                              color: th.isDark ? Colors.white38 : Colors.grey),
                          filled: true,
                          fillColor: th.isDark
                              ? const Color(0xFF3D3760)
                              : Colors.grey[100],
                          counterStyle: TextStyle(
                              color: th.isDark ? Colors.white38 : Colors.grey,
                              fontSize: 11),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none))),
                  const SizedBox(height: 16),
                  Container(
                      decoration: BoxDecoration(
                          color: th.isDark
                              ? const Color(0xFF3D3760)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12)),
                      child: ValueListenableBuilder<bool>(
                          valueListenable: isAllDayN,
                          builder: (_, isAllDay, __) => Column(children: [
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 16),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('하루 종일',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: th.isDark
                                                      ? Colors.white
                                                      : Colors.black87)),
                                          CupertinoSwitch(
                                              activeTrackColor:
                                                  th.primaryAccent,
                                              value: isAllDay,
                                              onChanged: (v) =>
                                                  isAllDayN.value = v)
                                        ])),
                                Divider(
                                    height: 1,
                                    color: th.isDark
                                        ? Colors.white12
                                        : Colors.grey[300]),
                                _buildPickerRow(
                                    label: '시작 날짜',
                                    notifier: startDateN,
                                    parentCtx: dlgCtx,
                                    isDate: true,
                                    onChanged: () => _applyDateTimeCorrection(
                                        startDateN,
                                        startTimeN,
                                        endDateN,
                                        endTimeN,
                                        isAllDayN.value)),
                                if (!isAllDay)
                                  _buildPickerRow(
                                      label: '시작 시간',
                                      notifier: startTimeN,
                                      parentCtx: dlgCtx,
                                      isDate: false,
                                      onChanged: () => _applyDateTimeCorrection(
                                          startDateN,
                                          startTimeN,
                                          endDateN,
                                          endTimeN,
                                          isAllDayN.value)),
                                Divider(
                                    height: 1,
                                    color: th.isDark
                                        ? Colors.white12
                                        : Colors.grey[300]),
                                _buildPickerRow(
                                    label: '종료 날짜',
                                    notifier: endDateN,
                                    parentCtx: dlgCtx,
                                    isDate: true,
                                    onChanged: () => _applyDateTimeCorrection(
                                        startDateN,
                                        startTimeN,
                                        endDateN,
                                        endTimeN,
                                        isAllDayN.value)),
                                if (!isAllDay)
                                  _buildPickerRow(
                                      label: '종료 시간',
                                      notifier: endTimeN,
                                      parentCtx: dlgCtx,
                                      isDate: false,
                                      onChanged: () => _applyDateTimeCorrection(
                                          startDateN,
                                          startTimeN,
                                          endDateN,
                                          endTimeN,
                                          isAllDayN.value))
                              ]))),
                  const SizedBox(height: 12),
                  Container(
                      decoration: BoxDecoration(
                          color: th.isDark
                              ? const Color(0xFF3D3760)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                child: Row(children: [
                                  Icon(Icons.notifications_outlined,
                                      color: th.primaryAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Text('알림 시간',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: th.isDark
                                              ? Colors.white
                                              : Colors.black87))
                                ])),
                            Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: ValueListenableBuilder<AlarmMinutes>(
                                    valueListenable: alarmN,
                                    builder: (_, alarm, __) => Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children:
                                            AlarmMinutes.values.map((opt) {
                                          final isSel = alarm == opt;
                                          return GestureDetector(
                                              onTap: () => alarmN.value = opt,
                                              child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6),
                                                  decoration: BoxDecoration(
                                                      color: isSel
                                                          ? th.primaryAccent
                                                          : (th.isDark
                                                              ? const Color(
                                                                  0xFF2A2640)
                                                              : Colors.white),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                          color: isSel
                                                              ? th.primaryAccent
                                                              : (th.isDark
                                                                  ? Colors
                                                                      .white24
                                                                  : Colors.grey
                                                                      .shade300))),
                                                  child: Text(opt.label,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isSel ? Colors.white : (th.isDark ? Colors.white70 : Colors.black87)))));
                                        }).toList()))),
                            ValueListenableBuilder<AlarmMinutes>(
                                valueListenable: alarmN,
                                builder: (_, alarm, __) {
                                  if (alarm == AlarmMinutes.none)
                                    return const SizedBox.shrink();
                                  return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Divider(
                                            height: 1,
                                            color: th.isDark
                                                ? Colors.white12
                                                : Colors.grey[300]),
                                        Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 12, 16, 4),
                                            child: Text('알림 방식',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: th.isDark
                                                        ? Colors.white54
                                                        : Colors.black54))),
                                        Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 0, 16, 12),
                                            child:
                                                ValueListenableBuilder<
                                                        AlarmMode>(
                                                    valueListenable: alarmModeN,
                                                    builder: (_, mode, __) =>
                                                        Wrap(
                                                            spacing: 8,
                                                            runSpacing: 8,
                                                            children: AlarmMode
                                                                .values
                                                                .map((opt) {
                                                              final isSel =
                                                                  mode == opt;
                                                              return GestureDetector(
                                                                  onTap: () =>
                                                                      alarmModeN
                                                                              .value =
                                                                          opt,
                                                                  child: Container(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              12,
                                                                          vertical:
                                                                              6),
                                                                      decoration: BoxDecoration(
                                                                          color: isSel
                                                                              ? th.primaryAccent.withValues(alpha: 0.15)
                                                                              : Colors.transparent,
                                                                          borderRadius: BorderRadius.circular(20),
                                                                          border: Border.all(color: isSel ? th.primaryAccent : (th.isDark ? Colors.white24 : Colors.grey.shade400))),
                                                                      child: Text(opt.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSel ? th.primaryAccent : (th.isDark ? Colors.white70 : Colors.black87)))));
                                                            }).toList())))
                                      ]);
                                })
                          ])),
                  const SizedBox(height: 18),
                  _buildColorPicker(colorN)
                ])),
                actions: [
                  TextButton(
                      onPressed: () {
                        if (dlgCtx.mounted) Navigator.pop(dlgCtx);
                      },
                      child: Text('취소',
                          style: TextStyle(
                              color:
                                  th.isDark ? Colors.white54 : Colors.grey))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: th.primaryAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      onPressed: () async {
                        if (ctrl.text.trim().isEmpty) {
                          _showAlert(dlgCtx, '일정을 입력해 주세요.');
                          return;
                        }
                        final sD = startDateN.value;
                        final eD = endDateN.value;
                        final isAllDay = isAllDayN.value;
                        if (!isAllDay) {
                          final sf = DateTime(sD.year, sD.month, sD.day,
                              startTimeN.value.hour, startTimeN.value.minute);
                          final ef = DateTime(eD.year, eD.month, eD.day,
                              endTimeN.value.hour, endTimeN.value.minute);
                          if (ef.isBefore(sf)) {
                            _showAlert(dlgCtx, '시작/종료 일시를 확인해 주세요.');
                            return;
                          }
                        } else {
                          if (DateTime(eD.year, eD.month, eD.day)
                              .isBefore(DateTime(sD.year, sD.month, sD.day))) {
                            _showAlert(dlgCtx, '시작/종료 일시를 확인해 주세요.');
                            return;
                          }
                        }
                        final title = ctrl.text.trim();
                        final sDStr = _dateKey(sD);
                        final eDStr = _dateKey(eD);
                        String? sT, eT;
                        if (!isAllDay) {
                          sT =
                              '${startTimeN.value.hour.toString().padLeft(2, '0')}:${startTimeN.value.minute.toString().padLeft(2, '0')}';
                          eT =
                              '${endTimeN.value.hour.toString().padLeft(2, '0')}:${endTimeN.value.minute.toString().padLeft(2, '0')}';
                        }
                        final newEvent = CalendarEvent(
                            id: isEdit
                                ? existingEvent.id
                                : EventStorage.generateId(),
                            title: title,
                            date: sDStr,
                            endDate: eDStr,
                            colorValue: colorN.value,
                            isAllDay: isAllDay,
                            startTime: sT,
                            endTime: eT,
                            alarmMinutes: alarmN.value,
                            eventAlarmMode: alarmModeN.value,
                            isAlarmOn: isEdit ? existingEvent.isAlarmOn : true);
                        const int maxLimit = 500;
                        if (!isEdit && _allEvents.length >= maxLimit) {
                          _showAlert(dlgCtx, '일정은 최대 $maxLimit개까지 등록할 수 있습니다.');
                          return;
                        }
                        if (isEdit) {
                          final idx = _allEvents
                              .indexWhere((e) => e.id == existingEvent.id);
                          if (idx != -1) {
                            _allEvents[idx] = newEvent;
                          }
                        } else {
                          _allEvents.add(newEvent);
                        }
                        await EventStorage.saveAll(_allEvents);
                        final alarmDt = newEvent.alarmDateTime;
                        if (alarmDt != null && newEvent.isAlarmOn) {
                          await NotificationService.scheduleEventAlarm(
                              event: newEvent, settings: _appSettings);
                        }
                        _rebuildIndex(_allEvents);
                        if (dlgCtx.mounted) {
                          Navigator.pop(dlgCtx);
                        }
                      },
                      child: const Text('저장'))
                ])).then((_) {
      ctrl.dispose();
      startDateN.dispose();
      endDateN.dispose();
      isAllDayN.dispose();
      startTimeN.dispose();
      endTimeN.dispose();
      colorN.dispose();
      alarmN.dispose();
      alarmModeN.dispose();
    });
  }

  Widget _buildPickerRow(
      {required String label,
      required ValueNotifier<DateTime> notifier,
      required BuildContext parentCtx,
      required bool isDate,
      required VoidCallback onChanged}) {
    return ValueListenableBuilder<DateTime>(
        valueListenable: notifier,
        builder: (_, value, __) {
          final displayText = isDate
              ? _formatDateKorean(value)
              : _formatHHmm(
                  '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}');
          return InkWell(
              onTap: () async {
                DateTime temp = value;
                await showModalBottomSheet<void>(
                    context: parentCtx,
                    builder: (bsCtx) => Container(
                        color:
                            th.isDark ? const Color(0xFF2A2640) : Colors.white,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(isDate ? '날짜 선택' : '시간 선택',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: th.isDark
                                                ? Colors.white
                                                : Colors.black87)),
                                    TextButton(
                                        onPressed: () {
                                          notifier.value = temp;
                                          onChanged();
                                          Navigator.pop(bsCtx);
                                        },
                                        child: Text('완료',
                                            style: TextStyle(
                                                color: th.primaryAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)))
                                  ])),
                          const Divider(height: 1),
                          SizedBox(
                              height: 220,
                              child: CupertinoTheme(
                                  data: CupertinoThemeData(
                                      textTheme: CupertinoTextThemeData(
                                          dateTimePickerTextStyle: TextStyle(
                                              color: th.isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 22))),
                                  child: CupertinoDatePicker(
                                      mode: isDate
                                          ? CupertinoDatePickerMode.date
                                          : CupertinoDatePickerMode.time,
                                      initialDateTime: value,
                                      onDateTimeChanged: (v) => temp = v)))
                        ])));
              },
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label,
                            style: TextStyle(
                                color:
                                    th.isDark ? Colors.white70 : Colors.black87,
                                fontSize: 15)),
                        Text(displayText,
                            style: TextStyle(
                                color: th.primaryAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 15))
                      ])));
        });
  }

  void _showAlert(BuildContext ctx, String msg) {
    showDialog(
        context: ctx,
        builder: (c) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('⚠️ 알림',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                content: Text(msg),
                actions: [
                  TextButton(
                      onPressed: () {
                        if (c.mounted) Navigator.pop(c);
                      },
                      child: const Text('확인'))
                ]));
  }

  void _showActionSheet(CalendarEvent event) {
    showModalBottomSheet(
        context: context,
        backgroundColor: _isTodoSky
            ? const Color(0xFF3A3F5C)
            : (th.isDark ? const Color(0xFF2A2640) : Colors.white),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2))),
                  ListTile(
                      leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: th.iconBg, shape: BoxShape.circle),
                          child: Icon(Icons.edit, color: th.iconColor)),
                      title: Text('수정하기',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: (th.isDark || _isTodoSky)
                                  ? Colors.white
                                  : Colors.black)),
                      onTap: () {
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        _showEventDialog(existingEvent: event);
                      }),
                  ListTile(
                      leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.delete,
                              color: Colors.redAccent)),
                      title: const Text('삭제하기',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent)),
                      onTap: () async {
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (event.alarmMinutes != AlarmMinutes.none) {
                          await NotificationService.cancelAlarm(event.id);
                        }
                        _allEvents.removeWhere((e) => e.id == event.id);
                        await EventStorage.saveAll(_allEvents);
                        _rebuildIndex(_allEvents);
                      })
                ]))));
  }

  @override
  Widget build(BuildContext context) {
    if (_isTodoSky) {
      return _buildTodoSkyLayout();
    }
    return Scaffold(
        backgroundColor: th.scaffoldBg,
        appBar: _buildAppBar(),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: th.primaryAccent))
            : Column(children: [
                _buildCalendarSection(),
                _buildSectionLabel(),
                Expanded(child: _buildEventList())
              ]),
        floatingActionButton: _buildFAB());
  }

  Widget _buildTodoSkyLayout() {
    final panelBg = th.bottomPanelBg ?? const Color(0xFF2D3142);
    final displayDay = _selectedDay ?? _focusedDay;
    final isToday = isSameDay(displayDay, DateTime.now());
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                _buildCalendarSection(),
                Expanded(
                    child: Container(
                        decoration: BoxDecoration(
                            color: panelBg,
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(28),
                                topRight: Radius.circular(28))),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 20, 24, 8),
                                  child: Text(
                                      isToday
                                          ? 'Today'
                                          : _formatDateKorean(displayDay),
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white))),
                              Expanded(child: _buildEventList())
                            ])))
              ]),
        floatingActionButton: _buildFAB());
  }

  AppBar _buildAppBar() {
    return AppBar(
        backgroundColor: th.appBarBg,
        elevation: 0,
        centerTitle: true,
        title: Text('My Calendar',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: th.appBarText,
                fontSize: 18)),
        leading: IconButton(
            onPressed: _showAppSettingsSheet,
            icon: Icon(Icons.settings_outlined, color: th.appBarText),
            tooltip: '앱 설정'),
        actions: [
          TextButton(
              onPressed: () {
                final now = DateTime.now();
                setState(() {
                  _focusedDay = now;
                  _selectedDay = now;
                  _selectedEvents = _eventsByDate[_dateKey(now)] ?? [];
                });
              },
              child: Text('오늘',
                  style: TextStyle(
                      color: th.primaryAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14))),
          IconButton(
              onPressed: _showThemePicker,
              icon: Icon(Icons.view_headline, color: th.appBarText, size: 28),
              tooltip: '테마 변경')
        ]);
  }

  Widget _buildFAB() => FloatingActionButton(
      onPressed: () => _showEventDialog(),
      backgroundColor: th.primaryAccent,
      foregroundColor: Colors.white,
      elevation: 4,
      child: const Icon(Icons.add, size: 28));

  Widget _buildSectionLabel() => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text('일정 목록',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: th.sectionLabelText)),
          const Spacer(),
          Text('전체 무음',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: th.isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.75,
            child: CupertinoSwitch(
              activeTrackColor: Colors.grey.shade400,
              value: _appSettings.globalSilentMode,
              onChanged: (val) async {
                final updated = _appSettings.copyWith(globalSilentMode: val);
                setState(() => _appSettings = updated);
                await AppSettingsStorage.save(updated);
                await _rescheduleAllAlarms();
              },
            ),
          )
        ],
      ));

  Widget _buildCalendarSection() {
    final isFloating =
        _currentTheme == AppTheme.todoSky || _currentTheme == AppTheme.darkNeon;
    if (isFloating) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
              decoration: BoxDecoration(
                  color: th.calendarBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4))
                  ]),
              child: _tableCalendar()));
    }
    return Container(
        decoration: BoxDecoration(
            color: th.calendarBg,
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: _tableCalendar());
  }

  Widget _buildCustomCell(DateTime day,
      {bool isToday = false, bool isSelected = false, bool isOutside = false}) {
    final events = _getEventsForDay(day);
    final showTextInside = _showTextInside;
    Color textColor;

    if (isOutside) {
      textColor = th.isDark ? Colors.white24 : Colors.grey[400]!;
    } else if (day.weekday == DateTime.sunday) {
      textColor = Colors.redAccent;
    } else if (day.weekday == DateTime.saturday) {
      textColor = Colors.blueAccent;
    } else {
      textColor = th.isDark ? Colors.white : const Color(0xFF333333);
    }

    final lunarTextColor = textColor;
    Color? todayRingColor;
    if (isToday && !isSelected && !isOutside) {
      if (day.weekday == DateTime.sunday) {
        todayRingColor = Colors.redAccent;
      } else if (day.weekday == DateTime.saturday) {
        todayRingColor = Colors.blueAccent;
      } else {
        todayRingColor = th.isDark ? Colors.white70 : Colors.black87;
      }
    }
    if (isSelected) {
      textColor = Colors.white;
    }

    String? lunarDayText;
    if (_appSettings.showLunarCalendar) {
      final dKey = _dateKey(day);
      if (_lunarCache.containsKey(dKey)) {
        lunarDayText = _lunarCache[dKey];
      } else {
        if (_lunarCache.length > 1000) _lunarCache.clear();
        try {
          final lunar = Lunar.fromDate(day);
          lunarDayText = lunar.getDay().toString();
          _lunarCache[dKey] = lunarDayText;
        } catch (_) {}
      }
    }

    Widget dateWidget = Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
            color: isSelected ? th.primaryAccent : null,
            border: todayRingColor != null
                ? Border.all(color: todayRingColor, width: 1.8)
                : null,
            shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text('${day.day}',
            style: TextStyle(
                color: textColor,
                fontWeight:
                    (isToday || isSelected) ? FontWeight.bold : FontWeight.w500,
                fontSize: 13)));
    Widget cellHeader;
    if (lunarDayText != null) {
      cellHeader = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            dateWidget,
            const SizedBox(width: 2),
            Text(lunarDayText,
                style: TextStyle(
                    color: lunarTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500))
          ]);
    } else {
      cellHeader = dateWidget;
    }

    return Container(
        margin: const EdgeInsets.only(top: 2, bottom: 2),
        child: Column(
            crossAxisAlignment: showTextInside
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.center,
            children: [
              Align(
                  alignment: showTextInside
                      ? (_currentTheme == AppTheme.samsung
                          ? Alignment.topLeft
                          : Alignment.topCenter)
                      : Alignment.center,
                  child: Padding(
                      padding: EdgeInsets.only(
                          top: showTextInside ? 3.0 : 5.0,
                          left: showTextInside ? 4.0 : 0),
                      child: cellHeader)),
              if (showTextInside && events.isNotEmpty)
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child:
                      Column(children: _buildEventBars(day, events, textColor)),
                )),
              if (!showTextInside && events.isNotEmpty && !isOutside)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 2, bottom: 2, left: 2, right: 2),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 2.5,
                        runSpacing: 2.5,
                        children: events.take(10).map((e) {
                          final color = e.colorValue != null
                              ? Color(e.colorValue!)
                              : th.primaryAccent;
                          return Container(
                              width: 4.5,
                              height: 4.5,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle));
                        }).toList(),
                      ),
                    ),
                  ),
                )
            ]));
  }

  List<Widget> _buildEventBars(
      DateTime day, List<CalendarEvent> events, Color textColor) {
    final dayKey = _dateKey(day);
    List<Widget> bars = [];

    int maxBars;
    int maxLines;
    double fontSize;
    double paddingVert;

    if (events.length == 1) {
      maxBars = 1;
      maxLines = 2;
      fontSize = 10.0;
      paddingVert = 2.0;
    } else if (events.length == 2) {
      maxBars = 2;
      maxLines = 1;
      fontSize = 9.0;
      paddingVert = 1.5;
    } else if (events.length == 3) {
      maxBars = 3;
      maxLines = 1;
      fontSize = 8.2;
      paddingVert = 1.0;
    } else {
      maxBars = 2;
      maxLines = 1;
      fontSize = 9.0;
      paddingVert = 1.5;
    }

    for (int i = 0; i < math.min(events.length, maxBars); i++) {
      final e = events[i];
      final color =
          e.colorValue != null ? Color(e.colorValue!) : th.primaryAccent;
      final isFirst = dayKey == e.date;
      final isLast = dayKey == (e.endDate ?? e.date);
      final dTitle = (!e.isAllDay && e.startTime != null && isFirst)
          ? '${e.startTime} ${e.title}'
          : e.title;

      bars.add(Container(
        width: double.infinity,
        margin: EdgeInsets.only(
            bottom: 2, left: isFirst ? 3.0 : 0, right: isLast ? 3.0 : 0),
        padding: EdgeInsets.only(
            left: isFirst ? 4.0 : 2.0,
            right: 2,
            top: paddingVert,
            bottom: paddingVert),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.horizontal(
                left: Radius.circular(isFirst ? 4.0 : 0),
                right: Radius.circular(isLast ? 4.0 : 0))),
        child: Text(dTitle,
            style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                height: 1.1,
                fontWeight: FontWeight.bold),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis),
      ));
    }

    if (events.length > maxBars) {
      bars.add(Expanded(
          child: Center(
              child: Text('+${events.length - maxBars}',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: th.isDark ? Colors.white54 : Colors.black54)))));
    }
    return bars;
  }

  Widget _tableCalendar() {
    String Function(DateTime, dynamic) headerFmt =
        (d, _) => '${d.year}년 ${d.month}월';
    if (_currentTheme == AppTheme.apple || _currentTheme == AppTheme.naver) {
      headerFmt = (d, _) => '${d.year}. ${d.month}';
    }
    final headerColor = _isTodoSky ? const Color(0xFF2D3142) : th.appBarText;
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
            rowHeight: _showTextInside ? 80 : 56,
            calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  const dows = ['월', '화', '수', '목', '금', '토', '일'];
                  Color c = headerColor.withValues(alpha: 0.6);
                  if (day.weekday == DateTime.sunday) {
                    c = Colors.redAccent;
                  } else if (day.weekday == DateTime.saturday) {
                    c = Colors.blueAccent;
                  }
                  return Center(
                      child: Text(dows[day.weekday - 1],
                          style: TextStyle(
                              color: c,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)));
                },
                defaultBuilder: (_, day, __) => _buildCustomCell(day),
                todayBuilder: (_, day, __) =>
                    _buildCustomCell(day, isToday: true),
                selectedBuilder: (_, day, __) =>
                    _buildCustomCell(day, isSelected: true),
                outsideBuilder: (_, day, __) =>
                    _buildCustomCell(day, isOutside: true),
                markerBuilder: (_, __, ___) => const SizedBox.shrink()),
            headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: headerFmt,
                titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: headerColor),
                leftChevronIcon: Icon(Icons.chevron_left, color: headerColor),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: headerColor))));
  }

  Widget _buildEventList() {
    if (_selectedEvents.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Text('이 날의 일정이 없어요',
                  style: TextStyle(
                      color: th.sectionLabelText.withValues(alpha: 0.5),
                      fontSize: 16))));
    }
    return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _selectedEvents.length,
        itemBuilder: (_, i) => GestureDetector(
            onTap: () => _showActionSheet(_selectedEvents[i]),
            child: _buildListItemByTheme(_selectedEvents[i])));
  }

  // 💡 [v2.6.0] 개별 알림 아이콘: 전체 무음(globalSilentMode) 활성화 시 Zz 아이콘으로 일괄 변경
  Widget _buildTitleColumn(CalendarEvent event, String dateInfo,
      {Color? titleColor, double titleSize = 15, double dateSize = 12}) {
    final isGlobalSilent = _appSettings.globalSilentMode;
    final effectiveAlarmOn = event.isAlarmOn && !isGlobalSilent;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text(event.title,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: titleSize,
                    color: titleColor ?? th.eventTitleText))),
        if (event.alarmMinutes != AlarmMinutes.none)
          GestureDetector(
            onTap: () async {
              if (isGlobalSilent) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('전체 무음 상태입니다. 먼저 전체 무음을 해제해주세요.'),
                    duration: Duration(seconds: 2)));
                return;
              }
              final idx = _allEvents.indexWhere((e) => e.id == event.id);
              if (idx != -1) {
                final updatedEvent = _allEvents[idx]
                    .copyWith(isAlarmOn: !_allEvents[idx].isAlarmOn);
                _allEvents[idx] = updatedEvent;
                await EventStorage.saveAll(_allEvents);

                if (updatedEvent.isAlarmOn) {
                  await NotificationService.scheduleEventAlarm(
                      event: updatedEvent, settings: _appSettings);
                } else {
                  await NotificationService.cancelAlarm(updatedEvent.id);
                }

                setState(() {
                  final selIdx =
                      _selectedEvents.indexWhere((e) => e.id == event.id);
                  if (selIdx != -1) _selectedEvents[selIdx] = updatedEvent;
                });
              }
            },
            child: Padding(
                padding:
                    const EdgeInsets.only(left: 8, right: 4, top: 2, bottom: 2),
                child: Icon(
                    effectiveAlarmOn
                        ? Icons.notifications_active
                        : Icons.notifications_paused, // 🔕 Zz 모양 수면 알람 아이콘
                    size: 16,
                    color: effectiveAlarmOn
                        ? th.primaryAccent
                        : Colors.grey.withValues(alpha: 0.5))),
          )
      ]),
      if (dateInfo.isNotEmpty)
        Text(dateInfo, style: TextStyle(fontSize: dateSize, color: Colors.grey))
    ]);
  }

  Widget _buildListItemByTheme(CalendarEvent event) {
    final color =
        event.colorValue != null ? Color(event.colorValue!) : th.primaryAccent;
    final dateInfo = _makeTimeString(event);
    final isGlobalSilent = _appSettings.globalSilentMode;
    final effectiveAlarmOn = event.isAlarmOn && !isGlobalSilent;

    switch (_currentTheme) {
      case AppTheme.apple:
        return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
                border: Border(
                    bottom:
                        BorderSide(color: Colors.grey.withValues(alpha: 0.1)))),
            child: Row(children: [
              Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(child: _buildTitleColumn(event, dateInfo, titleSize: 16))
            ]));
      case AppTheme.samsung:
      case AppTheme.naver:
        return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                color: th.cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4)
                ]),
            child: Row(children: [
              Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: color,
                      shape: _currentTheme == AppTheme.samsung
                          ? BoxShape.circle
                          : BoxShape.rectangle,
                      borderRadius: _currentTheme == AppTheme.naver
                          ? BorderRadius.circular(3)
                          : null)),
              const SizedBox(width: 12),
              Expanded(child: _buildTitleColumn(event, dateInfo))
            ]));
      case AppTheme.todoSky:
        return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                color: th.cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]),
            child: Row(children: [
              Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: Icon(Icons.event, color: color, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Expanded(
                          child: Text(event.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white))),
                      if (event.alarmMinutes != AlarmMinutes.none)
                        GestureDetector(
                            onTap: () async {
                              if (isGlobalSilent) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            '전체 무음 상태입니다. 먼저 전체 무음을 해제해주세요.'),
                                        duration: Duration(seconds: 2)));
                                return;
                              }
                              final idx = _allEvents
                                  .indexWhere((e) => e.id == event.id);
                              if (idx != -1) {
                                final updatedEvent = _allEvents[idx].copyWith(
                                    isAlarmOn: !_allEvents[idx].isAlarmOn);
                                _allEvents[idx] = updatedEvent;
                                await EventStorage.saveAll(_allEvents);
                                if (updatedEvent.isAlarmOn) {
                                  await NotificationService.scheduleEventAlarm(
                                      event: updatedEvent,
                                      settings: _appSettings);
                                } else {
                                  await NotificationService.cancelAlarm(
                                      updatedEvent.id);
                                }
                                setState(() {
                                  final selIdx = _selectedEvents
                                      .indexWhere((e) => e.id == event.id);
                                  if (selIdx != -1)
                                    _selectedEvents[selIdx] = updatedEvent;
                                });
                              }
                            },
                            child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                    effectiveAlarmOn
                                        ? Icons.notifications_active
                                        : Icons.notifications_paused,
                                    size: 14,
                                    color: effectiveAlarmOn
                                        ? th.primaryAccent
                                        : Colors.grey.withValues(alpha: 0.5))))
                    ]),
                    if (dateInfo.isNotEmpty) const SizedBox(height: 2),
                    if (dateInfo.isNotEmpty)
                      Text(dateInfo,
                          style:
                              TextStyle(fontSize: 12, color: th.eventSubText))
                  ])),
              if (event.startTime != null)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(_formatHHmm(event.startTime!),
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)))
            ]));
      default:
        return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                color: th.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: th.cardBorder)),
            child: Row(children: [
              Icon(Icons.check_circle_outline, color: color),
              const SizedBox(width: 12),
              Expanded(child: _buildTitleColumn(event, dateInfo, dateSize: 11))
            ]));
    }
  }
}

class _AppSettingsSheet extends StatefulWidget {
  final AppSettings initial;
  final bool isDark;
  final Color accent;
  final ValueChanged<AppSettings> onChanged;
  const _AppSettingsSheet(
      {required this.initial,
      required this.isDark,
      required this.accent,
      required this.onChanged});
  @override
  State<_AppSettingsSheet> createState() => _AppSettingsSheetState();
}

class _AppSettingsSheetState extends State<_AppSettingsSheet> {
  late AppSettings _s;
  @override
  void initState() {
    super.initState();
    _s = widget.initial;
  }

  void _update(AppSettings next) {
    setState(() => _s = next);
    widget.onChanged(next);
  }

  Color get _textColor =>
      widget.isDark ? Colors.white : const Color(0xFF1A1A2E);
  Color get _subColor => widget.isDark ? Colors.white54 : Colors.black54;
  Color get _tileBg =>
      widget.isDark ? const Color(0xFF3D3760) : const Color(0xFFF5F5F5);

  Future<void> _pickCustomSound() async {
    final status = await Permission.audio.request();
    if (!status.isGranted) await Permission.storage.request();

    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.audio, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      final newPath = result.files.single.path!;
      if (_s.lastCustomChannelId != null) {
        final impl = NotificationService._plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await impl?.deleteNotificationChannel(_s.lastCustomChannelId!);
      }
      _update(_s.copyWith(
          soundOption: NotificationSound.custom,
          customSoundPath: newPath,
          lastCustomChannelId:
              'cal_custom_${newPath.hashCode}_${_s.effectiveMode.index}'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Container(
            color: widget.isDark ? const Color(0xFF2A2640) : Colors.white,
            child: ListView(
                controller: scrollCtrl,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(2)))),
                  Text('⚙️ 앱 설정',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _textColor)),
                  const SizedBox(height: 20),
                  _sectionTitle('📅 달력 설정'),
                  _switchTile(
                      icon: Icons.calendar_today_outlined,
                      label: '음력 표시',
                      subtitle: '달력 날짜 옆에 음력을 표시합니다',
                      value: _s.showLunarCalendar,
                      onChanged: (v) =>
                          _update(_s.copyWith(showLunarCalendar: v))),
                  const SizedBox(height: 16),
                  _sectionTitle('🔔 알림 기본 설정'),
                  _switchTile(
                      icon: Icons.notifications_outlined,
                      label: '알림 사용',
                      subtitle: '모든 일정 알림을 켜거나 끕니다',
                      value: _s.masterEnabled,
                      onChanged: (v) => _update(_s.copyWith(masterEnabled: v))),
                  if (_s.masterEnabled) ...[
                    const SizedBox(height: 16),
                    _sectionTitle('알람 소리 및 진동 기본값 (일정 추가 시 적용)'),
                    _switchTile(
                        icon: Icons.volume_up_outlined,
                        label: '소리 허용',
                        subtitle: '기본적으로 소리 알람을 사용합니다',
                        value: _s.soundEnabled,
                        onChanged: (v) =>
                            _update(_s.copyWith(soundEnabled: v))),
                    _switchTile(
                        icon: Icons.vibration_outlined,
                        label: '진동 허용',
                        subtitle: '기본적으로 진동 알람을 사용합니다',
                        value: _s.vibrationEnabled,
                        onChanged: (v) =>
                            _update(_s.copyWith(vibrationEnabled: v))),
                    if (_s.soundEnabled) ...[
                      const SizedBox(height: 16),
                      _sectionTitle('소리 설정'),
                      ...NotificationSound.values.map((s) {
                        if (s == NotificationSound.custom) {
                          final isCustomSel =
                              _s.soundOption == NotificationSound.custom;
                          return GestureDetector(
                              onTap: _pickCustomSound,
                              child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                      color: isCustomSel
                                          ? widget.accent
                                              .withValues(alpha: 0.12)
                                          : _tileBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: isCustomSel
                                              ? widget.accent
                                              : Colors.transparent,
                                          width: 1.5)),
                                  child: Row(children: [
                                    Icon(Icons.library_music_outlined,
                                        color: isCustomSel
                                            ? widget.accent
                                            : _subColor,
                                        size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(s.label,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isCustomSel
                                                      ? widget.accent
                                                      : _textColor)),
                                          if (_s.customSoundPath != null)
                                            Text(
                                                _s.customSoundPath!
                                                    .split('/')
                                                    .last,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: _subColor),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis)
                                        ])),
                                    if (isCustomSel)
                                      Icon(Icons.check_circle,
                                          color: widget.accent, size: 20)
                                  ])));
                        }
                        final isSel = _s.soundOption == s;
                        return GestureDetector(
                            onTap: () => _update(_s.copyWith(soundOption: s)),
                            child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                    color: isSel
                                        ? widget.accent.withValues(alpha: 0.12)
                                        : _tileBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: isSel
                                            ? widget.accent
                                            : Colors.transparent,
                                        width: 1.5)),
                                child: Row(children: [
                                  Icon(Icons.music_note,
                                      color: isSel ? widget.accent : _subColor,
                                      size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Text(s.label,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isSel
                                                  ? widget.accent
                                                  : _textColor))),
                                  if (isSel)
                                    Icon(Icons.check_circle,
                                        color: widget.accent, size: 20)
                                ])));
                      }),
                    ],
                    if (_s.vibrationEnabled) ...[
                      const SizedBox(height: 16),
                      _sectionTitle('진동 패턴'),
                      ...VibrationPattern.values
                          .map((p) => _vibrationPatternTile(p))
                    ]
                  ],
                  if (_s.masterEnabled) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                            icon: const Icon(Icons.play_circle_fill_outlined),
                            label: const Text('현재 설정으로 알림 테스트해보기'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: widget.accent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14))),
                            onPressed: () async {
                              await NotificationService.showTestNotification(
                                  _s, _s.effectiveMode);
                            }))
                  ],
                  const SizedBox(height: 32)
                ])));
  }

  Widget _vibrationPatternTile(VibrationPattern p) {
    final isSel = _s.vibrationPattern == p;
    return GestureDetector(
        onTap: () => _update(_s.copyWith(vibrationPattern: p)),
        child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: isSel ? widget.accent.withValues(alpha: 0.12) : _tileBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isSel ? widget.accent : Colors.transparent,
                    width: 1.5)),
            child: Row(children: [
              Icon(Icons.vibration,
                  color: isSel ? widget.accent : _subColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(p.label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSel ? widget.accent : _textColor))),
              if (isSel)
                Icon(Icons.check_circle, color: widget.accent, size: 20)
            ])));
  }

  Widget _sectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _subColor,
              letterSpacing: 0.5)));
  Widget _switchTile(
      {required IconData icon,
      required String label,
      required String subtitle,
      required bool value,
      required ValueChanged<bool> onChanged,
      Color? activeColor}) {
    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: _tileBg, borderRadius: BorderRadius.circular(14)),
        child: SwitchListTile(
            secondary: Icon(icon,
                color: value ? (activeColor ?? widget.accent) : _subColor),
            title: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: _textColor)),
            subtitle: Text(subtitle,
                style: TextStyle(fontSize: 12, color: _subColor)),
            value: value,
            activeTrackColor: activeColor ?? widget.accent,
            activeThumbColor: Colors.white,
            onChanged: onChanged));
  }
}
