// ignore_for_file: curly_braces_in_flow_control_structures
// v3.6.2
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../logic/date_formatter.dart';
import '../logic/slot_calculator.dart';
import '../logic/holidays.dart';

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
  late CalendarTheme _th;
  DateTime _windowCenter = DateTime.now();
  List<CalendarEvent> _allEvents = [];
  Map<String, List<CalendarEvent>> _eventsByDate = {};
  Map<int, int> _slotMap = {};
  List<CalendarEvent> _selectedEvents = [];
  final Map<String, String> _lunarCache = {};
  late final PageController _pageController;
  double _cachedArrowRowHeight = 56.0;

  int get _currentPage =>
      (_focusedDay.year - 2020) * 12 + (_focusedDay.month - 1);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _pageController = PageController(initialPage: _currentPage);
    _th = _appSettings.currentTheme.themeData;
    _initialLoad();
    _loadAppSettings();
    NotificationService.requestPermissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAppSettings() async {
    final s = await AppSettingsStorage.load();
    if (mounted) {
      setState(() {
        _appSettings = s;
        _th = s.currentTheme.themeData;
      });
    }
  }

  Future<void> _initialLoad() async {
    final all = await EventStorage.loadAll();
    _rebuildIndex(all, firstLoad: true);
  }

  void _rebuildIndex(List<CalendarEvent> all, {bool firstLoad = false}) {
    final minDate = DateTime(_windowCenter.year, _windowCenter.month - 12, 1);
    final maxDate = DateTime(_windowCenter.year, _windowCenter.month + 13, 0);

    final holidays = _appSettings.showHolidays
        ? HolidayUtil.generateHolidaysForWindow(minDate, maxDate)
        : null;

    final result = SlotCalculator.calculate(
        all, _windowCenter, _slotMap, firstLoad, holidays);
    final selKey = DateFormatter.dateKey(_selectedDay ?? _focusedDay);

    if (mounted) {
      setState(() {
        _allEvents = all;
        _eventsByDate = result.eventsByDate;
        _slotMap = result.slotMap;
        _selectedEvents = _eventsByDate[selKey] ?? [];
        if (firstLoad) {
          _isLoading = false;
        }

        if (_th.showTextInside) {
          int maxCnt = 0;
          final fd = DateTime(_focusedDay.year, _focusedDay.month, 1);
          final ld = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
          for (var d = fd; !d.isAfter(ld); d = d.add(const Duration(days: 1))) {
            final cnt = (_eventsByDate[DateFormatter.dateKey(d)] ?? []).length;
            if (cnt > maxCnt) {
              maxCnt = cnt;
            }
          }
          _cachedArrowRowHeight = math.max(22.0 + maxCnt * 20.0 + 10.0, 56.0);
        } else {
          _cachedArrowRowHeight = 56.0;
        }
      });
    }
  }

  void _checkAndUpdateViewport(DateTime newFocusedDay) {
    final diffMonths = (newFocusedDay.year * 12 + newFocusedDay.month) -
        (_windowCenter.year * 12 + _windowCenter.month);
    if (diffMonths.abs() >= 6) {
      _windowCenter = newFocusedDay;
      _rebuildIndex(_allEvents);
    }
  }

  void _jumpToDate(DateTime targetDate) {
    _windowCenter = targetDate;
    _focusedDay = targetDate;
    _selectedDay = targetDate;
    final targetPage = (targetDate.year - 2020) * 12 + (targetDate.month - 1);
    if (_appSettings.calendarNavMode != CalendarNavMode.arrow &&
        _pageController.hasClients) {
      _pageController.animateToPage(targetPage,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
    _rebuildIndex(_allEvents);
  }

  Future<void> _rescheduleAllAlarms() async {
    for (final e in _allEvents) {
      if (e.isHoliday) continue;
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

  Future<void> _toggleAlarm(CalendarEvent event) async {
    if (event.isHoliday) return;
    if (_appSettings.globalSilentMode) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('무음모드 상태입니다. 먼저 무음모드를 해제해주세요.'),
            duration: Duration(seconds: 2)));
      }
      return;
    }
    final idx = _allEvents.indexWhere((e) => e.id == event.id);
    if (idx == -1) return;
    final updated =
        _allEvents[idx].copyWith(isAlarmOn: !_allEvents[idx].isAlarmOn);
    _allEvents[idx] = updated;
    await EventStorage.saveAll(_allEvents);
    if (updated.isAlarmOn) {
      await NotificationService.scheduleEventAlarm(
          event: updated, settings: _appSettings);
    } else {
      await NotificationService.cancelAlarm(updated.id);
    }
    _rebuildIndex(_allEvents);
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _eventsByDate[DateFormatter.dateKey(day)] ?? [];
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
      _selectedEvents = _eventsByDate[DateFormatter.dateKey(selected)] ?? [];
    });
  }

  DateTime _pageToMonth(int page) {
    final year = 2020 + page ~/ 12;
    final month = page % 12 + 1;
    return DateTime(year, month);
  }

  String? _getCachedLunarLabel(DateTime d) {
    if (!_appSettings.showLunarCalendar) return null;
    final key = DateFormatter.dateKey(d);
    return _lunarCache.putIfAbsent(
        key,
        () =>
            DateFormatter.getLunarLabel(d, _appSettings.showLunarCalendar) ??
            '');
  }

  double _calcRowHeight(DateTime firstDayOfWeek) {
    int maxEvents = 0;
    for (int i = 0; i < 7; i++) {
      final d = firstDayOfWeek.add(Duration(days: i));
      final cnt = _getEventsForDay(d).length;
      if (cnt > maxEvents) {
        maxEvents = cnt;
      }
    }
    return math.max(22.0 + (maxEvents > 0 ? maxEvents * 20.0 : 0) + 8.0, 52.0);
  }

  Widget _buildCustomCell(DateTime day,
      {bool isToday = false,
      bool isSelected = false,
      bool isOutside = false,
      double? forcedHeight}) {
    final events = _getEventsForDay(day);
    final bool isHoliday = events.any((e) => e.isHoliday);

    Color textColor;
    if (isOutside) {
      textColor = _th.isDark ? Colors.white24 : Colors.grey[400]!;
    } else if (day.weekday == DateTime.sunday || isHoliday) {
      textColor = Colors.redAccent;
    } else if (day.weekday == DateTime.saturday) {
      textColor = Colors.blueAccent;
    } else {
      textColor = _th.isDark ? Colors.white : const Color(0xFF333333);
    }

    Color? todayRingColor;
    if (isToday && !isSelected && !isOutside) {
      if (day.weekday == DateTime.sunday || isHoliday) {
        todayRingColor = Colors.redAccent;
      } else if (day.weekday == DateTime.saturday) {
        todayRingColor = Colors.blueAccent;
      } else {
        todayRingColor = _th.isDark ? Colors.white70 : Colors.black87;
      }
    }
    if (isSelected) {
      textColor = Colors.white;
    }

    final lunarLabel = (!isOutside && day.weekday == DateTime.sunday)
        ? _getCachedLunarLabel(day)
        : null;
    Widget dateWidget = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
            color: isSelected ? _th.primaryAccent : null,
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

    Widget cellHeader = lunarLabel != null && lunarLabel.isNotEmpty
        ? Row(mainAxisSize: MainAxisSize.min, children: [
            dateWidget,
            const SizedBox(width: 6),
            Flexible(
                child: Text(lunarLabel,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 9.5,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal),
                    maxLines: 1,
                    overflow: TextOverflow.clip))
          ])
        : dateWidget;

    if (_th.showTextInside) {
      return Container(
          constraints: forcedHeight != null
              ? BoxConstraints(minHeight: forcedHeight)
              : const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.only(top: 3, left: 1, right: 1, bottom: 2),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                    padding: const EdgeInsets.only(left: 3, bottom: 1),
                    child: Align(
                        alignment: _th.cellTextAlignment, child: cellHeader)),
                if (events.isNotEmpty && !isOutside)
                  ..._buildEventBarsText(day, events)
              ]));
    } else {
      return Container(
          margin: const EdgeInsets.only(top: 2, bottom: 2),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Center(child: cellHeader)),
                if (events.isNotEmpty && !isOutside)
                  Padding(
                      padding: const EdgeInsets.only(top: 3, bottom: 2),
                      child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 2.5,
                          runSpacing: 2.5,
                          children: events.take(8).map((e) {
                            final color = e.colorValue != null
                                ? Color(e.colorValue!)
                                : _th.primaryAccent;
                            return Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle));
                          }).toList()))
              ]));
    }
  }

  List<Widget> _buildEventBarsText(DateTime day, List<CalendarEvent> events) {
    final dayKey = DateFormatter.dateKey(day);
    int maxSlot = -1;
    final slotMap = <int, CalendarEvent>{};
    for (final e in events) {
      final s = _slotMap[e.id] ?? 0;
      slotMap[s] = e;
      if (s > maxSlot) {
        maxSlot = s;
      }
    }

    final List<Widget> result = [];
    for (int slot = 0; slot <= maxSlot; slot++) {
      final e = slotMap[slot];
      if (e == null) {
        result.add(const SizedBox(height: 20.0));
        continue;
      }

      final color =
          e.colorValue != null ? Color(e.colorValue!) : _th.primaryAccent;
      final isFirst = dayKey == e.date;
      final isLast = dayKey == (e.endDate ?? e.date);

      bool showText = !e.isMultiDay || isFirst;
      if (e.isHoliday && (e.title == '설날' || e.title == '추석') && e.isMultiDay) {
        final actualDay =
            DateFormatter.dateKey(e.startDt.add(const Duration(days: 1)));
        showText = (dayKey == actualDay);
      }

      String label = '';
      if (showText) {
        label = (!e.isAllDay && e.startTime != null && isFirst)
            ? '${e.startTime} ${e.title}'
            : e.title;
      }

      result.add(Container(
          height: 18.0,
          margin: EdgeInsets.only(
              bottom: 2.0,
              left: isFirst ? 2.0 : 0.0,
              right: isLast ? 2.0 : 0.0),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(isFirst ? 3.0 : 0),
                  right: Radius.circular(isLast ? 3.0 : 0))),
          child: showText
              ? Row(children: [
                  if (!e.isMultiDay)
                    Container(
                        width: 3,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(3),
                                bottomLeft: Radius.circular(3)))),
                  const SizedBox(width: 3),
                  Expanded(
                      child: Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w600,
                              height: 1.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis))
                ])
              : const SizedBox.shrink()));
    }
    return result;
  }

  Widget _buildCalendarSection() {
    final calWidget = _appSettings.calendarNavMode == CalendarNavMode.arrow
        ? _buildArrowCalendar()
        : _buildSwipeCalendar();

    if (_th.hasRoundedCard) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
              decoration: BoxDecoration(
                  color: _th.calendarBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4))
                  ]),
              child: calWidget));
    } else {
      return Container(
          decoration: BoxDecoration(
              color: _th.calendarBg,
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]),
          child: calWidget);
    }
  }

  Widget _buildArrowCalendar() {
    final headerColor = _th.appBarText;
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            onPageChanged: (focused) {
              setState(() {
                _focusedDay = focused;
                _checkAndUpdateViewport(focused);
                if (_th.showTextInside) {
                  int maxCnt = 0;
                  final fd = DateTime(focused.year, focused.month, 1);
                  final ld = DateTime(focused.year, focused.month + 1, 0);
                  for (var d = fd;
                      !d.isAfter(ld);
                      d = d.add(const Duration(days: 1))) {
                    final cnt = _getEventsForDay(d).length;
                    if (cnt > maxCnt) {
                      maxCnt = cnt;
                    }
                  }
                  _cachedArrowRowHeight =
                      math.max(22.0 + maxCnt * 20.0 + 10.0, 56.0);
                }
              });
            },
            eventLoader: _getEventsForDay,
            rowHeight: _cachedArrowRowHeight,
            calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  const dows = ['일', '월', '화', '수', '목', '금', '토'];
                  Color c = headerColor.withValues(alpha: 0.6);
                  if (day.weekday == DateTime.sunday) {
                    c = Colors.redAccent;
                  } else if (day.weekday == DateTime.saturday) {
                    c = Colors.blueAccent;
                  }
                  return Center(
                      child: Text(dows[day.weekday % 7],
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
                titleTextFormatter: (d, _) =>
                    (_th.type == AppTheme.apple || _th.type == AppTheme.naver)
                        ? '${d.year}. ${d.month}'
                        : '${d.year}년 ${d.month}월',
                titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: headerColor),
                leftChevronIcon: Icon(Icons.chevron_left, color: headerColor),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: headerColor))));
  }

  Widget _buildSwipeCalendar() {
    final headerColor = _th.appBarText;
    const dows = ['일', '월', '화', '수', '목', '금', '토'];
    final scrollAxis =
        _appSettings.calendarNavMode == CalendarNavMode.swipeVertical
            ? Axis.vertical
            : Axis.horizontal;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(
                icon: Icon(Icons.chevron_left, color: headerColor),
                onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut)),
            GestureDetector(
                onTap: () => _jumpToDate(DateTime.now()),
                child: Text(
                    (_th.type == AppTheme.apple || _th.type == AppTheme.naver)
                        ? '${_focusedDay.year}. ${_focusedDay.month}'
                        : '${_focusedDay.year}년 ${_focusedDay.month}월',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: headerColor))),
            IconButton(
                icon: Icon(Icons.chevron_right, color: headerColor),
                onPressed: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut))
          ])),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
              children: List.generate(7, (i) {
            Color c = headerColor.withValues(alpha: 0.6);
            if (i == 0) {
              c = Colors.redAccent;
            } else if (i == 6) {
              c = Colors.blueAccent;
            }
            return Expanded(
                child: Center(
                    child: Text(dows[i],
                        style: TextStyle(
                            color: c,
                            fontSize: 12,
                            fontWeight: FontWeight.bold))));
          }))),
      const SizedBox(height: 4),
      SizedBox(
          height: _calcSwipeCalendarHeight(_focusedDay),
          child: PageView.builder(
              scrollDirection: scrollAxis,
              controller: _pageController,
              pageSnapping: true,
              onPageChanged: (page) {
                final month = _pageToMonth(page);
                setState(() {
                  _focusedDay = month;
                  _checkAndUpdateViewport(month);
                  final now = DateTime.now();
                  if (month.year == now.year && month.month == now.month) {
                    _selectedDay = now;
                  } else {
                    _selectedDay = month;
                  }
                  _selectedEvents =
                      _eventsByDate[DateFormatter.dateKey(_selectedDay!)] ?? [];
                });
              },
              itemBuilder: (context, page) =>
                  _buildMonthGrid(_pageToMonth(page))))
    ]);
  }

  double _calcSwipeCalendarHeight(DateTime monthDate) {
    final firstDay = DateTime(monthDate.year, monthDate.month, 1);
    final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0);
    final int startOffset = firstDay.weekday % 7;
    final totalCells = startOffset + lastDay.day;
    final weeks = (totalCells / 7).ceil();
    if (_th.showTextInside) {
      double totalH = 0;
      for (int w = 0; w < weeks; w++) {
        totalH += _calcRowHeight(
            firstDay.subtract(Duration(days: startOffset - w * 7)));
      }
      return totalH;
    }
    return weeks * 56.0;
  }

  Widget _buildMonthGrid(DateTime monthDate) {
    final firstDay = DateTime(monthDate.year, monthDate.month, 1);
    final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0);
    final int startOffset = firstDay.weekday % 7;
    final totalCells = startOffset + lastDay.day;
    final weeks = (totalCells / 7).ceil();
    final today = DateTime.now();

    return Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(weeks, (w) {
          final weekFirstDate =
              firstDay.subtract(Duration(days: startOffset - w * 7));
          final rowH =
              _th.showTextInside ? _calcRowHeight(weekFirstDate) : 56.0;
          return SizedBox(
              height: rowH,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(7, (d) {
                    final dayDate = firstDay
                        .subtract(Duration(days: startOffset - (w * 7 + d)));
                    return Expanded(
                        child: GestureDetector(
                            onTap: () => _onDaySelected(dayDate, monthDate),
                            child: _buildCustomCell(dayDate,
                                isToday: isSameDay(dayDate, today),
                                isSelected: isSameDay(dayDate, _selectedDay),
                                isOutside: dayDate.month != monthDate.month,
                                forcedHeight: rowH)));
                  })));
        }));
  }

  AppBar _buildAppBar() {
    return AppBar(
        backgroundColor: _th.appBarBg,
        elevation: 0,
        centerTitle: true,
        title: Text('My Calendar',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _th.appBarText,
                fontSize: 18)),
        leading: IconButton(
            onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor:
                    _th.isDark ? const Color(0xFF2A2640) : Colors.white,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24))),
                builder: (ctx) => _AppSettingsSheet(
                    initial: _appSettings,
                    isDark: _th.isDark,
                    accent: _th.primaryAccent,
                    allEvents: _allEvents.where((e) => !e.isHoliday).toList(),
                    onDataRestored: () {
                      _loadAppSettings();
                      _initialLoad();
                    },
                    onChanged: (updated) async {
                      setState(() {
                        _appSettings = updated;
                        _th = updated.currentTheme.themeData;
                        if (!updated.showLunarCalendar) {
                          _lunarCache.clear();
                        }
                      });
                      await AppSettingsStorage.save(updated);
                      _rebuildIndex(_allEvents);
                      await _rescheduleAllAlarms();
                    })),
            icon: Icon(Icons.settings_outlined, color: _th.appBarText),
            tooltip: '앱 설정'),
        actions: [
          IconButton(
              onPressed: () async {
                final selectedEvent = await showSearch<CalendarEvent?>(
                    context: context,
                    delegate: EventSearchDelegate(_allEvents, _th));
                if (selectedEvent != null) {
                  _jumpToDate(selectedEvent.startDt);
                }
              },
              icon: Icon(Icons.search, color: _th.appBarText),
              tooltip: '검색'),
          TextButton(
              onPressed: () => _jumpToDate(DateTime.now()),
              child: Text('오늘',
                  style: TextStyle(
                      color: _th.isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14))),
          IconButton(
              onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor:
                      _th.isDark ? const Color(0xFF2A2640) : Colors.white,
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (ctx) => SizedBox(
                      height: MediaQuery.of(ctx).size.height * 0.6,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                    child: Container(
                                        width: 40,
                                        height: 4,
                                        margin:
                                            const EdgeInsets.only(bottom: 20),
                                        decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(2)))),
                                Text('테마 선택',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _th.isDark
                                            ? Colors.white
                                            : const Color(0xFF1A1A2E))),
                                const SizedBox(height: 16),
                                Expanded(
                                    child: ListView(
                                        children: AppTheme.values.map((t) {
                                  final data = t.themeData;
                                  final isSel = _th.type == t;
                                  return GestureDetector(
                                      onTap: () async {
                                        final updated = _appSettings.copyWith(
                                            currentTheme: t);
                                        setState(() {
                                          _appSettings = updated;
                                          _th = updated.currentTheme.themeData;
                                        });
                                        await AppSettingsStorage.save(updated);
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                        }
                                      },
                                      child: Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 10),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                          decoration: BoxDecoration(
                                              color: isSel
                                                  ? data.primaryAccent
                                                      .withValues(alpha: 0.15)
                                                  : (_th.isDark
                                                      ? const Color(0xFF3D3760)
                                                      : const Color(
                                                          0xFFF5F5F5)),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: isSel
                                                  ? Border.all(
                                                      color: data.primaryAccent,
                                                      width: 2)
                                                  : null),
                                          child: Row(children: [
                                            Container(
                                                width: 16,
                                                height: 16,
                                                margin: const EdgeInsets.only(
                                                    right: 4),
                                                decoration: BoxDecoration(
                                                    color: data.scaffoldBg,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.3),
                                                        width: 1))),
                                            Container(
                                                width: 16,
                                                height: 16,
                                                margin: const EdgeInsets.only(
                                                    right: 4),
                                                decoration: BoxDecoration(
                                                    color: data.primaryAccent,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.3),
                                                        width: 1))),
                                            const SizedBox(width: 12),
                                            Text('${data.emoji}  ${data.name}',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: _th.isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF1A1A2E))),
                                            const Spacer(),
                                            if (isSel)
                                              Icon(Icons.check_circle,
                                                  color: data.primaryAccent,
                                                  size: 22)
                                          ])));
                                }).toList()))
                              ])))),
              icon: Icon(Icons.color_lens_outlined,
                  color: _th.appBarText, size: 28),
              tooltip: '테마 변경')
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return _th.buildScaffoldLayout(
        context: context,
        isLoading: _isLoading,
        appBar: _buildAppBar(),
        calendarSection: _buildCalendarSection(),
        sectionLabel: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              Text('일정 목록',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _th.sectionLabelText)),
              const Spacer(),
              Text('무음모드',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _th.isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(width: 8),
              Transform.scale(
                  scale: 0.75,
                  child: CupertinoSwitch(
                      activeTrackColor: Colors.grey.shade400,
                      value: _appSettings.globalSilentMode,
                      onChanged: (val) async {
                        final updated =
                            _appSettings.copyWith(globalSilentMode: val);
                        setState(() {
                          _appSettings = updated;
                          _th = updated.currentTheme.themeData;
                        });
                        await AppSettingsStorage.save(updated);
                        await _rescheduleAllAlarms();
                      }))
            ])),
        eventList: _selectedEvents.isEmpty
            ? Center(
                child: Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Text('이 날의 일정이 없어요',
                        style: TextStyle(
                            color: _th.sectionLabelText.withValues(alpha: 0.5),
                            fontSize: 16))))
            : ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _selectedEvents.length,
                itemBuilder: (_, i) => GestureDetector(
                    onTap: () {
                      if (!_selectedEvents[i].isHoliday) {
                        _showActionSheet(_selectedEvents[i]);
                      }
                    },
                    child: _th.buildEventListItem(
                        context: context,
                        event: _selectedEvents[i],
                        dateInfo:
                            DateFormatter.makeTimeString(_selectedEvents[i]),
                        isGlobalSilent: _appSettings.globalSilentMode,
                        onToggleAlarm: () => _toggleAlarm(_selectedEvents[i]),
                        formatHHmm: DateFormatter.formatHHmm))),
        floatingActionButton: FloatingActionButton(
            onPressed: () => _showEventDialog(),
            backgroundColor: _th.primaryAccent,
            foregroundColor: Colors.white,
            elevation: 4,
            child: const Icon(Icons.add, size: 28)),
        displayDay: _selectedDay ?? _focusedDay,
        formatDateKorean: DateFormatter.formatDateKorean);
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
        isEdit ? existingEvent.eventAlarmMode : _appSettings.effectiveMode);
    final soundN = ValueNotifier<NotificationSound>(
        isEdit ? existingEvent.soundOption : _appSettings.soundOption);
    final vibN = ValueNotifier<VibrationPattern>(isEdit
        ? existingEvent.vibrationPattern
        : _appSettings.vibrationPattern);
    final customPathN = ValueNotifier<String?>(
        isEdit ? existingEvent.customSoundPath : _appSettings.customSoundPath);

    showDialog(
        context: context,
        builder: (dlgCtx) => AlertDialog(
                backgroundColor:
                    _th.isDark ? const Color(0xFF2A2640) : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text(isEdit ? '✏️ 일정 수정' : '✨ 새 일정 추가',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _th.isDark ? Colors.white : Colors.black)),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: ctrl,
                      autofocus: true,
                      maxLength: 100,
                      style: TextStyle(
                          color: _th.isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                          hintText: '일정을 입력하세요',
                          hintStyle: TextStyle(
                              color: _th.isDark ? Colors.white38 : Colors.grey),
                          filled: true,
                          fillColor: _th.isDark
                              ? const Color(0xFF3D3760)
                              : Colors.grey[100],
                          counterStyle: TextStyle(
                              color: _th.isDark ? Colors.white38 : Colors.grey,
                              fontSize: 11),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none))),
                  const SizedBox(height: 16),
                  Container(
                      decoration: BoxDecoration(
                          color: _th.isDark
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
                                                  color: _th.isDark
                                                      ? Colors.white
                                                      : Colors.black87)),
                                          CupertinoSwitch(
                                              activeTrackColor:
                                                  _th.primaryAccent,
                                              value: isAllDay,
                                              onChanged: (v) =>
                                                  isAllDayN.value = v)
                                        ])),
                                Divider(
                                    height: 1,
                                    color: _th.isDark
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
                                    color: _th.isDark
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
                          color: _th.isDark
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
                                      color: _th.primaryAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Text('알림 시간',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: _th.isDark
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
                                                          ? _th.primaryAccent
                                                          : (_th.isDark
                                                              ? const Color(
                                                                  0xFF2A2640)
                                                              : Colors.white),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                          color: isSel
                                                              ? _th
                                                                  .primaryAccent
                                                              : (_th.isDark
                                                                  ? Colors
                                                                      .white24
                                                                  : Colors.grey
                                                                      .shade300))),
                                                  child: Text(opt.label,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: isSel ? Colors.white : (_th.isDark ? Colors.white70 : Colors.black87)))));
                                        }).toList()))),
                            ValueListenableBuilder<AlarmMinutes>(
                                valueListenable: alarmN,
                                builder: (_, alarm, __) {
                                  if (alarm == AlarmMinutes.none)
                                    return const SizedBox.shrink();
                                  return ValueListenableBuilder<AlarmMode>(
                                      valueListenable: alarmModeN,
                                      builder: (_, mode, __) {
                                        return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Divider(
                                                  height: 1,
                                                  color: _th.isDark
                                                      ? Colors.white12
                                                      : Colors.grey[300]),
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          16, 12, 16, 4),
                                                  child: Text('알림 방식',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                          color: _th.isDark
                                                              ? Colors.white54
                                                              : Colors
                                                                  .black54))),
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          16, 0, 16, 12),
                                                  child: Wrap(
                                                      spacing: 8,
                                                      runSpacing: 8,
                                                      children: AlarmMode.values
                                                          .map((opt) {
                                                        final isSel =
                                                            mode == opt;
                                                        return GestureDetector(
                                                            onTap: () =>
                                                                alarmModeN.value =
                                                                    opt,
                                                            child: Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            12,
                                                                        vertical:
                                                                            6),
                                                                decoration: BoxDecoration(
                                                                    color: isSel
                                                                        ? _th.primaryAccent.withValues(
                                                                            alpha:
                                                                                0.15)
                                                                        : Colors
                                                                            .transparent,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            20),
                                                                    border: Border.all(
                                                                        color: isSel
                                                                            ? _th.primaryAccent
                                                                            : (_th.isDark ? Colors.white24 : Colors.grey.shade400))),
                                                                child: Text(opt.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSel ? _th.primaryAccent : (_th.isDark ? Colors.white70 : Colors.black87)))));
                                                      }).toList())),
                                              if (mode == AlarmMode.soundOnly ||
                                                  mode ==
                                                      AlarmMode
                                                          .soundAndVibration) ...[
                                                Divider(
                                                    height: 1,
                                                    color: _th.isDark
                                                        ? Colors.white12
                                                        : Colors.grey[300]),
                                                Padding(
                                                    padding: const EdgeInsets
                                                        .fromLTRB(
                                                        16, 12, 16, 4),
                                                    child: Text('알림 소리',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13,
                                                            color: _th.isDark
                                                                ? Colors.white54
                                                                : Colors
                                                                    .black54))),
                                                SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    padding: const EdgeInsets
                                                        .fromLTRB(
                                                        16, 0, 16, 12),
                                                    child: ValueListenableBuilder<
                                                            NotificationSound>(
                                                        valueListenable: soundN,
                                                        builder: (_, snd, __) =>
                                                            Row(
                                                                children:
                                                                    NotificationSound
                                                                        .values
                                                                        .map(
                                                                            (opt) {
                                                              final isSel =
                                                                  snd == opt;
                                                              return GestureDetector(
                                                                  onTap: () {
                                                                    if (opt ==
                                                                        NotificationSound
                                                                            .custom) {
                                                                      FilePicker
                                                                          .platform
                                                                          .pickFiles(
                                                                              type: FileType.audio)
                                                                          .then((r) {
                                                                        if (r !=
                                                                            null) {
                                                                          customPathN.value = r
                                                                              .files
                                                                              .single
                                                                              .path;
                                                                          soundN.value =
                                                                              NotificationSound.custom;
                                                                        }
                                                                      });
                                                                    } else {
                                                                      soundN.value =
                                                                          opt;
                                                                    }
                                                                  },
                                                                  child: Container(
                                                                      margin: const EdgeInsets
                                                                          .only(
                                                                          right:
                                                                              8),
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              12,
                                                                          vertical:
                                                                              6),
                                                                      decoration: BoxDecoration(
                                                                          color: isSel
                                                                              ? _th.primaryAccent.withValues(alpha: 0.15)
                                                                              : Colors.transparent,
                                                                          borderRadius: BorderRadius.circular(20),
                                                                          border: Border.all(color: isSel ? _th.primaryAccent : (_th.isDark ? Colors.white24 : Colors.grey.shade400))),
                                                                      child: Text(opt == NotificationSound.custom && isSel && customPathN.value != null ? '🎵 ${customPathN.value!.split('/').last}' : opt.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSel ? _th.primaryAccent : (_th.isDark ? Colors.white70 : Colors.black87)))));
                                                            }).toList())))
                                              ],
                                              if (mode ==
                                                      AlarmMode.vibrationOnly ||
                                                  mode ==
                                                      AlarmMode
                                                          .soundAndVibration) ...[
                                                Divider(
                                                    height: 1,
                                                    color: _th.isDark
                                                        ? Colors.white12
                                                        : Colors.grey[300]),
                                                Padding(
                                                    padding: const EdgeInsets
                                                        .fromLTRB(
                                                        16, 12, 16, 4),
                                                    child: Text('진동 패턴',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13,
                                                            color: _th.isDark
                                                                ? Colors.white54
                                                                : Colors
                                                                    .black54))),
                                                SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    padding: const EdgeInsets
                                                        .fromLTRB(
                                                        16, 0, 16, 12),
                                                    child: ValueListenableBuilder<
                                                            VibrationPattern>(
                                                        valueListenable: vibN,
                                                        builder: (_, vib, __) =>
                                                            Row(
                                                                children:
                                                                    VibrationPattern
                                                                        .values
                                                                        .map(
                                                                            (opt) {
                                                              final isSel =
                                                                  vib == opt;
                                                              return GestureDetector(
                                                                  onTap: () =>
                                                                      vibN.value =
                                                                          opt,
                                                                  child: Container(
                                                                      margin: const EdgeInsets
                                                                          .only(
                                                                          right:
                                                                              8),
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              12,
                                                                          vertical:
                                                                              6),
                                                                      decoration: BoxDecoration(
                                                                          color: isSel
                                                                              ? _th.primaryAccent.withValues(alpha: 0.15)
                                                                              : Colors.transparent,
                                                                          borderRadius: BorderRadius.circular(20),
                                                                          border: Border.all(color: isSel ? _th.primaryAccent : (_th.isDark ? Colors.white24 : Colors.grey.shade400))),
                                                                      child: Text(opt.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSel ? _th.primaryAccent : (_th.isDark ? Colors.white70 : Colors.black87)))));
                                                            }).toList())))
                                              ]
                                            ]);
                                      });
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
                                  _th.isDark ? Colors.white54 : Colors.grey))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _th.primaryAccent,
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
                        final sDStr = DateFormatter.dateKey(sD);
                        final eDStr = DateFormatter.dateKey(eD);
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
                            soundOption: soundN.value,
                            vibrationPattern: vibN.value,
                            customSoundPath: customPathN.value,
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
                        if (newEvent.alarmDateTime != null &&
                            newEvent.isAlarmOn) {
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
      soundN.dispose();
      vibN.dispose();
      customPathN.dispose();
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
              ? DateFormatter.formatDateKorean(value)
              : DateFormatter.formatHHmm(
                  '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}');
          return InkWell(
              onTap: () async {
                DateTime temp = value;
                await showModalBottomSheet<void>(
                    context: parentCtx,
                    builder: (bsCtx) => Container(
                        color:
                            _th.isDark ? const Color(0xFF2A2640) : Colors.white,
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
                                            color: _th.isDark
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
                                                color: _th.primaryAccent,
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
                                              color: _th.isDark
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
                                color: _th.isDark
                                    ? Colors.white70
                                    : Colors.black87,
                                fontSize: 15)),
                        Text(displayText,
                            style: TextStyle(
                                color: _th.primaryAccent,
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
        backgroundColor: _th.bottomSheetBg ??
            (_th.isDark ? const Color(0xFF2A2640) : Colors.white),
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
                              color: _th.iconBg, shape: BoxShape.circle),
                          child: Icon(Icons.edit, color: _th.iconColor)),
                      title: Text('수정하기',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: (_th.isDark || _th.bottomSheetBg != null)
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

  Widget _buildColorPicker(ValueNotifier<int> colorNotifier) {
    final List<int> opts = [
      defaultEventColor,
      0xFFE57373,
      0xFF81C784,
      0xFFFFB74D,
      0xFFBA68C8
    ];
    return ValueListenableBuilder<int>(
        valueListenable: colorNotifier,
        builder: (_, int sel, __) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: opts.map((int v) {
              final bool isSel = sel == v;
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
                                  color: _th.isDark
                                      ? Colors.white
                                      : Colors.black54,
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
}

class EventSearchDelegate extends SearchDelegate<CalendarEvent?> {
  final List<CalendarEvent> allEvents;
  final CalendarTheme th;
  EventSearchDelegate(this.allEvents, this.th);
  @override
  String get searchFieldLabel => '일정 검색... (초성 가능)';
  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
          backgroundColor: th.appBarBg,
          iconTheme: IconThemeData(color: th.appBarText),
          titleTextStyle: TextStyle(color: th.appBarText, fontSize: 18)),
      scaffoldBackgroundColor: th.scaffoldBg,
      inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(color: th.appBarText.withValues(alpha: 0.5)),
          border: InputBorder.none));
  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
            icon: Icon(Icons.clear, color: th.appBarText),
            onPressed: () => query = '')
      ];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      icon: Icon(Icons.arrow_back, color: th.appBarText),
      onPressed: () => close(context, null));
  @override
  Widget buildResults(BuildContext context) => _buildList();
  @override
  Widget buildSuggestions(BuildContext context) => _buildList();
  Widget _buildList() {
    final cleanQuery = query.replaceAll(' ', '').toLowerCase();
    if (cleanQuery.isEmpty)
      return Center(
          child: Text('검색어를 입력하세요.',
              style: TextStyle(
                  color: th.sectionLabelText.withValues(alpha: 0.5),
                  fontSize: 16)));
    final queryChosung = DateFormatter.getChosung(cleanQuery);
    final results = allEvents.where((e) {
      final cleanTitle = e.title.replaceAll(' ', '').toLowerCase();
      final titleChosung = DateFormatter.getChosung(cleanTitle);
      return cleanTitle.contains(cleanQuery) ||
          titleChosung.contains(queryChosung);
    }).toList();
    if (results.isEmpty)
      return Center(
          child: Text('검색 결과가 없습니다.',
              style: TextStyle(
                  color: th.sectionLabelText.withValues(alpha: 0.5),
                  fontSize: 16)));
    return ListView.builder(
        itemCount: results.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, i) {
          final e = results[i];
          final color =
              e.colorValue != null ? Color(e.colorValue!) : th.primaryAccent;
          return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              title: Text(e.title,
                  style: TextStyle(
                      color: th.eventTitleText, fontWeight: FontWeight.bold)),
              subtitle: Text(e.date, style: TextStyle(color: th.eventSubText)),
              onTap: () => close(context, e));
        });
  }
}

class _AppSettingsSheet extends StatefulWidget {
  final AppSettings initial;
  final bool isDark;
  final Color accent;
  final List<CalendarEvent> allEvents;
  final VoidCallback onDataRestored;
  final ValueChanged<AppSettings> onChanged;
  const _AppSettingsSheet(
      {required this.initial,
      required this.isDark,
      required this.accent,
      required this.allEvents,
      required this.onDataRestored,
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
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48),
                        Text('⚙️ 앱 설정',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _textColor)),
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('완료',
                                style: TextStyle(
                                    color: widget.accent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)))
                      ]),
                  const SizedBox(height: 10),

                  Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text('💾 데이터 관리 (범용 규격)',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _subColor,
                              letterSpacing: 0.5))),
                  Row(children: [
                    Expanded(
                        child: ElevatedButton.icon(
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('ICS 내보내기',
                                style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _tileBg,
                                foregroundColor: _textColor,
                                elevation: 0),
                            onPressed: () async {
                              await IcsService.exportToIcs(widget.allEvents);
                            })),
                    const SizedBox(width: 8),
                    Expanded(
                        child: ElevatedButton.icon(
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('ICS 불러오기',
                                style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _tileBg,
                                foregroundColor: _textColor,
                                elevation: 0),
                            onPressed: () async {
                              final success = await IcsService.importFromIcs();
                              if (context.mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: const Text(
                                              'ICS 데이터가 성공적으로 병합되었습니다!'),
                                          backgroundColor: widget.accent));
                                  widget.onDataRestored();
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              '복구 실패: 취소했거나 올바른 ics 파일이 아닙니다.'),
                                          backgroundColor: Colors.red));
                                }
                              }
                            }))
                  ]),
                  const SizedBox(height: 16),

                  _sectionTitle('📅 달력 설정'),
                  // 💡 [수정] 자막을 기획 의도에 맞게 변경
                  _switchTile(
                      icon: Icons.calendar_today_outlined,
                      label: '음력 표시 (일요일)',
                      subtitle: '매주 일요일 양력 날짜 옆에 음력을 표시합니다',
                      value: _s.showLunarCalendar,
                      onChanged: (v) =>
                          _update(_s.copyWith(showLunarCalendar: v))),
                  _switchTile(
                      icon: Icons.flag_outlined,
                      label: '공휴일 표시',
                      subtitle: '한국의 주요 공휴일을 표시합니다',
                      value: _s.showHolidays,
                      onChanged: (v) => _update(_s.copyWith(showHolidays: v))),

                  const SizedBox(height: 12),
                  Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                          color: _tileBg,
                          borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(Icons.swap_vert,
                                      color: widget.accent, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text('달력 넘기기 방식',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                                color: _textColor)),
                                        Text('월 이동 방법을 선택합니다',
                                            style: TextStyle(
                                                fontSize: 12, color: _subColor))
                                      ]))
                                ]),
                                const SizedBox(height: 12),
                                Row(
                                    children:
                                        CalendarNavMode.values.map((mode) {
                                  final isSel = _s.calendarNavMode == mode;
                                  return Expanded(
                                      child: GestureDetector(
                                          onTap: () => _update(_s.copyWith(
                                              calendarNavMode: mode)),
                                          child: Container(
                                              margin: EdgeInsets.only(
                                                  right:
                                                      mode != CalendarNavMode.values.last
                                                          ? 8
                                                          : 0),
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 10),
                                              decoration: BoxDecoration(
                                                  color: isSel
                                                      ? widget.accent.withValues(
                                                          alpha: 0.15)
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                      color: isSel
                                                          ? widget.accent
                                                          : (widget.isDark
                                                              ? Colors.white24
                                                              : Colors.grey.shade300),
                                                      width: isSel ? 2 : 1)),
                                              child: Column(children: [
                                                Icon(
                                                    mode ==
                                                            CalendarNavMode
                                                                .arrow
                                                        ? Icons.chevron_right
                                                        : (mode ==
                                                                CalendarNavMode
                                                                    .swipeVertical
                                                            ? Icons.swap_vert
                                                            : Icons.swap_horiz),
                                                    color: isSel
                                                        ? widget.accent
                                                        : _subColor,
                                                    size: 22),
                                                const SizedBox(height: 4),
                                                Text(mode.label,
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isSel
                                                            ? widget.accent
                                                            : _subColor))
                                              ]))));
                                }).toList())
                              ]))),
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
                    _sectionTitle('새 일정 추가 시 알람 소리/진동 기본값'),
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
                    _switchTile(
                        icon: Icons.volume_off_outlined,
                        label: '무음모드',
                        subtitle: '켜면 모든 소리·진동 알림이 무음으로 차단됨',
                        value: _s.globalSilentMode,
                        onChanged: (v) =>
                            _update(_s.copyWith(globalSilentMode: v)),
                        activeColor: Colors.grey),
                    if (_s.soundEnabled) ...[
                      const SizedBox(height: 16),
                      _sectionTitle('기본 소리 설정'),
                      ...NotificationSound.values.map((s) {
                        if (s == NotificationSound.custom) {
                          final bool isCustomSel =
                              _s.soundOption == NotificationSound.custom;
                          return GestureDetector(
                              onTap: () {
                                FilePicker.platform
                                    .pickFiles(type: FileType.audio)
                                    .then((r) {
                                  if (r != null) {
                                    _update(_s.copyWith(
                                        soundOption: NotificationSound.custom,
                                        customSoundPath: r.files.single.path));
                                  }
                                });
                              },
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
                      _sectionTitle('기본 진동 패턴'),
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
                            label: const Text('현재 기본 설정으로 알림 테스트'),
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
