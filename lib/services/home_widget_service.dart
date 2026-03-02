// v4.3.9
// claude_home_widget_service.dart
// lib/services/home_widget_service.dart
// ignore_for_file: curly_braces_in_flow_control_structures
// [v4.3.9] 동적 인포그래픽 테마 4종 지원 및 Web 크래시 방지 패치
// - dart:io Platform 대신 foundation의 kIsWeb 및 defaultTargetPlatform 사용

import 'package:flutter/foundation.dart'; // 💡 kIsWeb, defaultTargetPlatform 사용
import 'package:home_widget/home_widget.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../app_config.dart';
import 'date_formatter.dart';

class HomeWidgetService {
  // ── ISO 8601 주차 계산 (월요일 시작) ──────────────────────────
  static int _isoWeek(DateTime d) {
    final startOfYear = DateTime(d.year, 1, 1);
    final dayOfYear = d.difference(startOfYear).inDays + 1;
    final weekNum = ((dayOfYear - d.weekday + 10) / 7).floor();
    if (weekNum < 1) {
      return _isoWeek(DateTime(d.year - 1, 12, 31));
    }
    return weekNum;
  }

  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static String _weekdayLabel(DateTime d) => _weekdays[d.weekday - 1];

  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC'
  ];
  static String _monthLabel(DateTime d) => _months[d.month - 1];

  static Future<void> updateTodayEvents(
    List<CalendarEvent> allEvents, {
    WidgetTheme widgetTheme = WidgetTheme.flip,
  }) async {
    // 💡 [Web 크래시 방지 패치] 웹이거나, 안드로이드/iOS가 아니면 즉시 종료
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      await HomeWidget.setAppGroupId(AppConfig.appGroupId);
      final today = DateTime.now();
      final todayKey = DateFormatter.dateKey(today);

      final todayEvents = allEvents
          .where((e) =>
              !e.isHoliday && !e.isRecurrenceInstance && e.date == todayKey)
          .toList();

      todayEvents.sort((a, b) {
        if (a.isAllDay && !b.isAllDay) return -1;
        if (!a.isAllDay && b.isAllDay) return 1;
        return (a.startTime ?? '00:00').compareTo(b.startTime ?? '00:00');
      });

      final summary = todayEvents.isEmpty
          ? '오늘 일정이 없습니다'
          : todayEvents.take(3).map((e) {
              final time = e.isAllDay ? '종일' : (e.startTime ?? '');
              return '$time ${e.title}'.trim();
            }).join('\n');

      final day = today.day.toString();
      final weekday = _weekdayLabel(today);
      final month = _monthLabel(today);
      final week = '${_isoWeek(today)}주차'; // 💡 N주차 포맷 통일

      final cfg = AppThemeExt.widgetConfig(widgetTheme);
      final accentHex = _colorToHex(cfg.accent);
      final bgHex = _colorToHex(cfg.bg);
      final textPrimaryHex = _colorToHex(cfg.textPrimary);
      final textSecondaryHex = _colorToHex(cfg.textSecondary);

      await HomeWidget.saveWidgetData<String>(
          'today_date', '${today.month}월 ${today.day}일');
      await HomeWidget.saveWidgetData<String>('today_events', summary);
      await HomeWidget.saveWidgetData<int>('event_count', todayEvents.length);

      await HomeWidget.saveWidgetData<String>('day', day);
      await HomeWidget.saveWidgetData<String>('weekday', weekday);
      await HomeWidget.saveWidgetData<String>('month', month);
      await HomeWidget.saveWidgetData<String>('week', week);

      await HomeWidget.saveWidgetData<String>('widget_theme', cfg.motionTag);
      await HomeWidget.saveWidgetData<String>('accent_color', accentHex);
      await HomeWidget.saveWidgetData<String>('bg_color', bgHex);
      await HomeWidget.saveWidgetData<String>('text_primary', textPrimaryHex);
      await HomeWidget.saveWidgetData<String>(
          'text_secondary', textSecondaryHex);

      await HomeWidget.updateWidget(
          name: AppConfig.androidWidgetProvider,
          iOSName: AppConfig.iosWidgetName);

      debugPrint(
          '[HomeWidget] $day $weekday $week / theme=${cfg.motionTag} / ${todayEvents.length}건');
    } catch (e) {
      debugPrint('[HomeWidget] 갱신 실패: $e');
    }
  }

  static String _colorToHex(dynamic color) {
    // ignore: deprecated_member_use
    final value = color.value as int;
    return '#${value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}
