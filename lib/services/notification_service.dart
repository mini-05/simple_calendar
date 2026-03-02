// v4.3.9
// lib/services/notification_service.dart
// [Web 호환성 패치] kIsWeb 차단벽 적용 및 dart:io Platform 제거

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/models.dart';
import 'storage_service.dart' show appLog;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  // 💡 dart:io의 Platform 대신 foundation의 defaultTargetPlatform 사용
  static bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> initMinimal() async {
    if (!_isMobile) return;
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

  static Future<void> initNotifications() async {
    if (!_isMobile) return;
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));
  }

  static Future<String> _ensureChannel(AlarmMode mode, NotificationSound sound,
      VibrationPattern vib, String? customPath) async {
    if (!_isMobile) return 'cal_silent';
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (impl == null) return 'cal_silent';

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
    if (!_isMobile) return;
    await _plugin.cancel(id);
  }

  static Future<void> showTestNotification(
      AppSettings settings, AlarmMode testMode) async {
    if (!_isMobile) return;
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
    if (!_isMobile) return;
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
