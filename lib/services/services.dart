// v4.3.0
// gemini_services.dart
// lib/services/services.dart
import 'dart:io' show File, Platform;
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';

void appLog(String msg) {
  if (!kReleaseMode) {
    debugPrint(msg);
  }
}

String encodeEventsToJson(List<CalendarEvent> events) =>
    jsonEncode(events.map((e) => e.toJson()).toList());

List<CalendarEvent> decodeEventsFromJson(String raw) =>
    (jsonDecode(raw) as List)
        .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();

// ── NotificationService ──────────────────────────────────────────

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // 💡 [최적화] 시간대 설정만 빠르게 진행하는 경량 초기화 함수
  static Future<void> initMinimal() async {
    if (!_isMobile) {
      return;
    }
    tz_data.initializeTimeZones();
    try {
      final loc =
          tz.getLocation((await FlutterTimezone.getLocalTimezone()).toString());
      tz.setLocalLocation(loc);
    } catch (e) {
      appLog('[NotifSvc] 시간대 설정 실패, Asia/Seoul 사용: $e');
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    }
  }

  // 💡 [최적화] 무거운 알림 플러그인 초기화는 앱 렌더링 이후에 호출
  static Future<void> initNotifications() async {
    if (!_isMobile) {
      return;
    }
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));
  }

  static Future<String> _ensureChannel(AlarmMode mode, NotificationSound sound,
      VibrationPattern vib, String? customPath) async {
    if (!_isMobile) {
      return 'cal_silent';
    }
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (impl == null) {
      return 'cal_silent';
    }

    if (mode == AlarmMode.silent) {
      await impl.createNotificationChannel(const AndroidNotificationChannel(
          'cal_silent', '무음 알림',
          importance: Importance.low,
          playSound: false,
          enableVibration: false));
      return 'cal_silent';
    }

    String id = 'cal';
    String name = '알림';
    AndroidNotificationSound? snd;
    bool playSnd = false, playVib = false;

    if (mode == AlarmMode.soundOnly || mode == AlarmMode.soundAndVibration) {
      playSnd = true;
      if (sound == NotificationSound.custom && customPath != null) {
        snd = UriAndroidNotificationSound('file://$customPath');
        id = '${id}_cust_${customPath.hashCode}';
        name = '내 음악 알림';
      } else {
        if (sound != NotificationSound.system) {
          snd = RawResourceAndroidNotificationSound(sound.fileName);
        }
        id = '${id}_snd_${sound.name}';
        name = '소리 알림';
      }
    }
    if (mode == AlarmMode.vibrationOnly ||
        mode == AlarmMode.soundAndVibration) {
      playVib = true;
      id = '${id}_vib_${vib.name}';
      name = playSnd ? '$name (진동포함)' : '진동 전용 알림';
    }

    await impl.createNotificationChannel(AndroidNotificationChannel(id, name,
        importance: Importance.high,
        playSound: playSnd,
        sound: snd,
        enableVibration: playVib,
        vibrationPattern: playVib ? vib.patternInt64 : null));
    return id;
  }

  static Future<void> scheduleEventAlarm({
    required CalendarEvent event,
    required AppSettings settings,
  }) async {
    if (!_isMobile ||
        !settings.masterEnabled ||
        !event.isAlarmOn ||
        event.alarmDateTime == null ||
        event.alarmDateTime!.isBefore(DateTime.now())) {
      return;
    }

    try {
      final mode =
          settings.globalSilentMode ? AlarmMode.silent : event.eventAlarmMode;
      final channelId = await _ensureChannel(mode, event.soundOption,
          event.vibrationPattern, event.customSoundPath);

      AndroidNotificationSound? snd;
      if (mode == AlarmMode.soundOnly || mode == AlarmMode.soundAndVibration) {
        if (event.soundOption == NotificationSound.custom &&
            event.customSoundPath != null) {
          snd = UriAndroidNotificationSound('file://${event.customSoundPath}');
        } else if (event.soundOption != NotificationSound.system) {
          snd = RawResourceAndroidNotificationSound(event.soundOption.fileName);
        }
      }

      Int64List? vib;
      if (mode == AlarmMode.vibrationOnly ||
          mode == AlarmMode.soundAndVibration) {
        vib = event.vibrationPattern.patternInt64;
      }

      await _plugin.zonedSchedule(
        event.id,
        '📅 일정 알림',
        event.title,
        tz.TZDateTime.from(event.alarmDateTime!, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(channelId, '캘린더 알림',
              importance:
                  mode == AlarmMode.silent ? Importance.low : Importance.high,
              priority: Priority.high,
              sound: snd,
              playSound:
                  snd != null || event.soundOption == NotificationSound.system,
              enableVibration: vib != null,
              vibrationPattern: vib,
              silent: mode == AlarmMode.silent),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      appLog('[NotifSvc] 알림 스케줄 실패: $e');
    }
  }

  static Future<void> cancelAlarm(int id) async {
    if (!_isMobile) {
      return;
    }
    await _plugin.cancel(id);
  }

  static Future<void> showTestNotification(
      AppSettings settings, AlarmMode testMode) async {
    if (!_isMobile) {
      return;
    }
    try {
      final mode = settings.globalSilentMode ? AlarmMode.silent : testMode;
      final channelId = await _ensureChannel(mode, settings.soundOption,
          settings.vibrationPattern, settings.customSoundPath);

      AndroidNotificationSound? snd;
      if (mode == AlarmMode.soundOnly || mode == AlarmMode.soundAndVibration) {
        if (settings.soundOption == NotificationSound.custom &&
            settings.customSoundPath != null) {
          snd =
              UriAndroidNotificationSound('file://${settings.customSoundPath}');
        } else if (settings.soundOption != NotificationSound.system) {
          snd = RawResourceAndroidNotificationSound(
              settings.soundOption.fileName);
        }
      }

      Int64List? vib;
      if (mode == AlarmMode.vibrationOnly ||
          mode == AlarmMode.soundAndVibration) {
        vib = settings.vibrationPattern.patternInt64;
      }

      await _plugin.show(
        9999,
        '🔔 테스트 알림',
        '알림이 이렇게 울립니다.',
        NotificationDetails(
          android: AndroidNotificationDetails(channelId, '테스트 알림',
              importance:
                  mode == AlarmMode.silent ? Importance.low : Importance.high,
              priority: Priority.high,
              sound: snd,
              playSound: snd != null ||
                  settings.soundOption == NotificationSound.system,
              enableVibration: vib != null,
              vibrationPattern: vib,
              silent: mode == AlarmMode.silent),
        ),
      );
    } catch (e) {
      appLog('[NotifSvc] 테스트 알림 실패: $e');
    }
  }

  static Future<void> requestPermissions() async {
    if (!_isMobile) {
      return;
    }
    final audioStatus = await Permission.audio.request();
    if (!audioStatus.isGranted) {
      await Permission.storage.request();
    }
    await Permission.notification.request();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestExactAlarmsPermission();
  }
}

// ── Storage ──────────────────────────────────────────────────────

const _ss = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true));

class AppSettingsStorage {
  static final String _key = String.fromCharCodes([
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
    final raw = await _ss.read(key: _key);
    if (raw != null) {
      try {
        return AppSettings.fromJson(jsonDecode(raw));
      } catch (e) {
        appLog('[Settings] 설정 파싱 실패, 기본값 사용: $e');
      }
    }
    return const AppSettings();
  }

  static Future<void> save(AppSettings s) async {
    await _ss.write(key: _key, value: jsonEncode(s.toJson()));
  }
}

class EventStorage {
  static final String _key = String.fromCharCodes([
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

  // 💡 [최적화] 메모이제이션(캐시) 적용: 디스크 I/O를 최소화합니다.
  static List<CalendarEvent>? _cachedEvents;

  static Future<List<CalendarEvent>> loadAll({bool refresh = false}) async {
    if (!refresh && _cachedEvents != null) {
      return _cachedEvents!;
    }
    final raw = await _ss.read(key: _key);
    if (raw == null) {
      _cachedEvents = [];
      return _cachedEvents!;
    }
    try {
      _cachedEvents = await compute(decodeEventsFromJson, raw);
      return _cachedEvents!;
    } catch (e) {
      appLog('[EventStorage] 이벤트 로드 실패: $e');
      _cachedEvents = [];
      return _cachedEvents!;
    }
  }

  static Future<void> saveAll(List<CalendarEvent> events) async {
    final toSave = events.where((e) => !e.isRecurrenceInstance).toList();
    _cachedEvents = toSave; // 캐시 즉시 동기화
    final jsonString = await compute(encodeEventsToJson, toSave);
    await _ss.write(key: _key, value: jsonString);
  }

  static final _rng = math.Random.secure();
  static int generateId() =>
      ((DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF) ^
          ((_rng.nextInt(0xFFFF) << 15) & 0x7FFFFFFF));
}

// ── IcsService ───────────────────────────────────────────────────

class IcsService {
  static String _escapeIcsText(String text) => text
      .replaceAll('\\', '\\\\')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '');

  static Future<void> exportToIcs(List<CalendarEvent> events) async {
    try {
      final buf = StringBuffer();
      buf.writeln('BEGIN:VCALENDAR');
      buf.writeln('VERSION:2.0');
      buf.writeln('PRODID:-//My Calendar App//v4.3.0//EN');

      String formatDt(DateTime d) =>
          '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

      for (final e
          in events.where((e) => !e.isHoliday && !e.isRecurrenceInstance)) {
        buf.writeln('BEGIN:VEVENT');
        buf.writeln('UID:${e.id}@mycalendar.app');
        buf.writeln('SUMMARY:${_escapeIcsText(e.title)}');
        if (e.isAllDay) {
          buf.writeln('DTSTART;VALUE=DATE:${formatDt(e.startDt)}');
          buf.writeln(
              'DTEND;VALUE=DATE:${formatDt(e.endDt.add(const Duration(days: 1)))}');
        } else {
          final sT = (e.startTime ?? '00:00').replaceAll(':', '');
          final eT = (e.endTime ?? '00:00').replaceAll(':', '');
          buf.writeln('DTSTART:${formatDt(e.startDt)}T${sT}00');
          buf.writeln('DTEND:${formatDt(e.endDt)}T${eT}00');
        }
        if (e.recurrenceRule != null) {
          final r = e.recurrenceRule!;
          final freq = r.frequency.name.toUpperCase();
          var rrule = 'RRULE:FREQ=$freq;INTERVAL=${r.interval}';
          if (r.until != null) {
            rrule += ';UNTIL=${formatDt(r.until!)}';
          }
          buf.writeln(rrule);
        }
        buf.writeln('END:VEVENT');
      }
      buf.writeln('END:VCALENDAR');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/my_calendar_backup.ics');
      await file.writeAsString(buf.toString());
      await Share.shareXFiles([XFile(file.path)], text: '내 캘린더 ics 백업 파일입니다.');
    } catch (e) {
      appLog('ICS 내보내기 실패: $e');
    }
  }

  static Future<bool> importFromIcs() async {
    try {
      await Permission.storage.request();
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) {
        return false;
      }

      final content = await File(result.files.single.path!).readAsString();
      final imported = <CalendarEvent>[];
      final lines = const LineSplitter().convert(content);
      bool inEvent = false;
      String? summary, dtStart, dtEnd;

      for (final line in lines) {
        if (line.startsWith('BEGIN:VEVENT')) {
          inEvent = true;
          summary = dtStart = dtEnd = null;
        } else if (line.startsWith('END:VEVENT')) {
          if (inEvent && summary != null && dtStart != null) {
            final sD = _parseDate(dtStart);
            final eD = dtEnd != null ? _parseDate(dtEnd) : sD;
            final sT = _parseTime(dtStart);
            final eT = dtEnd != null ? _parseTime(dtEnd) : sT;
            if (sD != null) {
              imported.add(CalendarEvent(
                id: EventStorage.generateId(),
                title: summary,
                date: _fmtDateStr(sD),
                endDate: eD != null ? _fmtDateStr(eD) : null,
                isAllDay: sT == null,
                startTime: sT,
                endTime: eT,
              ));
            }
          }
          inEvent = false;
        } else if (inEvent) {
          if (line.startsWith('SUMMARY:')) {
            summary = line.substring(8);
          } else if (line.startsWith('DTSTART')) {
            dtStart = line.substring(line.indexOf(':') + 1);
          } else if (line.startsWith('DTEND')) {
            dtEnd = line.substring(line.indexOf(':') + 1);
          }
        }
      }

      if (imported.isNotEmpty) {
        final existing = await EventStorage.loadAll();
        existing.addAll(imported);
        await EventStorage.saveAll(existing);
        return true;
      }
      return false;
    } catch (e) {
      appLog('[ICS] import 실패: $e');
      return false;
    }
  }

  static String _fmtDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parseDate(String v) {
    v = v.replaceAll('\r', '').replaceAll('Z', '');
    if (v.length >= 8) {
      return DateTime.tryParse(
          '${v.substring(0, 4)}-${v.substring(4, 6)}-${v.substring(6, 8)}');
    }
    return null;
  }

  static String? _parseTime(String v) {
    if (v.contains('T') && v.length >= 15) {
      final t = v.indexOf('T');
      return '${v.substring(t + 1, t + 3)}:${v.substring(t + 3, t + 5)}';
    }
    return null;
  }
}
