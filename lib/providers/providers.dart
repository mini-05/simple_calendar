// v4.4.2
// providers.dart
// lib/providers/providers.dart
// [v4.4.2] Riverpod 3.x 마이그레이션 및 캡처 방지 로직 적용

import 'dart:math' as math;
import 'package:flutter/foundation.dart'
    show kIsWeb, compute, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_protector/screen_protector.dart'; // 💡 [신규 추가됨] 화면 캡처 방지 패키지
import '../models/models.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

List<CalendarEvent> _generateHolidaysIsolate(Map<String, dynamic> args) {
  final minDate = args['minDate'] as DateTime;
  final maxDate = args['maxDate'] as DateTime;
  return HolidayUtil.generateHolidaysForWindow(minDate, maxDate);
}

List<CalendarEvent> _expandRecurringIsolate(Map<String, dynamic> args) {
  final events = args['events'] as List<CalendarEvent>;
  final min = args['minDate'] as DateTime;
  final max = args['maxDate'] as DateTime;
  final result = <CalendarEvent>[];

  for (final e in events) {
    if (e.recurrenceRule == null) {
      result.add(e);
      continue;
    }
    final dates = e.recurrenceRule!.expand(e.startDt, from: min, to: max);
    for (final d in dates) {
      final dur = e.endDt.difference(e.startDt);
      final instEnd = d.add(dur);
      result.add(
        e.copyWith(
          date: _dateKey(d),
          endDate: _dateKey(instEnd),
          parentId: e.id,
          isRecurrenceInstance: true,
        ),
      );
    }
  }
  return result;
}

class CalendarState {
  final List<CalendarEvent> masterEvents;
  final Map<String, List<CalendarEvent>> eventsByDate;
  final Map<int, int> slotMap;
  final List<CalendarEvent> selectedEvents;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final AppSettings settings;
  final bool isLoading;
  final double cachedArrowRowHeight;
  final Set<String> holidayDates;

  const CalendarState({
    this.masterEvents = const [],
    this.eventsByDate = const {},
    this.slotMap = const {},
    this.selectedEvents = const [],
    required this.focusedDay,
    this.selectedDay,
    this.settings = const AppSettings(),
    this.isLoading = true,
    this.cachedArrowRowHeight = 56.0,
    this.holidayDates = const {},
  });

  CalendarState copyWith({
    List<CalendarEvent>? masterEvents,
    Map<String, List<CalendarEvent>>? eventsByDate,
    Map<int, int>? slotMap,
    List<CalendarEvent>? selectedEvents,
    DateTime? focusedDay,
    DateTime? selectedDay,
    AppSettings? settings,
    bool? isLoading,
    double? cachedArrowRowHeight,
    Set<String>? holidayDates,
  }) => CalendarState(
    masterEvents: masterEvents ?? this.masterEvents,
    eventsByDate: eventsByDate ?? this.eventsByDate,
    slotMap: slotMap ?? this.slotMap,
    selectedEvents: selectedEvents ?? this.selectedEvents,
    focusedDay: focusedDay ?? this.focusedDay,
    selectedDay: selectedDay ?? this.selectedDay,
    settings: settings ?? this.settings,
    isLoading: isLoading ?? this.isLoading,
    cachedArrowRowHeight: cachedArrowRowHeight ?? this.cachedArrowRowHeight,
    holidayDates: holidayDates ?? this.holidayDates,
  );
}

class CalendarNotifier extends Notifier<CalendarState> {
  DateTime _windowCenter = DateTime.now();

  @override
  CalendarState build() {
    _init();
    return CalendarState(focusedDay: DateTime.now());
  }

  Future<void> _init() async {
    final results = await Future.wait([
      AppSettingsStorage.load(),
      EventStorage.loadAll(),
    ]);

    AppSettings settings = results[0] as AppSettings;
    final events = results[1] as List<CalendarEvent>;

    final isFirstRun = await AppSettingsStorage.isFirstRun();
    if (isFirstRun) {
      final defaultTheme =
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
              ? AppTheme.apple
              : AppTheme.samsung;
      settings = settings.copyWith(currentTheme: defaultTheme);
      await AppSettingsStorage.save(settings);
    }

    state = state.copyWith(settings: settings);

    // 💡 [신규 추가됨] 앱 시작 시 캡처 방지 설정 적용
    if (!kIsWeb) {
      if (settings.preventCapture) {
        await ScreenProtector.preventScreenshotOn();
      } else {
        await ScreenProtector.preventScreenshotOff();
      }
    }

    await NotificationService.initNotifications();
    await _rebuildIndex(events, firstLoad: true);
  }

  Future<void> _rebuildIndex(
    List<CalendarEvent> master, {
    bool firstLoad = false,
  }) async {
    final minDate = DateTime(_windowCenter.year, _windowCenter.month - 12, 1);
    final maxDate = DateTime(_windowCenter.year, _windowCenter.month + 13, 0);

    final holidaysFuture = compute(_generateHolidaysIsolate, {
      'minDate': minDate,
      'maxDate': maxDate,
    });

    final expandFuture = compute(_expandRecurringIsolate, {
      'events': master,
      'minDate': minDate,
      'maxDate': maxDate,
    });

    final isolateResults = await Future.wait([holidaysFuture, expandFuture]);
    final allHolidays = isolateResults[0];
    final expanded = isolateResults[1];

    final holidayDates = <String>{};
    for (final h in allHolidays) {
      DateTime cur = h.startDt;
      while (!cur.isAfter(h.endDt)) {
        holidayDates.add(_dateKey(cur));
        cur = cur.add(const Duration(days: 1));
      }
    }

    final holidaysToDisplay =
        state.settings.showHolidays ? allHolidays : <CalendarEvent>[];

    final result = SlotCalculator.calculate(
      expanded,
      _windowCenter,
      state.slotMap,
      firstLoad,
      holidaysToDisplay.isEmpty ? null : holidaysToDisplay,
    );

    final selKey = _dateKey(state.selectedDay ?? state.focusedDay);
    final selEvents = result.eventsByDate[selKey] ?? <CalendarEvent>[];

    final rowHeight = _calcRowHeight(state.focusedDay, result.eventsByDate);

    state = state.copyWith(
      masterEvents: master,
      eventsByDate: result.eventsByDate,
      slotMap: result.slotMap,
      selectedEvents: selEvents,
      isLoading: false,
      cachedArrowRowHeight: rowHeight,
      holidayDates: holidayDates,
    );

    HomeWidgetService.updateTodayEvents(
      master,
      widgetTheme: state.settings.dynamicWidgetTheme,
    );
  }

  double _calcRowHeight(
    DateTime focused,
    Map<String, List<CalendarEvent>> byDate,
  ) {
    if (!state.settings.currentTheme.themeData.showTextInside) {
      return 56.0;
    }
    int maxCnt = 0;
    final fd = DateTime(focused.year, focused.month, 1);
    final ld = DateTime(focused.year, focused.month + 1, 0);
    for (var d = fd; !d.isAfter(ld); d = d.add(const Duration(days: 1))) {
      final cnt = (byDate[_dateKey(d)] ?? []).length;
      if (cnt > maxCnt) maxCnt = cnt;
    }
    return math.max(22.0 + maxCnt * 20.0 + 10.0, 56.0);
  }

  void _checkAndUpdateViewport(DateTime focused) {
    final diff =
        (focused.year * 12 + focused.month) -
        (_windowCenter.year * 12 + _windowCenter.month);
    if (diff.abs() >= 6) {
      _windowCenter = focused;
      _rebuildIndex(state.masterEvents);
    }
  }

  void selectDay(DateTime selected, DateTime focused) {
    final selEvents =
        state.eventsByDate[_dateKey(selected)] ?? <CalendarEvent>[];
    state = state.copyWith(
      selectedDay: selected,
      focusedDay: focused,
      selectedEvents: selEvents,
    );
  }

  void onArrowPageChanged(DateTime focused) {
    state = state.copyWith(focusedDay: focused);
    _checkAndUpdateViewport(focused);
    if (state.settings.currentTheme.themeData.showTextInside) {
      state = state.copyWith(
        cachedArrowRowHeight: _calcRowHeight(focused, state.eventsByDate),
      );
    }
  }

  void onSwipePageChanged(DateTime month) {
    final now = DateTime.now();
    final sel =
        (month.year == now.year && month.month == now.month) ? now : month;
    final selEvents = state.eventsByDate[_dateKey(sel)] ?? <CalendarEvent>[];
    state = state.copyWith(
      focusedDay: month,
      selectedDay: sel,
      selectedEvents: selEvents,
    );
    _checkAndUpdateViewport(month);
  }

  void jumpToDate(DateTime target) {
    _windowCenter = target;
    state = state.copyWith(
      focusedDay: target,
      selectedDay: target,
      selectedEvents: state.eventsByDate[_dateKey(target)] ?? <CalendarEvent>[],
    );
    _rebuildIndex(state.masterEvents);
  }

  Future<void> addEvent(CalendarEvent event) async {
    final updated = <CalendarEvent>[...state.masterEvents, event];
    await EventStorage.saveAll(updated);
    if (event.alarmDateTime != null && event.isAlarmOn) {
      await NotificationService.scheduleEventAlarm(
        event: event,
        settings: state.settings,
      );
    }
    await _rebuildIndex(updated);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await NotificationService.cancelAlarm(event.id);
    final idx = state.masterEvents.indexWhere((e) => e.id == event.id);
    final updated = <CalendarEvent>[...state.masterEvents];
    if (idx != -1) updated[idx] = event;
    await EventStorage.saveAll(updated);
    if (event.alarmDateTime != null && event.isAlarmOn) {
      await NotificationService.scheduleEventAlarm(
        event: event,
        settings: state.settings,
      );
    }
    await _rebuildIndex(updated);
  }

  Future<void> deleteEvent(int id) async {
    await NotificationService.cancelAlarm(id);
    final updated = state.masterEvents.where((e) => e.id != id).toList();
    await EventStorage.saveAll(updated);
    await _rebuildIndex(updated);
  }

  Future<void> moveEventToDate(CalendarEvent event, DateTime target) async {
    final dur = event.endDt.difference(event.startDt);
    final newStart = DateTime(
      target.year,
      target.month,
      target.day,
      event.startDt.hour,
      event.startDt.minute,
    );
    final newEnd = newStart.add(dur);
    final moved = event.copyWith(
      date: _dateKey(newStart),
      endDate: _dateKey(newEnd),
    );
    await updateEvent(moved);
  }

  Future<void> toggleAlarm(CalendarEvent event) async {
    if (event.isHoliday) return;
    final idx = state.masterEvents.indexWhere((e) => e.id == event.id);
    if (idx == -1) return;
    final toggled = state.masterEvents[idx].copyWith(
      isAlarmOn: !state.masterEvents[idx].isAlarmOn,
    );
    final updated = <CalendarEvent>[...state.masterEvents];
    updated[idx] = toggled;
    await EventStorage.saveAll(updated);
    if (toggled.isAlarmOn) {
      await NotificationService.scheduleEventAlarm(
        event: toggled,
        settings: state.settings,
      );
    } else {
      await NotificationService.cancelAlarm(toggled.id);
    }
    await _rebuildIndex(updated);
  }

  Future<void> toggleSilentMode(bool val) async {
    final updated = state.settings.copyWith(globalSilentMode: val);
    await updateSettings(updated);
  }

  Future<void> updateSettings(AppSettings settings) async {
    await AppSettingsStorage.save(settings);
    final prev = state.settings;
    state = state.copyWith(settings: settings);

    // 💡 [신규 추가됨] 설정 화면에서 토글 스위치를 바꿨을 때 즉시 적용
    if (!kIsWeb && prev.preventCapture != settings.preventCapture) {
      if (settings.preventCapture) {
        await ScreenProtector.preventScreenshotOn();
      } else {
        await ScreenProtector.preventScreenshotOff();
      }
    }

    final needsRebuild =
        prev.showHolidays != settings.showHolidays ||
        prev.currentTheme.themeData.showTextInside !=
            settings.currentTheme.themeData.showTextInside;

    if (needsRebuild) await _rebuildIndex(state.masterEvents);
    await _rescheduleAllAlarms();
  }

  Future<void> _rescheduleAllAlarms() async {
    for (final e in state.masterEvents) {
      if (e.isHoliday || e.isRecurrenceInstance || e.alarmDateTime == null) {
        continue;
      }
      if (e.alarmDateTime!.isAfter(DateTime.now())) {
        if (e.isAlarmOn) {
          await NotificationService.scheduleEventAlarm(
            event: e,
            settings: state.settings,
          );
        } else {
          await NotificationService.cancelAlarm(e.id);
        }
      }
    }
  }

  Future<void> exportIcs() async => IcsService.exportToIcs(state.masterEvents);

  Future<bool> importIcs() async {
    final ok = await IcsService.importFromIcs();
    if (ok) {
      final all = await EventStorage.loadAll();
      await _rebuildIndex(all, firstLoad: true);
    }
    return ok;
  }
}

final calendarProvider = NotifierProvider<CalendarNotifier, CalendarState>(
  CalendarNotifier.new,
);

final settingsProvider = Provider<AppSettings>(
  (ref) => ref.watch(calendarProvider).settings,
);

final selectedDayProvider = Provider<DateTime?>(
  (ref) => ref.watch(calendarProvider).selectedDay,
);

final selectedEventsProvider = Provider<List<CalendarEvent>>(
  (ref) => ref.watch(calendarProvider).selectedEvents,
);
