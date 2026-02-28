// v4.3.7
// gemini_calendar_screen.dart
// lib/ui/calendar_screen.dart
// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../services/date_formatter.dart';
import '../theme/app_theme.dart';
import 'widgets/calendar_tile.dart';
import 'widgets/theme_dialog.dart';
import 'dialogs/event_editor.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final PageController _pageCtrl;

  bool _isPanelOpen = false;
  double _panelHeight = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _panelHeight = MediaQuery.of(context).size.height * 0.65;
  }

  static int _monthToPage(DateTime d) => (d.year - 2020) * 12 + (d.month - 1);
  static DateTime _pageToMonth(int page) =>
      DateTime(2020 + page ~/ 12, page % 12 + 1);

  @override
  void initState() {
    super.initState();
    final focused = ref.read(calendarProvider).focusedDay;
    _pageCtrl = PageController(initialPage: _monthToPage(focused));
    NotificationService.requestPermissions();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime sel, DateTime foc, CalendarNotifier notifier) {
    notifier.selectDay(sel, foc);
    setState(() {
      _isPanelOpen = true;
    });
  }

  void _showMonthPicker(
      BuildContext context, CalendarState st, CalendarNotifier notifier) {
    DateTime tempDate = st.focusedDay;
    final th = st.settings.currentTheme.themeData;

    showModalBottomSheet(
      context: context,
      backgroundColor: th.bottomSheetBg ??
          (th.isDark ? const Color(0xFF2A2640) : Colors.white),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                      child: Text('취소',
                          style: TextStyle(
                              color:
                                  th.isDark ? Colors.white54 : Colors.black54,
                              fontSize: 16)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        notifier.jumpToDate(tempDate);

                        // 💡 [수정] 월 선택 시 PageController도 해당 월로 강제 동기화
                        if (st.settings.calendarNavMode !=
                                CalendarNavMode.arrow &&
                            _pageCtrl.hasClients) {
                          _pageCtrl.jumpToPage(_monthToPage(tempDate));
                        }

                        setState(() {
                          _isPanelOpen = false;
                        });
                      },
                      child: Text('완료',
                          style: TextStyle(
                              color: th.primaryAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: th.isDark ? Brightness.dark : Brightness.light,
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.monthYear,
                    initialDateTime: st.focusedDay,
                    minimumDate: DateTime(2020, 1, 1),
                    maximumDate: DateTime(2030, 12, 31),
                    onDateTimeChanged: (DateTime newDate) {
                      tempDate = newDate;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);
    final th = st.settings.currentTheme.themeData;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: th.scaffoldBg,
      drawer: _buildDrawer(st, notifier, th),
      appBar: _buildAppBar(st, notifier, th),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showEventEditor(context, st, notifier);
        },
        backgroundColor: th.primaryAccent,
        foregroundColor: Colors.white,
        elevation: _isPanelOpen ? 8 : 4,
        child: const Icon(Icons.add, size: 28),
      ),
      body: st.isLoading
          ? Center(child: CircularProgressIndicator(color: th.primaryAccent))
          : Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onVerticalDragEnd: (details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v < -300) {
                        setState(() {
                          _isPanelOpen = true;
                        });
                      }
                      if (v > 300) {
                        setState(() {
                          _isPanelOpen = false;
                        });
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCalendarSection(st, notifier, th),
                          ]),
                    ),
                  ),
                ),
                if (!_isPanelOpen)
                  Positioned(
                    bottom: 25,
                    left: 0,
                    right: 0,
                    child:
                        IgnorePointer(child: _SwipeHint(color: th.appBarText)),
                  ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  bottom: _isPanelOpen ? 0 : -_panelHeight,
                  left: 0,
                  right: 0,
                  height: _panelHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: th.bottomSheetBg ??
                          (th.isDark ? const Color(0xFF2A2640) : Colors.white),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.26),
                            blurRadius: 20,
                            offset: const Offset(0, -4))
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onVerticalDragEnd: (details) {
                            if ((details.primaryVelocity ?? 0) > 200) {
                              setState(() {
                                _isPanelOpen = false;
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            color: Colors.transparent,
                            padding: const EdgeInsets.only(top: 14, bottom: 6),
                            child: Center(
                              child: Container(
                                width: 42,
                                height: 5,
                                decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(3)),
                              ),
                            ),
                          ),
                        ),
                        _buildSectionLabel(context, st, notifier, th),
                        Expanded(
                            child: _buildEventList(context, st, notifier, th)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDrawer(
      CalendarState st, CalendarNotifier notifier, CalendarTheme th) {
    final textStyle = TextStyle(
        color: th.isDark ? Colors.white : Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w500);
    final iconColor = th.isDark ? Colors.white70 : Colors.black54;

    return Drawer(
      backgroundColor: th.isDark ? const Color(0xFF1E1B2E) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: th.isDark ? Colors.white12 : Colors.black12))),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: th.primaryAccent,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.calendar_month,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text('My Calendar',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: th.isDark ? Colors.white : Colors.black)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(Icons.palette_outlined, color: iconColor),
                    title: Text('테마', style: textStyle),
                    onTap: () {
                      Navigator.pop(context);
                      showThemeDialog(
                          context: context,
                          th: th,
                          settings: st.settings,
                          onSelect: (t) async {
                            await notifier.updateSettings(
                                st.settings.copyWith(currentTheme: t));
                          });
                    },
                  ),
                  Divider(
                      color: th.isDark ? Colors.white12 : Colors.black12,
                      height: 1),
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Icon(Icons.sync_alt_outlined, color: iconColor),
                      title: Text('백업 / 복원', style: textStyle),
                      iconColor: th.primaryAccent,
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 54),
                          title: Text('ICS 내보내기',
                              style: textStyle.copyWith(
                                  fontSize: 14,
                                  color: th.isDark
                                      ? Colors.white70
                                      : Colors.black54)),
                          onTap: () {
                            Navigator.pop(context);
                            notifier.exportIcs();
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 54),
                          title: Text('ICS 불러오기',
                              style: textStyle.copyWith(
                                  fontSize: 14,
                                  color: th.isDark
                                      ? Colors.white70
                                      : Colors.black54)),
                          onTap: () async {
                            Navigator.pop(context);
                            final ok = await notifier.importIcs();
                            if (!mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok
                                  ? 'ICS 데이터가 성공적으로 병합되었습니다!'
                                  : '복구 실패: 취소했거나 올바른 ics 파일이 아닙니다.'),
                              backgroundColor:
                                  ok ? th.primaryAccent : Colors.red,
                            ));
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(
                      color: th.isDark ? Colors.white12 : Colors.black12,
                      height: 1),
                  ListTile(
                    leading: Icon(Icons.settings_outlined, color: iconColor),
                    title: Text('설정', style: textStyle),
                    onTap: () {
                      Navigator.pop(context);
                      _showSettingsSheet(context, st, notifier, th);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      CalendarState st, CalendarNotifier notifier, CalendarTheme th) {
    const monthNames = [
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
    final today = DateTime.now();
    final isArrow = st.settings.calendarNavMode == CalendarNavMode.arrow;
    final focused = st.focusedDay;

    final dateTextStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.3,
      color: th.appBarText,
    );

    // 💡 [수정] 모드와 상관없이 항상 "YYYY년 M월" 형태로 통합 표시
    final Widget titleWidget = GestureDetector(
      onTap: () => _showMonthPicker(context, st, notifier),
      child: Text('${focused.year}년 ${focused.month}월', style: dateTextStyle),
    );

    final Widget todayBtn = Padding(
      padding: const EdgeInsets.only(right: 14, left: 4),
      child: GestureDetector(
        onTap: () {
          final now = DateTime.now();
          notifier.jumpToDate(now);

          // 💡 [수정] '오늘' 버튼 클릭 시 PageController 실제 캘린더 화면도 동기화
          if (!isArrow && _pageCtrl.hasClients) {
            _pageCtrl.jumpToPage(_monthToPage(now));
          }

          setState(() {
            _isPanelOpen = false;
          });
        },
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                border: Border.all(color: th.appBarText, width: 1.8),
                borderRadius: BorderRadius.circular(10)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(monthNames[today.month - 1],
                    style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        color: th.appBarText,
                        letterSpacing: 0.5)),
                Text('${today.day}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        color: th.appBarText)),
              ],
            ),
          ),
        ),
      ),
    );

    return AppBar(
      backgroundColor: th.scaffoldBg,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu_rounded, color: th.appBarText, size: 28),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      title: titleWidget,
      titleSpacing: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: th.appBarText, size: 26),
          onPressed: () async {
            final e = await showSearch<CalendarEvent?>(
                context: context,
                delegate: _EventSearchDelegate(
                    st.masterEvents.where((e) => !e.isHoliday).toList(), th));
            if (e != null) {
              notifier.jumpToDate(e.startDt);

              if (st.settings.calendarNavMode != CalendarNavMode.arrow &&
                  _pageCtrl.hasClients) {
                _pageCtrl.jumpToPage(_monthToPage(e.startDt));
              }

              setState(() {
                _isPanelOpen = true;
              });
            }
          },
        ),
        todayBtn,
      ],
    );
  }

  Widget _buildCalendarSection(
      CalendarState st, CalendarNotifier notifier, CalendarTheme th) {
    final mode = st.settings.calendarNavMode;
    final isArrow = mode == CalendarNavMode.arrow;
    final calWidget = isArrow
        ? _buildArrowCalendar(st, notifier, th)
        : _buildSwipeCalendar(st, notifier, th);

    // 💡 [수정] 화살표 모드에서도 상단 AppBar에 년월이 표시되므로, 별도의 월 표시 헤더를 완전히 제거
    if (th.hasRoundedCard) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
              decoration: BoxDecoration(
                  color: th.calendarBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4))
                  ]),
              child: calWidget),
        ),
      );
    }

    return Expanded(
      child: Container(
          decoration: BoxDecoration(
              color: th.calendarBg,
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]),
          child: calWidget),
    );
  }

  Widget _buildArrowCalendar(
      CalendarState st, CalendarNotifier notifier, CalendarTheme th) {
    final hc = th.appBarText;
    const dows = ['일', '월', '화', '수', '목', '금', '토'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TableCalendar<CalendarEvent>(
        shouldFillViewport: true,
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: st.focusedDay,
        selectedDayPredicate: (d) => isSameDay(st.selectedDay, d),
        onDaySelected: (sel, foc) => _onDaySelected(sel, foc, notifier),
        onPageChanged: (focused) => notifier.onArrowPageChanged(focused),
        eventLoader: (d) => st.eventsByDate[DateFormatter.dateKey(d)] ?? [],
        calendarBuilders: CalendarBuilders(
          dowBuilder: (_, day) {
            Color c = hc.withValues(alpha: 0.6);
            if (day.weekday == DateTime.sunday) {
              c = Colors.redAccent;
            }
            if (day.weekday == DateTime.saturday) {
              c = Colors.blueAccent;
            }
            return Center(
                child: Text(dows[day.weekday % 7],
                    style: TextStyle(
                        color: c, fontSize: 12, fontWeight: FontWeight.bold)));
          },
          defaultBuilder: (_, d, __) => _tile(d, st, th),
          todayBuilder: (_, d, __) => _tile(d, st, th, isToday: true),
          selectedBuilder: (_, d, __) => _tile(d, st, th, isSelected: true),
          outsideBuilder: (_, d, __) => _tile(d, st, th, isOutside: true),
          markerBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextFormatter: (d, _) => '',
            titleTextStyle: const TextStyle(fontSize: 0),
            leftChevronIcon: Icon(Icons.chevron_left, color: hc),
            rightChevronIcon: Icon(Icons.chevron_right, color: hc)),
        onHeaderTapped: (date) {
          _showMonthPicker(context, st, notifier);
        },
      ),
    );
  }

  Widget _buildSwipeCalendar(
      CalendarState st, CalendarNotifier notifier, CalendarTheme th) {
    final hc = th.appBarText;
    const dows = ['일', '월', '화', '수', '목', '금', '토'];
    final axis = st.settings.calendarNavMode == CalendarNavMode.swipeVertical
        ? Axis.vertical
        : Axis.horizontal;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
            children: List.generate(7, (i) {
          Color c = hc.withValues(alpha: 0.6);
          if (i == 0) {
            c = Colors.redAccent;
          }
          if (i == 6) {
            c = Colors.blueAccent;
          }
          return Expanded(
              child: Center(
                  child: Text(dows[i],
                      style: TextStyle(
                          color: c,
                          fontSize: 12,
                          fontWeight: FontWeight.bold))));
        })),
      ),
      Expanded(
        child: PageView.builder(
          scrollDirection: axis,
          controller: _pageCtrl,
          pageSnapping: true,
          onPageChanged: (page) {
            notifier.onSwipePageChanged(_pageToMonth(page));
          },
          itemBuilder: (_, page) =>
              _buildMonthGrid(_pageToMonth(page), st, notifier, th),
        ),
      ),
    ]);
  }

  Widget _buildMonthGrid(DateTime month, CalendarState st,
      CalendarNotifier notifier, CalendarTheme th) {
    final first = DateTime(month.year, month.month, 1);
    final offset = first.weekday % 7;
    final weeks =
        ((offset + DateTime(month.year, month.month + 1, 0).day) / 7).ceil();
    final today = DateTime.now();

    return Column(
      children: List.generate(weeks, (w) {
        return Expanded(
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(7, (d) {
                final date =
                    first.subtract(Duration(days: offset - (w * 7 + d)));
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _onDaySelected(date, month, notifier);
                    },
                    child: _tile(date, st, th,
                        isToday: isSameDay(date, today),
                        isSelected: isSameDay(date, st.selectedDay),
                        isOutside: date.month != month.month),
                  ),
                );
              })),
        );
      }),
    );
  }

  Widget _tile(DateTime day, CalendarState st, CalendarTheme th,
      {bool isToday = false, bool isSelected = false, bool isOutside = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 360;

    String? customLunarText;

    if (!isOutside && st.settings.showLunarCalendar) {
      customLunarText = DateFormatter.getLunarLabel(day, true);
      if (isSmallScreen &&
          customLunarText != null &&
          customLunarText.startsWith('음')) {
        customLunarText = customLunarText.substring(1);
      }
    }

    return Stack(
      children: [
        CalendarTile(
            day: day,
            th: th,
            eventsByDate: st.eventsByDate,
            slotMap: st.slotMap,
            isToday: isToday,
            isSelected: isSelected,
            isOutside: isOutside,
            isHoliday: st.holidayDates.contains(DateFormatter.dateKey(day)),
            showLunar: false),
        if (customLunarText != null)
          Positioned(
            right: 4.0,
            top: 4.0,
            child: Text(
              customLunarText,
              style: TextStyle(
                fontSize: 9.0,
                color: th.isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, CalendarState st,
      CalendarNotifier notifier, CalendarTheme th) {
    final displayDay = st.selectedDay ?? st.focusedDay;
    final isToday = isSameDay(displayDay, DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 20, 12),
      child: Row(children: [
        Text(isToday ? 'Today' : DateFormatter.formatDateKorean(displayDay),
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: th.sectionLabelText)),
        const Spacer(),
        Text('무음모드',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: th.isDark ? Colors.white70 : Colors.black54)),
        const SizedBox(width: 8),
        Transform.scale(
            scale: 0.75,
            child: CupertinoSwitch(
                activeTrackColor: th.primaryAccent,
                value: st.settings.globalSilentMode,
                onChanged: (val) async {
                  await notifier.updateSettings(
                      st.settings.copyWith(globalSilentMode: val));
                })),
      ]),
    );
  }

  Widget _buildEventList(BuildContext context, CalendarState st,
      CalendarNotifier notifier, CalendarTheme th) {
    if (st.selectedEvents.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Text('이 날의 일정이 없어요',
                  style: TextStyle(
                      color: th.sectionLabelText.withValues(alpha: 0.5),
                      fontSize: 16))));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      itemCount: st.selectedEvents.length,
      cacheExtent: 500,
      itemBuilder: (_, i) {
        final event = st.selectedEvents[i];
        return GestureDetector(
          onTap: () {
            if (!event.isHoliday) {
              _showActionSheet(context, event, st, notifier, th);
            }
          },
          child: th.buildEventListItem(
              context: context,
              event: event,
              dateInfo: DateFormatter.makeTimeString(event),
              isGlobalSilent: st.settings.globalSilentMode,
              onToggleAlarm: () {
                notifier.toggleAlarm(event);
              },
              formatHHmm: DateFormatter.formatHHmm),
        );
      },
    );
  }

  void _showEventEditor(
      BuildContext context, CalendarState st, CalendarNotifier notifier,
      {CalendarEvent? existingEvent}) {
    showEventEditor(
        context: context,
        th: st.settings.currentTheme.themeData,
        settings: st.settings,
        currentEventCount: st.masterEvents.length,
        existingEvent: existingEvent,
        selectedDay: st.selectedDay ?? st.focusedDay,
        onSave: (e) async {
          if (existingEvent == null) {
            await notifier.addEvent(e);
          } else {
            await notifier.updateEvent(e);
          }
        });
  }

  void _showActionSheet(BuildContext context, CalendarEvent event,
      CalendarState st, CalendarNotifier notifier, CalendarTheme th) {
    showModalBottomSheet(
      context: context,
      backgroundColor: th.bottomSheetBg ??
          (th.isDark ? const Color(0xFF2A2640) : Colors.white),
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
                    decoration:
                        BoxDecoration(color: th.iconBg, shape: BoxShape.circle),
                    child: Icon(Icons.edit, color: th.iconColor)),
                title: Text('수정하기',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: (th.isDark || th.bottomSheetBg != null)
                            ? Colors.white
                            : Colors.black)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEventEditor(context, st, notifier, existingEvent: event);
                }),
            ListTile(
                leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.delete, color: Colors.redAccent)),
                title: const Text('삭제하기',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await notifier.deleteEvent(event.id);
                }),
          ]),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, CalendarState st,
      CalendarNotifier notifier, CalendarTheme th) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: th.isDark ? const Color(0xFF2A2640) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AppSettingsSheet(
          initial: st.settings,
          isDark: th.isDark,
          accent: th.primaryAccent,
          onChanged: (updated) {
            notifier.updateSettings(updated);
          }),
    );
  }
}

class _SwipeHint extends StatefulWidget {
  final Color color;
  const _SwipeHint({required this.color});
  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, -6 * _ctrl.value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.keyboard_arrow_up_rounded,
                color: widget.color.withValues(alpha: 0.7), size: 26),
            Transform.translate(
                offset: const Offset(0, -12),
                child: Icon(Icons.keyboard_arrow_up_rounded,
                    color: widget.color.withValues(alpha: 0.3), size: 26)),
          ],
        ),
      ),
    );
  }
}

class _EventSearchDelegate extends SearchDelegate<CalendarEvent?> {
  final List<CalendarEvent> allEvents;
  final CalendarTheme th;
  _EventSearchDelegate(this.allEvents, this.th);
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
            onPressed: () {
              query = '';
            })
      ];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      icon: Icon(Icons.arrow_back, color: th.appBarText),
      onPressed: () {
        close(context, null);
      });
  @override
  Widget buildResults(BuildContext context) => _buildList(context);
  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final clean = query.replaceAll(' ', '').toLowerCase();
    if (clean.isEmpty) {
      return Center(
          child: Text('검색어를 입력하세요.',
              style: TextStyle(
                  color: th.sectionLabelText.withValues(alpha: 0.5),
                  fontSize: 16)));
    }
    final chosung = DateFormatter.getChosung(clean);
    final results = allEvents.where((e) {
      final t = e.title.replaceAll(' ', '').toLowerCase();
      return t.contains(clean) || DateFormatter.getChosung(t).contains(chosung);
    }).toList();
    if (results.isEmpty) {
      return Center(
          child: Text('검색 결과가 없습니다.',
              style: TextStyle(
                  color: th.sectionLabelText.withValues(alpha: 0.5),
                  fontSize: 16)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (_, i) {
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
            onTap: () {
              close(context, e);
            });
      },
    );
  }
}

class _AppSettingsSheet extends StatefulWidget {
  final AppSettings initial;
  final bool isDark;
  final Color accent;
  final ValueChanged<AppSettings> onChanged;
  const _AppSettingsSheet(
      {required this.initial,
      required this.isDark,
      required this.accent,
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
    setState(() {
      _s = next;
    });
    widget.onChanged(next);
  }

  Color get _text => widget.isDark ? Colors.white : const Color(0xFF1A1A2E);
  Color get _sub => widget.isDark ? Colors.white54 : Colors.black54;
  Color get _tile =>
      widget.isDark ? const Color(0xFF3D3760) : const Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        color: widget.isDark ? const Color(0xFF2A2640) : Colors.white,
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2)))),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const SizedBox(width: 48),
              Text('⚙️ 앱 설정',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: _text)),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('완료',
                      style: TextStyle(
                          color: widget.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)))
            ]),
            const SizedBox(height: 10),
            _sectionTitle('📅 달력 설정'),
            _switchTile(
                icon: Icons.calendar_today_outlined,
                label: '음력 표시 (일요일)',
                subtitle: '매주 일요일 양력 날짜 옆에 음력을 표시합니다',
                value: _s.showLunarCalendar,
                onChanged: (v) {
                  _update(_s.copyWith(showLunarCalendar: v));
                }),
            _switchTile(
                icon: Icons.flag_outlined,
                label: '공휴일 표시',
                subtitle: '한국의 주요 공휴일을 표시합니다',
                value: _s.showHolidays,
                onChanged: (v) {
                  _update(_s.copyWith(showHolidays: v));
                }),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: _tile, borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.swap_vert, color: widget.accent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('달력 넘기기 방식',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: _text)),
                              Text('월 이동 방법을 선택합니다',
                                  style: TextStyle(fontSize: 12, color: _sub))
                            ]))
                      ]),
                      const SizedBox(height: 12),
                      Row(
                          children: [
                        CalendarNavMode.arrow,
                        CalendarNavMode.swipeHorizontal
                      ].map((mode) {
                        final isSel = _s.calendarNavMode == mode;
                        final isLast = mode == CalendarNavMode.swipeHorizontal;
                        return Expanded(
                            child: GestureDetector(
                          onTap: () {
                            _update(_s.copyWith(calendarNavMode: mode));
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: isLast ? 0 : 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                color: isSel
                                    ? widget.accent.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: isSel
                                        ? widget.accent
                                        : (widget.isDark
                                            ? Colors.white24
                                            : Colors.grey.shade300),
                                    width: isSel ? 2 : 1)),
                            child: Column(children: [
                              mode == CalendarNavMode.arrow
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.chevron_left,
                                            color: isSel ? widget.accent : _sub,
                                            size: 22),
                                        Icon(Icons.chevron_right,
                                            color: isSel ? widget.accent : _sub,
                                            size: 22),
                                      ],
                                    )
                                  : Icon(Icons.swap_horiz,
                                      color: isSel ? widget.accent : _sub,
                                      size: 22),
                              const SizedBox(height: 4),
                              Text(mode.label,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isSel ? widget.accent : _sub))
                            ]),
                          ),
                        ));
                      }).toList()),
                    ]),
              ),
            ),
            const SizedBox(height: 16),
            _sectionTitle('🔔 알림 기본 설정'),
            _switchTile(
                icon: Icons.notifications_outlined,
                label: '알림 사용',
                subtitle: '모든 일정 알림을 켜거나 끕니다',
                value: _s.masterEnabled,
                onChanged: (v) {
                  _update(_s.copyWith(masterEnabled: v));
                }),
            if (_s.masterEnabled) ...[
              const SizedBox(height: 16),
              _sectionTitle('새 일정 추가 시 알람 소리/진동 기본값'),
              _switchTile(
                  icon: Icons.volume_up_outlined,
                  label: '소리 허용',
                  subtitle: '기본적으로 소리 알람을 사용합니다',
                  value: _s.globalSilentMode ? false : _s.soundEnabled,
                  disabled: _s.globalSilentMode,
                  onChanged: _s.globalSilentMode
                      ? null
                      : (v) {
                          _update(_s.copyWith(soundEnabled: v));
                        }),
              _switchTile(
                  icon: Icons.vibration_outlined,
                  label: '진동 허용',
                  subtitle: '기본적으로 진동 알람을 사용합니다',
                  value: _s.globalSilentMode ? false : _s.vibrationEnabled,
                  disabled: _s.globalSilentMode,
                  onChanged: _s.globalSilentMode
                      ? null
                      : (v) {
                          _update(_s.copyWith(vibrationEnabled: v));
                        }),
              _switchTile(
                  icon: Icons.volume_off_outlined,
                  label: '무음모드',
                  subtitle: '켜면 모든 소리·진동 알림이 무음으로 차단됨',
                  value: _s.globalSilentMode,
                  onChanged: (v) {
                    _update(_s.copyWith(globalSilentMode: v));
                  }),
              if (!_s.globalSilentMode && _s.soundEnabled) ...[
                const SizedBox(height: 16),
                _sectionTitle('기본 소리 설정'),
                ...NotificationSound.values.map((s) => _soundTile(s))
              ],
              if (!_s.globalSilentMode && _s.vibrationEnabled) ...[
                const SizedBox(height: 16),
                _sectionTitle('기본 진동 패턴'),
                ...VibrationPattern.values.map((p) => _vibrationTile(p))
              ],
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_circle_fill_outlined),
                      label: const Text('현재 기본 설정으로 알림 테스트'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: widget.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      onPressed: () {
                        NotificationService.showTestNotification(
                            _s, _s.effectiveMode);
                      })),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _soundTile(NotificationSound s) {
    if (s == NotificationSound.custom) {
      final isSel = _s.soundOption == NotificationSound.custom;
      return GestureDetector(
        onTap: () {
          FilePicker.platform.pickFiles(type: FileType.audio).then((r) {
            if (r != null) {
              _update(_s.copyWith(
                  soundOption: NotificationSound.custom,
                  customSoundPath: r.files.single.path));
            }
          });
        },
        child: _selectableTile(
            icon: Icons.library_music_outlined,
            isSel: isSel,
            label: s.label,
            sub: _s.customSoundPath?.split('/').last),
      );
    }
    return GestureDetector(
        onTap: () {
          _update(_s.copyWith(soundOption: s));
        },
        child: _selectableTile(
            icon: Icons.music_note,
            isSel: _s.soundOption == s,
            label: s.label));
  }

  Widget _vibrationTile(VibrationPattern p) => GestureDetector(
      onTap: () {
        _update(_s.copyWith(vibrationPattern: p));
      },
      child: _selectableTile(
          icon: Icons.vibration,
          isSel: _s.vibrationPattern == p,
          label: p.label));

  Widget _selectableTile(
          {required IconData icon,
          required bool isSel,
          required String label,
          String? sub}) =>
      Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: isSel ? widget.accent.withValues(alpha: 0.12) : _tile,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSel ? widget.accent : Colors.transparent,
                  width: 1.5)),
          child: Row(children: [
            Icon(icon, color: isSel ? widget.accent : _sub, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSel ? widget.accent : _text)),
                  if (sub != null)
                    Text(sub,
                        style: TextStyle(fontSize: 11, color: _sub),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)
                ])),
            if (isSel) Icon(Icons.check_circle, color: widget.accent, size: 20)
          ]));

  Widget _sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(t,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _sub,
              letterSpacing: 0.5)));

  Widget _switchTile(
          {required IconData icon,
          required String label,
          required String subtitle,
          required bool value,
          ValueChanged<bool>? onChanged,
          Color? activeColor,
          bool disabled = false}) =>
      Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
                color: _tile, borderRadius: BorderRadius.circular(14)),
            child: SwitchListTile(
                secondary: Icon(icon,
                    color: value ? (activeColor ?? widget.accent) : _sub),
                title: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _text)),
                subtitle:
                    Text(subtitle, style: TextStyle(fontSize: 12, color: _sub)),
                value: value,
                activeTrackColor: activeColor ?? widget.accent,
                activeThumbColor: Colors.white,
                onChanged: onChanged)),
      );
}
