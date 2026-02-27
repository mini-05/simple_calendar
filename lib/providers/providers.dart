// v4.1.0-fix1
// claude_providers.dart
// lib\providers\providers.dart
// ignore_for_file: curly_braces_in_flow_control_structures
// 수정: ⑥ updateSettings — showHolidays/showTextInside 변경 시에만 리빌드
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/slot_calculator.dart';
import '../services/holidays.dart';
import '../theme/app_theme.dart';

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
  }) =>
      CalendarState(
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

class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier() : super(CalendarState(focusedDay: DateTime.now())) {
    _init();
  }

  DateTime _windowCenter = DateTime.now();

  Future<void> _init() async {
    final settings = await AppSettingsStorage.load();
    final events = await EventStorage.loadAll();
    state = state.copyWith(settings: settings);
    _rebuildIndex(events, firstLoad: true);
  }

  void _rebuildIndex(List<CalendarEvent> master, {bool firstLoad = false}) {
    final minDate = DateTime(_windowCenter.year, _windowCenter.month - 12, 1);
    final maxDate = DateTime(_windowCenter.year, _windowCenter.month + 13, 0);

    final allHolidays = HolidayUtil.generateHolidaysForWindow(minDate, maxDate);
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
    final expanded = _expandRecurring(master, minDate, maxDate);

    final result = SlotCalculator.calculate(
        expanded,
        _windowCenter,
        state.slotMap,
        firstLoad,
        holidaysToDisplay.isEmpty ? null : holidaysToDisplay);

    final selKey = _dateKey(state.selectedDay ?? state.focusedDay);
    final selEvents = result.eventsByDate[selKey] ?? [];

    double rowHeight = 56.0;
    if (state.settings.currentTheme.themeData.showTextInside) {
      int maxCnt = 0;
      final fd = DateTime(state.focusedDay.year, state.focusedDay.month, 1);
      final ld = DateTime(state.focusedDay.year, state.focusedDay.month + 1, 0);
      for (var d = fd; !d.isAfter(ld); d = d.add(const Duration(days: 1))) {
        final cnt = (result.eventsByDate[_dateKey(d)] ?? []).length;
        if (cnt > maxCnt) maxCnt = cnt;
      }
      rowHeight = math.max(22.0 + maxCnt * 20.0 + 10.0, 56.0);
    }

    state = state.copyWith(
      masterEvents: master,
      eventsByDate: result.eventsByDate,
      slotMap: result.slotMap,
      selectedEvents: selEvents,
      isLoading: false,
      cachedArrowRowHeight: rowHeight,
      holidayDates: holidayDates,
    );
  }

  List<CalendarEvent> _expandRecurring(
      List<CalendarEvent> events, DateTime min, DateTime max) {
    final result = <CalendarEvent>[];
    for (final e in events) {
      if (e.recurrenceRule == null) {
        result.add(e);
        continue;
      }
      final dates = e.recurrenceRule!.expand(e.startDt, limit: 500);
      for (final d in dates) {
        if (d.isAfter(max)) break;
        if (d.isBefore(min)) continue;
        final dur = e.endDt.difference(e.startDt);
        final instEnd = d.add(dur);
        result.add(e.copyWith(
          date: _dateKey(d),
          endDate: _dateKey(instEnd),
          parentId: e.id,
          isRecurrenceInstance: true,
        ));
      }
    }
    return result;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _checkAndUpdateViewport(DateTime focused) {
    final diff = (focused.year * 12 + focused.month) -
        (_windowCenter.year * 12 + _windowCenter.month);
    if (diff.abs() >= 6) {
      _windowCenter = focused;
      _rebuildIndex(state.masterEvents);
    }
  }

  void selectDay(DateTime selected, DateTime focused) {
    final selEvents = state.eventsByDate[_dateKey(selected)] ?? [];
    state = state.copyWith(
        selectedDay: selected, focusedDay: focused, selectedEvents: selEvents);
  }

  void onArrowPageChanged(DateTime focused) {
    state = state.copyWith(focusedDay: focused);
    _checkAndUpdateViewport(focused);
    if (state.settings.currentTheme.themeData.showTextInside) {
      int maxCnt = 0;
      final fd = DateTime(focused.year, focused.month, 1);
      final ld = DateTime(focused.year, focused.month + 1, 0);
      for (var d = fd; !d.isAfter(ld); d = d.add(const Duration(days: 1))) {
        final cnt = (state.eventsByDate[_dateKey(d)] ?? []).length;
        if (cnt > maxCnt) maxCnt = cnt;
      }
      state = state.copyWith(
          cachedArrowRowHeight: math.max(22.0 + maxCnt * 20.0 + 10.0, 56.0));
    }
  }

  void onSwipePageChanged(DateTime month) {
    final now = DateTime.now();
    final sel =
        (month.year == now.year && month.month == now.month) ? now : month;
    final selEvents = state.eventsByDate[_dateKey(sel)] ?? [];
    state = state.copyWith(
        focusedDay: month, selectedDay: sel, selectedEvents: selEvents);
    _checkAndUpdateViewport(month);
  }

  void jumpToDate(DateTime target) {
    _windowCenter = target;
    state = state.copyWith(
        focusedDay: target,
        selectedDay: target,
        selectedEvents: state.eventsByDate[_dateKey(target)] ?? []);
    _rebuildIndex(state.masterEvents);
  }

  Future<void> addEvent(CalendarEvent event) async {
    final updated = [...state.masterEvents, event];
    await EventStorage.saveAll(updated);
    if (event.alarmDateTime != null && event.isAlarmOn) {
      await NotificationService.scheduleEventAlarm(
          event: event, settings: state.settings);
    }
    _rebuildIndex(updated);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await NotificationService.cancelAlarm(event.id);
    final idx = state.masterEvents.indexWhere((e) => e.id == event.id);
    final updated = [...state.masterEvents];
    if (idx != -1) updated[idx] = event;
    await EventStorage.saveAll(updated);
    if (event.alarmDateTime != null && event.isAlarmOn) {
      await NotificationService.scheduleEventAlarm(
          event: event, settings: state.settings);
    }
    _rebuildIndex(updated);
  }

  Future<void> deleteEvent(int id) async {
    await NotificationService.cancelAlarm(id);
    final updated = state.masterEvents.where((e) => e.id != id).toList();
    await EventStorage.saveAll(updated);
    _rebuildIndex(updated);
  }

  Future<void> moveEventToDate(CalendarEvent event, DateTime target) async {
    final dur = event.endDt.difference(event.startDt);
    final newStart = DateTime(target.year, target.month, target.day,
        event.startDt.hour, event.startDt.minute);
    final newEnd = newStart.add(dur);
    final moved =
        event.copyWith(date: _dateKey(newStart), endDate: _dateKey(newEnd));
    await updateEvent(moved);
  }

  Future<void> toggleAlarm(CalendarEvent event) async {
    if (event.isHoliday) return;
    final idx = state.masterEvents.indexWhere((e) => e.id == event.id);
    if (idx == -1) return;
    final toggled = state.masterEvents[idx]
        .copyWith(isAlarmOn: !state.masterEvents[idx].isAlarmOn);
    final updated = [...state.masterEvents];
    updated[idx] = toggled;
    await EventStorage.saveAll(updated);
    if (toggled.isAlarmOn) {
      await NotificationService.scheduleEventAlarm(
          event: toggled, settings: state.settings);
    } else {
      await NotificationService.cancelAlarm(toggled.id);
    }
    _rebuildIndex(updated);
  }

  Future<void> toggleSilentMode(bool val) async {
    final updated = state.settings.copyWith(globalSilentMode: val);
    await updateSettings(updated);
  }

  /// [fix⑥] 불필요한 _rebuildIndex 호출 방지
  /// 리빌드가 필요한 경우만 실행:
  ///   - showHolidays 변경: 공휴일 표시 On/Off → eventsByDate 재구성 필요
  ///   - showTextInside 변경 (테마 전환): rowHeight 재계산 필요
  /// 그 외(무음모드, 알람ON/OFF, 소리/진동 등)는 state 업데이트만으로 충분
  Future<void> updateSettings(AppSettings settings) async {
    await AppSettingsStorage.save(settings);
    final prev = state.settings;
    state = state.copyWith(settings: settings);

    final needsRebuild = prev.showHolidays != settings.showHolidays ||
        prev.currentTheme.themeData.showTextInside !=
            settings.currentTheme.themeData.showTextInside;

    if (needsRebuild) _rebuildIndex(state.masterEvents);
    await _rescheduleAllAlarms();
  }

  Future<void> _rescheduleAllAlarms() async {
    for (final e in state.masterEvents) {
      if (e.isHoliday || e.alarmDateTime == null) continue;
      if (e.alarmDateTime!.isAfter(DateTime.now())) {
        if (e.isAlarmOn) {
          await NotificationService.scheduleEventAlarm(
              event: e, settings: state.settings);
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
      _rebuildIndex(all, firstLoad: true);
    }
    return ok;
  }
}

final calendarProvider = StateNotifierProvider<CalendarNotifier, CalendarState>(
    (_) => CalendarNotifier());

final settingsProvider =
    Provider<AppSettings>((ref) => ref.watch(calendarProvider).settings);

final selectedDayProvider =
    Provider<DateTime?>((ref) => ref.watch(calendarProvider).selectedDay);

final selectedEventsProvider = Provider<List<CalendarEvent>>(
    (ref) => ref.watch(calendarProvider).selectedEvents);
