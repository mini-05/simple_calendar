// v4.4.3
// gemini_calendar_screen.dart
// lib/ui/calendar_screen.dart
// [v4.4.3] 테마 변경 시 페이지 컨트롤러 파괴 방지 (위젯 트리 통일)
// [v4.4.3] 일정 리스트뷰 Overscroll 시 패널 닫기 제스처 연동 (사용성 극강 개선)
// [v4.4.3] 달력 셀(Tile) 전체 영역 터치 인식되도록 HitTestBehavior.opaque 적용
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';
import 'widgets/calendar_tile.dart';
import 'widgets/app_drawer.dart';
import 'dialogs/event_editor.dart';
import 'widgets/search_delegate.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        NotificationService.requestPermissions();
      });
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _jumpAndSync(
    DateTime targetDate,
    CalendarNotifier notifier,
    CalendarState st,
  ) {
    notifier.jumpToDate(targetDate);
    if (st.settings.calendarNavMode != CalendarNavMode.arrow) {
      final targetPage = _monthToPage(targetDate);
      if (_pageCtrl.hasClients && _pageCtrl.page?.round() != targetPage) {
        final currentPage = _pageCtrl.page?.round() ?? targetPage;
        final distance = (currentPage - targetPage).abs();
        if (distance > 6) {
          final isForward = targetPage > currentPage;
          _pageCtrl.jumpToPage(targetPage + (isForward ? -1 : 1));
        }
        _pageCtrl.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  void _onDaySelected(DateTime sel, DateTime foc, CalendarNotifier notifier) {
    notifier.selectDay(sel, foc);
    setState(() {
      _isPanelOpen = true;
    });
  }

  void _showMonthPicker(
    BuildContext context,
    CalendarState st,
    CalendarNotifier notifier,
  ) {
    int tempYear = st.focusedDay.year;
    int tempMonth = st.focusedDay.month;
    final th = st.settings.currentTheme.themeData;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          th.bottomSheetBg ??
          (th.isDark ? const Color(0xFF2A2640) : Colors.white),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: SizedBox(
              height: 300,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            '취소',
                            style: TextStyle(
                              color:
                                  th.isDark ? Colors.white54 : Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            final maxDay =
                                DateTime(tempYear, tempMonth + 1, 0).day;
                            final finalDate = DateTime(
                              tempYear,
                              tempMonth,
                              st.focusedDay.day.clamp(1, maxDay),
                            );

                            _jumpAndSync(finalDate, notifier, st);
                            setState(() {
                              _isPanelOpen = false;
                            });
                          },
                          child: Text(
                            '완료',
                            style: TextStyle(
                              color: th.primaryAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        brightness:
                            th.isDark ? Brightness.dark : Brightness.light,
                        textTheme: CupertinoTextThemeData(
                          pickerTextStyle: TextStyle(
                            color: th.isDark ? Colors.white : Colors.black,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(
                                initialItem: tempYear - 2020,
                              ),
                              itemExtent: 40,
                              onSelectedItemChanged: (i) => tempYear = 2020 + i,
                              children: List.generate(
                                11,
                                (i) => Center(child: Text('${2020 + i}년')),
                              ),
                            ),
                          ),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(
                                initialItem: tempMonth - 1,
                              ),
                              itemExtent: 40,
                              onSelectedItemChanged: (i) => tempMonth = i + 1,
                              children: List.generate(
                                12,
                                (i) => Center(child: Text('${i + 1}월')),
                              ),
                            ),
                          ),
                        ],
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
      drawer: const AppDrawer(),
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
      body:
          st.isLoading
              ? Center(
                child: CircularProgressIndicator(color: th.primaryAccent),
              )
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
                          children: [_buildCalendarSection(st, notifier, th)],
                        ),
                      ),
                    ),
                  ),
                  if (!_isPanelOpen)
                    Positioned(
                      bottom: 25,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: _SwipeHint(color: th.appBarText),
                      ),
                    ),
                  _PanelDragWrapper(
                    panelHeight: _panelHeight,
                    isPanelOpen: _isPanelOpen,
                    onOpenChanged:
                        (open) => setState(() {
                          _isPanelOpen = open;
                        }),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            th.bottomSheetBg ??
                            (th.isDark
                                ? const Color(0xFF2A2640)
                                : Colors.white),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.26),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            color: Colors.transparent,
                            padding: const EdgeInsets.only(top: 14, bottom: 6),
                            child: Center(
                              child: Container(
                                width: 42,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          _buildSectionLabel(context, st, notifier, th),
                          Expanded(
                            child: _buildEventList(context, st, notifier, th),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    CalendarState st,
    CalendarNotifier notifier,
    CalendarTheme th,
  ) {
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
      'DEC',
    ];
    final today = DateTime.now();
    final focused = st.focusedDay;

    final dateTextStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.3,
      color: th.appBarText,
    );

    final Widget titleWidget = GestureDetector(
      onTap: () => _showMonthPicker(context, st, notifier),
      child: Text('${focused.year}년 ${focused.month}월', style: dateTextStyle),
    );

    final Widget todayBtn = Padding(
      padding: const EdgeInsets.only(right: 14, left: 4),
      child: GestureDetector(
        onTap: () {
          _jumpAndSync(DateTime.now(), notifier, st);
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monthNames[today.month - 1],
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: th.appBarText,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${today.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    color: th.appBarText,
                  ),
                ),
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
              delegate: EventSearchDelegate(
                st.masterEvents.where((e) => !e.isHoliday).toList(),
                th,
              ),
            );
            if (e != null) {
              _jumpAndSync(e.startDt, notifier, st);
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
    CalendarState st,
    CalendarNotifier notifier,
    CalendarTheme th,
  ) {
    final mode = st.settings.calendarNavMode;
    final isArrow = mode == CalendarNavMode.arrow;
    final calWidget =
        isArrow
            ? _buildArrowCalendar(st, notifier, th)
            : _buildSwipeCalendar(st, notifier, th);

    // 💡 [이슈1 완벽 해결] 테마 구조(hasRoundedCard)가 바뀌어도 PageView가 파괴되지 않도록
    // 위젯 트리의 구조를 <Expanded - Padding - Container>로 동일하게 고정하고 속성값만 변경합니다.
    return Expanded(
      child: Padding(
        padding:
            th.hasRoundedCard
                ? const EdgeInsets.fromLTRB(16, 0, 16, 0)
                : EdgeInsets.zero,
        child: Container(
          decoration:
              th.hasRoundedCard
                  ? BoxDecoration(
                    color: th.calendarBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  )
                  : BoxDecoration(
                    color: th.calendarBg,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
          child: calWidget,
        ),
      ),
    );
  }

  Widget _buildArrowCalendar(
    CalendarState st,
    CalendarNotifier notifier,
    CalendarTheme th,
  ) {
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
              child: Text(
                dows[day.weekday % 7],
                style: TextStyle(
                  color: c,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
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
          rightChevronIcon: Icon(Icons.chevron_right, color: hc),
        ),
        onHeaderTapped: (date) {
          _showMonthPicker(context, st, notifier);
        },
      ),
    );
  }

  Widget _buildSwipeCalendar(
    CalendarState st,
    CalendarNotifier notifier,
    CalendarTheme th,
  ) {
    final hc = th.appBarText;
    const dows = ['일', '월', '화', '수', '목', '금', '토'];
    final axis =
        st.settings.calendarNavMode == CalendarNavMode.swipeVertical
            ? Axis.vertical
            : Axis.horizontal;

    return Column(
      children: [
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
                  child: Text(
                    dows[i],
                    style: TextStyle(
                      color: c,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: PageView.builder(
            scrollDirection: axis,
            controller: _pageCtrl,
            pageSnapping: true,
            onPageChanged: (page) {
              notifier.onSwipePageChanged(_pageToMonth(page));
            },
            itemBuilder:
                (_, page) =>
                    _buildMonthGrid(_pageToMonth(page), st, notifier, th),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthGrid(
    DateTime month,
    CalendarState st,
    CalendarNotifier notifier,
    CalendarTheme th,
  ) {
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
              final date = first.subtract(Duration(days: offset - (w * 7 + d)));
              return Expanded(
                child: GestureDetector(
                  // 💡 [이슈3 완벽 해결] 빈 공간(투명 영역)을 터치해도 인식하도록 HitTestBehavior.opaque 추가!
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _onDaySelected(date, month, notifier);
                  },
                  child: _tile(
                    date,
                    st,
                    th,
                    isToday: isSameDay(date, today),
                    isSelected: isSameDay(date, st.selectedDay),
                    isOutside: date.month != month.month,
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _tile(
    DateTime day,
    CalendarState st,
    CalendarTheme th, {
    bool isToday = false,
    bool isSelected = false,
    bool isOutside = false,
  }) {
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

    // 💡 [이슈3 완벽 해결 보강] 전체 영역 터치 인식을 위해 Container(color: Colors.transparent) 껍데기 씌우기
    return Container(
      color: Colors.transparent,
      child: Stack(
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
            showLunar: false,
          ),
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
      ),
    );
  }

  Widget _buildSectionLabel(
    BuildContext context,
    CalendarState st,
    CalendarNotifier notifier,
    CalendarTheme th,
  ) {
    final displayDay = st.selectedDay ?? st.focusedDay;
    final isToday = isSameDay(displayDay, DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 20, 12),
      child: Row(
        children: [
          Text(
            isToday ? 'Today' : DateFormatter.formatDateKorean(displayDay),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: th.sectionLabelText,
            ),
          ),
          const Spacer(),
          Text(
            '무음모드',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: th.isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.75,
            child: CupertinoSwitch(
              activeTrackColor: th.primaryAccent,
              value: st.settings.globalSilentMode,
              onChanged: (val) async {
                await notifier.updateSettings(
                  st.settings.copyWith(globalSilentMode: val),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(
    BuildContext context,
    CalendarState st,
    CalendarNotifier notifier,
    CalendarTheme th,
  ) {
    if (st.selectedEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 50),
          child: Text(
            '이 날의 일정이 없어요',
            style: TextStyle(
              color: th.sectionLabelText.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      // 💡 [이슈2 보조] 리스트가 짧아도 항상 스크롤(Overscroll) 이벤트를 발생시켜 패널 닫기를 유도합니다.
      physics: const AlwaysScrollableScrollPhysics(),
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
            formatHHmm: DateFormatter.formatHHmm,
          ),
        );
      },
    );
  }

  void _showEventEditor(
    BuildContext context,
    CalendarState st,
    CalendarNotifier notifier, {
    CalendarEvent? existingEvent,
  }) {
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
      },
    );
  }

  void _showActionSheet(
    BuildContext context,
    CalendarEvent event,
    CalendarState st,
    CalendarNotifier notifier,
    CalendarTheme th,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          th.bottomSheetBg ??
          (th.isDark ? const Color(0xFF2A2640) : Colors.white),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: th.iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, color: th.iconColor),
                    ),
                    title: Text(
                      '수정하기',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                            (th.isDark || th.bottomSheetBg != null)
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEventEditor(
                        context,
                        st,
                        notifier,
                        existingEvent: event,
                      );
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete, color: Colors.redAccent),
                    ),
                    title: const Text(
                      '삭제하기',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await notifier.deleteEvent(event.id);
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }
} // end of _CalendarScreenState

class _PanelDragWrapper extends StatefulWidget {
  final double panelHeight;
  final bool isPanelOpen;
  final Widget child;
  final ValueChanged<bool> onOpenChanged;

  const _PanelDragWrapper({
    required this.panelHeight,
    required this.isPanelOpen,
    required this.child,
    required this.onOpenChanged,
  });

  @override
  State<_PanelDragWrapper> createState() => _PanelDragWrapperState();
}

class _PanelDragWrapperState extends State<_PanelDragWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snapCtrl;
  late Animation<double> _snapAnim;
  double _currentBottom = 0;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _currentBottom = widget.isPanelOpen ? 0 : widget.panelHeight;
  }

  @override
  void didUpdateWidget(_PanelDragWrapper old) {
    super.didUpdateWidget(old);
    if (old.isPanelOpen != widget.isPanelOpen && !_animating) {
      _snapTo(widget.isPanelOpen ? 0 : widget.panelHeight);
    }
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _snapTo(double target) {
    _animating = true;
    final from = _currentBottom;
    _snapAnim =
        Tween<double>(begin: from, end: target).animate(
            CurvedAnimation(parent: _snapCtrl, curve: Curves.easeInOutCubic),
          )
          ..addListener(() {
            setState(() => _currentBottom = _snapAnim.value);
          })
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) {
              _animating = false;
              _currentBottom = target;
            }
          });
    _snapCtrl.forward(from: 0);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (widget.panelHeight <= 0) return;
    _currentBottom = (_currentBottom + d.delta.dy).clamp(
      0.0,
      widget.panelHeight,
    );
    setState(() {});
  }

  void _onDragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    final half = widget.panelHeight / 2;
    final bool shouldOpen;

    if (velocity.abs() > 400) {
      shouldOpen = velocity < 0;
    } else {
      shouldOpen = _currentBottom < half;
    }

    _snapTo(shouldOpen ? 0 : widget.panelHeight);
    widget.onOpenChanged(shouldOpen);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = -(_currentBottom);

    return Positioned(
      bottom: bottom,
      left: 0,
      right: 0,
      height: widget.panelHeight,
      // 💡 [이슈2 완벽 해결] 패널 안의 스크롤 뷰(ListView)에서 발생하는 제스처를 감청합니다!
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification info) {
          // 리스트가 최상단일 때 + 쓸어내리는 힘이 발생하면 -> 패널 닫기 액션으로 힘을 넘겨줍니다.
          if (info is OverscrollNotification &&
              info.overscroll < 0 &&
              info.dragDetails != null) {
            _onDragUpdate(info.dragDetails!);
          } else if (info is ScrollUpdateNotification &&
              info.metrics.pixels <= 0 &&
              info.dragDetails != null &&
              info.dragDetails!.delta.dy > 0) {
            _onDragUpdate(info.dragDetails!);
          } else if (info is ScrollEndNotification) {
            // 패널이 어중간하게 열려있을 때 손을 떼면 스냅(Snap) 애니메이션 실행
            if (_currentBottom > 0 && _currentBottom < widget.panelHeight) {
              _onDragEnd(DragEndDetails(primaryVelocity: 0));
            }
          }
          // false를 반환하여 일반적인 리스트 스크롤도 방해받지 않도록 합니다.
          return false;
        },
        child: GestureDetector(
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          behavior: HitTestBehavior.translucent,
          child: widget.child,
        ),
      ),
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
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
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
      builder:
          (_, __) => Transform.translate(
            offset: Offset(0, -6 * _ctrl.value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: widget.color.withValues(alpha: 0.7),
                  size: 26,
                ),
                Transform.translate(
                  offset: const Offset(0, -12),
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: widget.color.withValues(alpha: 0.3),
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
