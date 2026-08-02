// v4.4.8
// providers.dart
// lib/providers/providers.dart
// [v4.4.2] Riverpod 3.x 마이그레이션 및 캡처 방지 로직 적용
// [v4.4.8] 효율/정리:
//   - 로컬 _dateKey 제거 → DateFormatter.dateKey로 일원화(포맷 정의가 갈리지 않도록).
//   - 아무도 읽지 않던 cachedArrowRowHeight/_calcRowHeight 제거.
//     (화살표 월 이동 시 state를 두 번 대입해 화면이 두 번 리빌드되던 원인)
//   - 공휴일 생성 아이솔레이트를 (minDate,maxDate) 기준으로 캐시 — 일정 추가/수정 등
//     창(window)이 그대로인 재빌드에서 동일 결과를 다시 계산하지 않는다.
//   - 반복 일정이 하나도 없으면 확장 아이솔레이트를 띄우지 않는다.

import 'package:flutter/foundation.dart'
    show kIsWeb, compute, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_protector/screen_protector.dart'; // 💡 [신규 추가됨] 화면 캡처 방지 패키지
import '../models/models.dart';
import '../services/services.dart';
import '../theme/app_theme.dart'; // themeData 확장 (updateSettings의 showTextInside 비교)

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
          date: DateFormatter.dateKey(d),
          endDate: DateFormatter.dateKey(instEnd),
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
    holidayDates: holidayDates ?? this.holidayDates,
  );
}

class CalendarNotifier extends Notifier<CalendarState> {
  DateTime _windowCenter = DateTime.now();

  // 공휴일 캐시 — 창(minDate,maxDate)이 바뀔 때만 갱신된다.
  List<CalendarEvent> _cachedHolidays = const [];
  Set<String> _cachedHolidayDates = const {};
  DateTime? _holidayCacheMin;
  DateTime? _holidayCacheMax;

  @override
  CalendarState build() {
    _init();
    return CalendarState(focusedDay: DateTime.now());
  }

  Future<void> _init() async {
    // 설정과 '최초 실행 여부'는 같은 키에서 나오므로 한 번만 읽는다.
    // 두 로드는 서로 독립적이라 먼저 나란히 시작해 두고 결과만 기다린다.
    final settingsFuture = AppSettingsStorage.loadWithFirstRun();
    final eventsFuture = EventStorage.loadAll();
    final loaded = await settingsFuture;
    final events = await eventsFuture;

    AppSettings settings = loaded.settings;

    if (loaded.isFirstRun) {
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

    // 공휴일은 (minDate, maxDate)만의 순수 함수이므로 창이 그대로면 재계산하지 않는다.
    // 일정 추가/수정/삭제·알람 토글·설정 변경 등 대부분의 재빌드는 창이 바뀌지 않아
    // 매번 아이솔레이트를 띄우고 동일한 결과를 다시 만들던 비용이 사라진다.
    final needHolidays =
        _holidayCacheMin != minDate || _holidayCacheMax != maxDate;

    final holidaysFuture = needHolidays
        ? compute(_generateHolidaysIsolate, {
            'minDate': minDate,
            'maxDate': maxDate,
          })
        : Future.value(_cachedHolidays);

    // 반복 일정이 하나도 없으면 확장 아이솔레이트는 단순 복사에 불과하다.
    // 아이솔레이트 기동 + 이벤트 목록 왕복 직렬화 비용만 남으므로 건너뛴다.
    final hasRecurrence = master.any((e) => e.recurrenceRule != null);
    final expandFuture = hasRecurrence
        ? compute(_expandRecurringIsolate, {
            'events': master,
            'minDate': minDate,
            'maxDate': maxDate,
          })
        : Future.value(master);

    final isolateResults = await Future.wait([holidaysFuture, expandFuture]);
    final allHolidays = isolateResults[0];
    final expanded = isolateResults[1];

    if (needHolidays) {
      final keys = <String>{};
      for (final h in allHolidays) {
        DateTime cur = h.startDt;
        while (!cur.isAfter(h.endDt)) {
          keys.add(DateFormatter.dateKey(cur));
          cur = cur.add(const Duration(days: 1));
        }
      }
      _cachedHolidays = allHolidays;
      _cachedHolidayDates = keys;
      _holidayCacheMin = minDate;
      _holidayCacheMax = maxDate;
    }
    final holidayDates = _cachedHolidayDates;

    final holidaysToDisplay =
        state.settings.showHolidays ? allHolidays : <CalendarEvent>[];

    final result = SlotCalculator.calculate(
      expanded,
      _windowCenter,
      state.slotMap,
      firstLoad,
      holidaysToDisplay,
    );

    final selKey = DateFormatter.dateKey(state.selectedDay ?? state.focusedDay);
    final selEvents = result.eventsByDate[selKey] ?? <CalendarEvent>[];

    state = state.copyWith(
      masterEvents: master,
      eventsByDate: result.eventsByDate,
      slotMap: result.slotMap,
      selectedEvents: selEvents,
      isLoading: false,
      holidayDates: holidayDates,
    );

    HomeWidgetService.updateTodayEvents(
      master,
      widgetTheme: state.settings.dynamicWidgetTheme,
    );
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
        state.eventsByDate[DateFormatter.dateKey(selected)] ?? <CalendarEvent>[];
    state = state.copyWith(
      selectedDay: selected,
      focusedDay: focused,
      selectedEvents: selEvents,
    );
  }

  void onArrowPageChanged(DateTime focused) {
    state = state.copyWith(focusedDay: focused);
    _checkAndUpdateViewport(focused);
  }

  void onSwipePageChanged(DateTime month) {
    final now = DateTime.now();
    final sel =
        (month.year == now.year && month.month == now.month) ? now : month;
    final selEvents = state.eventsByDate[DateFormatter.dateKey(sel)] ?? <CalendarEvent>[];
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
      selectedEvents: state.eventsByDate[DateFormatter.dateKey(target)] ?? <CalendarEvent>[],
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
      date: DateFormatter.dateKey(newStart),
      endDate: DateFormatter.dateKey(newEnd),
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
