// v4.3.9
// lib/services/storage_service.dart
// [Web 호환성 패치] 모바일은 SecureStorage, 웹은 SharedPreferences 자동 분기

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

void appLog(String msg) {
  if (!kReleaseMode) debugPrint(msg);
}

String encodeEventsToJson(List<CalendarEvent> events) =>
    jsonEncode(events.map((e) => e.toJson()).toList());

List<CalendarEvent> decodeEventsFromJson(String raw) =>
    (jsonDecode(raw) as List)
        .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();

class StorageHelper {
  static const _ss = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true));

  static Future<String?> readData(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return await _ss.read(key: key);
    }
  }

  static Future<void> writeData(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _ss.write(key: key, value: value);
    }
  }
}

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
    final raw = await StorageHelper.readData(_key);
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
    await StorageHelper.writeData(_key, jsonEncode(s.toJson()));
  }

  static Future<bool> isFirstRun() async {
    final raw = await StorageHelper.readData(_key);
    return raw == null;
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

  static List<CalendarEvent>? _cachedEvents;

  static Future<List<CalendarEvent>> loadAll({bool refresh = false}) async {
    if (!refresh && _cachedEvents != null) {
      return _cachedEvents!;
    }
    final raw = await StorageHelper.readData(_key);
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
    _cachedEvents = toSave;
    final jsonString = await compute(encodeEventsToJson, toSave);
    await StorageHelper.writeData(_key, jsonString);
  }

  static final _rng = math.Random.secure();
  static int generateId() =>
      ((DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF) ^
          ((_rng.nextInt(0xFFFF) << 15) & 0x7FFFFFFF));
}
