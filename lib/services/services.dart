// ignore_for_file: curly_braces_in_flow_control_structures
// v3.6.2
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

String encodeEventsToJson(List<CalendarEvent> events) {
  return jsonEncode(events.map((e) => e.toJson()).toList());
}

List<CalendarEvent> decodeEventsFromJson(String raw) {
  return (jsonDecode(raw) as List)
      .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
      .toList();
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> init() async {
    if (!_isMobile) {
      return;
    }
    tz_data.initializeTimeZones();
    try {
      final tz.Location loc =
          tz.getLocation((await FlutterTimezone.getLocalTimezone()).toString());
      tz.setLocalLocation(loc);
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
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

    String idStr = 'cal';
    String nameStr = '알림';
    AndroidNotificationSound? androidSound;
    bool playSnd = false;
    bool playVib = false;

    if (mode == AlarmMode.soundOnly || mode == AlarmMode.soundAndVibration) {
      playSnd = true;
      if (sound == NotificationSound.custom && customPath != null) {
        androidSound = UriAndroidNotificationSound('file://$customPath');
        idStr = '${idStr}_cust_${customPath.hashCode}';
        nameStr = '내 음악 알림';
      } else {
        if (sound != NotificationSound.system) {
          androidSound = RawResourceAndroidNotificationSound(sound.fileName);
        }
        idStr = '${idStr}_snd_${sound.name}';
        nameStr = '소리 알림';
      }
    }
    if (mode == AlarmMode.vibrationOnly ||
        mode == AlarmMode.soundAndVibration) {
      playVib = true;
      idStr = '${idStr}_vib_${vib.name}';
      nameStr = playSnd ? '$nameStr (진동포함)' : '진동 전용 알림';
    }

    await impl.createNotificationChannel(AndroidNotificationChannel(
        idStr, nameStr,
        importance: Importance.high,
        playSound: playSnd,
        sound: androidSound,
        enableVibration: playVib,
        vibrationPattern: playVib ? vib.patternInt64 : null));
    return idStr;
  }

  static Future<void> scheduleEventAlarm(
      {required CalendarEvent event, required AppSettings settings}) async {
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
                  importance: mode == AlarmMode.silent
                      ? Importance.low
                      : Importance.high,
                  priority: Priority.high,
                  sound: snd,
                  playSound: snd != null ||
                      event.soundOption == NotificationSound.system,
                  enableVibration: vib != null,
                  vibrationPattern: vib,
                  silent: mode == AlarmMode.silent)),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime);
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
                  importance: mode == AlarmMode.silent
                      ? Importance.low
                      : Importance.high,
                  priority: Priority.high,
                  sound: snd,
                  playSound: snd != null ||
                      settings.soundOption == NotificationSound.system,
                  enableVibration: vib != null,
                  vibrationPattern: vib,
                  silent: mode == AlarmMode.silent)));
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
    if (android != null) {
      await android.requestExactAlarmsPermission();
    }
  }
}

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
    if (raw == null) {
      return [];
    }
    try {
      return await compute(decodeEventsFromJson, raw);
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<CalendarEvent> events) async {
    final jsonString = await compute(encodeEventsToJson, events);
    await _secureStorage.write(key: _eventsKey, value: jsonString);
  }

  static int generateId() {
    return ((DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF) ^
        ((math.Random().nextInt(0xFFFF) << 15) & 0x7FFFFFFF));
  }
}

class IcsService {
  static Future<void> exportToIcs(List<CalendarEvent> events) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('BEGIN:VCALENDAR');
      buffer.writeln('VERSION:2.0');
      buffer.writeln('PRODID:-//My Calendar App//v3.6.2//EN');

      String formatDt(DateTime d) {
        return '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
      }

      for (var e in events) {
        buffer.writeln('BEGIN:VEVENT');
        buffer.writeln('UID:${e.id}@mycalendar.app');
        buffer.writeln('SUMMARY:${e.title}');

        if (e.isAllDay) {
          buffer.writeln('DTSTART;VALUE=DATE:${formatDt(e.startDt)}');
          buffer.writeln(
              'DTEND;VALUE=DATE:${formatDt(e.endDt.add(const Duration(days: 1)))}');
        } else {
          String startTimeStr = (e.startTime ?? '00:00').replaceAll(':', '');
          String endTimeStr = (e.endTime ?? '00:00').replaceAll(':', '');
          String sTime = '${startTimeStr}00';
          String eTime = '${endTimeStr}00';

          buffer.writeln('DTSTART:${formatDt(e.startDt)}T$sTime');
          buffer.writeln('DTEND:${formatDt(e.endDt)}T$eTime');
        }
        buffer.writeln('END:VEVENT');
      }
      buffer.writeln('END:VCALENDAR');

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/my_calendar_backup.ics');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(file.path)], text: '내 캘린더 ics 백업 파일입니다.');
    } catch (_) {
      appLog('ICS 백업 실패');
    }
  }

  static Future<bool> importFromIcs() async {
    try {
      await Permission.storage.request();
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) {
        return false;
      }

      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      List<CalendarEvent> importedEvents = [];
      final lines = const LineSplitter().convert(content);
      bool inEvent = false;
      String? summary;
      String? dtStart;
      String? dtEnd;

      for (var line in lines) {
        if (line.startsWith('BEGIN:VEVENT')) {
          inEvent = true;
          summary = null;
          dtStart = null;
          dtEnd = null;
        } else if (line.startsWith('END:VEVENT')) {
          if (inEvent && summary != null && dtStart != null) {
            DateTime? sD = _parseIcsDate(dtStart);
            DateTime? eD = dtEnd != null ? _parseIcsDate(dtEnd) : sD;
            String? sT = _parseIcsTime(dtStart);
            String? eT = dtEnd != null ? _parseIcsTime(dtEnd) : sT;
            if (sD != null) {
              importedEvents.add(CalendarEvent(
                id: EventStorage.generateId(),
                title: summary,
                date:
                    '${sD.year}-${sD.month.toString().padLeft(2, '0')}-${sD.day.toString().padLeft(2, '0')}',
                endDate: eD != null
                    ? '${eD.year}-${eD.month.toString().padLeft(2, '0')}-${eD.day.toString().padLeft(2, '0')}'
                    : null,
                isAllDay: (sT == null),
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
      if (importedEvents.isNotEmpty) {
        final existing = await EventStorage.loadAll();
        existing.addAll(importedEvents);
        await EventStorage.saveAll(existing);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static DateTime? _parseIcsDate(String val) {
    val = val.replaceAll('\r', '').replaceAll('Z', '');
    if (val.length >= 8) {
      return DateTime.tryParse(
          '${val.substring(0, 4)}-${val.substring(4, 6)}-${val.substring(6, 8)}');
    }
    return null;
  }

  static String? _parseIcsTime(String val) {
    if (val.contains('T') && val.length >= 15) {
      int t = val.indexOf('T');
      return '${val.substring(t + 1, t + 3)}:${val.substring(t + 3, t + 5)}';
    }
    return null;
  }
}
