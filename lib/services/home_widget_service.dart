// v4.3.6
// claude_home_widget_service.dart
// lib/services/home_widget_service.dart
// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:home_widget/home_widget.dart';
import '../models/models.dart';
import '../app_config.dart';
import 'date_formatter.dart';

class HomeWidgetService {
  static Future<void> updateTodayEvents(List<CalendarEvent> allEvents) async {
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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

      await HomeWidget.saveWidgetData<String>(
          'today_date', '${today.month}월 ${today.day}일');
      await HomeWidget.saveWidgetData<String>('today_events', summary);
      await HomeWidget.saveWidgetData<int>('event_count', todayEvents.length);
      await HomeWidget.updateWidget(
          name: AppConfig.androidWidgetProvider,
          iOSName: AppConfig.iosWidgetName);

      debugPrint('[HomeWidget] 오늘 일정 ${todayEvents.length}개 갱신: $summary');
    } catch (e) {
      debugPrint('[HomeWidget] 갱신 실패: $e');
    }
  }
}
