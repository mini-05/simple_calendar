import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyCalendarApp());
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🎨 테마 정의 (6종)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
enum AppTheme { apple, samsung, naver, darkNeon, classicBlue, todoSky }

class CalendarThemeData {
  final String name;
  final String emoji;
  final Color scaffoldBg;
  final Color appBarBg;
  final Color appBarText;
  final Color calendarBg;
  final int primaryAccentInt;
  final Color secondaryAccent;
  final Color cardBg;
  final Color cardBorder;
  final Color eventTitleText;
  final Color eventSubText;
  final Color iconBg;
  final Color iconColor;
  final Color sectionLabelText;
  // 투두스카이: 하단 패널 별도 배경색
  final Color? bottomPanelBg;
  final Color? bottomPanelText;
  final bool isDark;

  const CalendarThemeData({
    required this.name,
    required this.emoji,
    required this.scaffoldBg,
    required this.appBarBg,
    required this.appBarText,
    required this.calendarBg,
    required this.primaryAccentInt,
    required this.secondaryAccent,
    required this.cardBg,
    required this.cardBorder,
    required this.eventTitleText,
    required this.eventSubText,
    required this.iconBg,
    required this.iconColor,
    required this.sectionLabelText,
    this.bottomPanelBg,
    this.bottomPanelText,
    this.isDark = false,
  });

  Color get primaryAccent => Color(primaryAccentInt);
}

// ── 6가지 테마 ──
const themeApple = CalendarThemeData(
  name: '애플 캘린더',
  emoji: '🍎',
  scaffoldBg: Color(0xFFF8F9FF),
  appBarBg: Colors.white,
  appBarText: Color(0xFF1A1A2E),
  calendarBg: Colors.white,
  primaryAccentInt: 0xFFFA233B,
  secondaryAccent: Color(0xFFFFD1D6),
  cardBg: Colors.white,
  cardBorder: Colors.transparent,
  eventTitleText: Color(0xFF1A1A2E),
  eventSubText: Color(0xFF888888),
  iconBg: Color(0xFFFFF0F1),
  iconColor: Color(0xFFFA233B),
  sectionLabelText: Color(0xFF1A1A2E),
);
const themeSamsung = CalendarThemeData(
  name: '삼성 캘린더',
  emoji: '📱',
  scaffoldBg: Color(0xFFF2F2F2),
  appBarBg: Color(0xFFF2F2F2),
  appBarText: Color(0xFF222222),
  calendarBg: Colors.white,
  primaryAccentInt: 0xFF2196F3,
  secondaryAccent: Color(0xFFBBDEF0),
  cardBg: Colors.white,
  cardBorder: Colors.transparent,
  eventTitleText: Color(0xFF222222),
  eventSubText: Color(0xFF666666),
  iconBg: Color(0xFFE3F2FD),
  iconColor: Color(0xFF2196F3),
  sectionLabelText: Color(0xFF444444),
);
const themeNaver = CalendarThemeData(
  name: '네이버 캘린더',
  emoji: '🇳',
  scaffoldBg: Colors.white,
  appBarBg: Colors.white,
  appBarText: Colors.black,
  calendarBg: Colors.white,
  primaryAccentInt: 0xFF03C75A,
  secondaryAccent: Color(0xFFD4F5E1),
  cardBg: Color(0xFFF9F9F9),
  cardBorder: Colors.transparent,
  eventTitleText: Colors.black87,
  eventSubText: Colors.black54,
  iconBg: Color(0xFFE6F9ED),
  iconColor: Color(0xFF03C75A),
  sectionLabelText: Colors.black,
);
const themeDarkNeon = CalendarThemeData(
  name: '다크 네온',
  emoji: '🌙',
  scaffoldBg: Color(0xFF1E1B2E),
  appBarBg: Color(0xFF1E1B2E),
  appBarText: Colors.white,
  calendarBg: Color(0xFF2A2640),
  primaryAccentInt: 0xFF9C6FE4,
  secondaryAccent: Color(0xFF00D4FF),
  cardBg: Color(0xFF2A2640),
  cardBorder: Color(0xFF3D3760),
  eventTitleText: Colors.white,
  eventSubText: Color(0xFF9E9BB8),
  iconBg: Color(0xFF3D3760),
  iconColor: Color(0xFF9C6FE4),
  sectionLabelText: Colors.white,
  isDark: true,
);
const themeClassicBlue = CalendarThemeData(
  name: '클래식 블루',
  emoji: '☁️',
  scaffoldBg: Color(0xFFF8F9FF),
  appBarBg: Colors.white,
  appBarText: Color(0xFF1A1A2E),
  calendarBg: Colors.white,
  primaryAccentInt: 0xFF4A90D9,
  secondaryAccent: Color(0xFFDDEEFF),
  cardBg: Colors.white,
  cardBorder: Color(0xFFEEEEEE),
  eventTitleText: Color(0xFF1A1A2E),
  eventSubText: Color(0xFF888888),
  iconBg: Color(0xFFEEF4FF),
  iconColor: Color(0xFF4A90D9),
  sectionLabelText: Color(0xFF1A1A2E),
);
// 4. 투두 스카이 리디자인:
//    상단(달력) = 흰색, 하단(일정목록) = 어두운 네이비(#2D3142)
const themeTodoSky = CalendarThemeData(
  name: '투두 스카이', emoji: '✅',
  scaffoldBg: Colors.white, // 전체 배경 = 흰색
  appBarBg: Colors.white,
  appBarText: Color(0xFF2D3142),
  calendarBg: Colors.white, // 달력 배경 = 흰색
  primaryAccentInt: 0xFFEF6C6C, // 포인트 = 산호핑크 (calendar3의 버튼색)
  secondaryAccent: Color(0xFFF5E6E6),
  cardBg: Color(0xFF3A3F5C), // 카드 = 중간 네이비
  cardBorder: Color(0xFF4A5073),
  eventTitleText: Colors.white, // 카드 글자 = 흰색
  eventSubText: Color(0xFFADB5D0),
  iconBg: Color(0xFF4A5073),
  iconColor: Color(0xFFEF6C6C),
  sectionLabelText: Colors.white, // 하단 라벨 = 흰색
  bottomPanelBg: Color(0xFF2D3142), // 하단 패널 = 어두운 네이비
  bottomPanelText: Colors.white,
);

const Map<AppTheme, CalendarThemeData> themeMap = {
  AppTheme.apple: themeApple,
  AppTheme.samsung: themeSamsung,
  AppTheme.naver: themeNaver,
  AppTheme.darkNeon: themeDarkNeon,
  AppTheme.classicBlue: themeClassicBlue,
  AppTheme.todoSky: themeTodoSky,
};

const int defaultEventColor = 0xFF2196F3;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 앱 루트
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class MyCalendarApp extends StatelessWidget {
  const MyCalendarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Calendar',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      locale: const Locale('ko', 'KR'),
      home: const CalendarScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📝 데이터 모델
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class CalendarEvent {
  final int id;
  final String title;
  final String date;
  final String? endDate;
  final int? colorValue;
  final bool isAllDay;
  final String? startTime;
  final String? endTime;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    this.endDate,
    this.colorValue,
    this.isAllDay = false,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'endDate': endDate,
        'colorValue': colorValue,
        'isAllDay': isAllDay,
        'startTime': startTime,
        'endTime': endTime,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'] as int,
        title: json['title'] as String,
        date: json['date'] as String,
        endDate: json['endDate'] as String?,
        colorValue: json['colorValue'] as int?,
        isAllDay: json['isAllDay'] as bool? ?? false,
        startTime: json['startTime'] as String?,
        endTime: json['endTime'] as String?,
      );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 💾 저장소
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class EventStorage {
  static const _eventsKey = 'calendar_events_v5';
  static const _nextIdKey = 'calendar_next_id_v5';

  static Future<List<CalendarEvent>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_eventsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveAll(List<CalendarEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _eventsKey, jsonEncode(events.map((e) => e.toJson()).toList()));
  }

  static Future<int> _nextId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = (prefs.getInt(_nextIdKey) ?? 0) + 1;
    await prefs.setInt(_nextIdKey, id);
    return id;
  }

  static Future<void> insert(
      String date,
      String? endDate,
      String title,
      int? colorValue,
      bool isAllDay,
      String? startTime,
      String? endTime) async {
    final events = await loadAll();
    events.add(CalendarEvent(
      id: await _nextId(),
      title: title,
      date: date,
      endDate: endDate,
      colorValue: colorValue,
      isAllDay: isAllDay,
      startTime: startTime,
      endTime: endTime,
    ));
    await saveAll(events);
  }

  static Future<void> update(
      int id,
      String newTitle,
      String newDate,
      String? newEndDate,
      int? colorValue,
      bool isAllDay,
      String? startTime,
      String? endTime) async {
    final events = await loadAll();
    final idx = events.indexWhere((e) => e.id == id);
    if (idx != -1) {
      events[idx] = CalendarEvent(
        id: id,
        title: newTitle,
        date: newDate,
        endDate: newEndDate,
        colorValue: colorValue,
        isAllDay: isAllDay,
        startTime: startTime,
        endTime: endTime,
      );
      await saveAll(events);
    }
  }

  static Future<void> delete(int id) async {
    final events = await loadAll();
    events.removeWhere((e) => e.id == id);
    await saveAll(events);
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📱 메인 화면
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CalendarEvent> _allEvents = [];
  bool _isLoading = true;

  AppTheme _currentTheme = AppTheme.samsung;
  CalendarThemeData get th => themeMap[_currentTheme]!;

  // 삼성/네이버: 셀 안에 일정 텍스트, 그 외: 하단 도트
  bool get _showTextInside =>
      _currentTheme == AppTheme.samsung || _currentTheme == AppTheme.naver;

  // 투두스카이: 하단 배경색
  bool get _isTodoSky => _currentTheme == AppTheme.todoSky;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadEvents() async {
    final all = await EventStorage.loadAll();
    all.sort((a, b) {
      final dc = a.date.compareTo(b.date);
      if (dc != 0) return dc;
      if (a.isAllDay && !b.isAllDay) return -1;
      if (!a.isAllDay && b.isAllDay) return 1;
      if (!a.isAllDay && !b.isAllDay) {
        final tc = (a.startTime ?? '00:00').compareTo(b.startTime ?? '00:00');
        if (tc != 0) return tc;
      }
      return a.title.compareTo(b.title);
    });
    setState(() {
      _allEvents = all;
      _isLoading = false;
    });
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    return _allEvents.where((e) {
      final start = DateTime.parse(e.date);
      final end = e.endDate != null ? DateTime.parse(e.endDate!) : start;
      return !target.isBefore(start) && !target.isAfter(end);
    }).toList();
  }

  String _formatHHmm(String hhmm) {
    final p = hhmm.split(':');
    if (p.length != 2) return '';
    final h = int.parse(p[0]), m = int.parse(p[1]);
    final period = h < 12 ? '오전' : '오후';
    final disp = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $disp:${m.toString().padLeft(2, '0')}';
  }

  String _formatDateKorean(DateTime d) {
    const wd = ['월', '화', '수', '목', '금', '토', '일'];
    return '${d.year}년 ${d.month}월 ${d.day}일 (${wd[d.weekday - 1]})';
  }

  // ──────────────────────────────────────
  // 테마 선택 바텀시트
  // ──────────────────────────────────────
  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: th.isDark ? const Color(0xFF2A2640) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.6,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              )),
              Text('테마 선택',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          th.isDark ? Colors.white : const Color(0xFF1A1A2E))),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: AppTheme.values.map((t) {
                    final data = themeMap[t]!;
                    final isSel = _currentTheme == t;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentTheme = t);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSel
                              ? data.primaryAccent.withValues(alpha: 0.15)
                              : (th.isDark
                                  ? const Color(0xFF3D3760)
                                  : const Color(0xFFF5F5F5)),
                          borderRadius: BorderRadius.circular(14),
                          border: isSel
                              ? Border.all(color: data.primaryAccent, width: 2)
                              : null,
                        ),
                        child: Row(children: [
                          _colorDot(data.scaffoldBg),
                          _colorDot(data.primaryAccent),
                          const SizedBox(width: 12),
                          Text('${data.emoji}  ${data.name}',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: th.isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A2E))),
                          const Spacer(),
                          if (isSel)
                            Icon(Icons.check_circle,
                                color: data.primaryAccent, size: 22),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorDot(Color color) => Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
      );

  // ──────────────────────────────────────
  // 색상 선택기
  // ──────────────────────────────────────
  Widget _buildColorPicker(ValueNotifier<int> colorNotifier) {
    const opts = [
      defaultEventColor,
      0xFFE57373,
      0xFF81C784,
      0xFFFFB74D,
      0xFFBA68C8
    ];
    return ValueListenableBuilder<int>(
      valueListenable: colorNotifier,
      builder: (_, sel, __) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: opts.map((v) {
          final isSel = sel == v;
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
                        color: th.isDark ? Colors.white : Colors.black54,
                        width: 3)
                    : null,
              ),
              child: isSel
                  ? const Icon(Icons.check, size: 22, color: Colors.white)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ──────────────────────────────────────
  // 3. 날짜 선택 행 - '완료' 버튼 추가
  // ──────────────────────────────────────
  Widget _buildDatePickerRow(
      String label, ValueNotifier<DateTime> notifier, BuildContext parentCtx) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: notifier,
      builder: (_, date, __) => InkWell(
        onTap: () {
          DateTime tempDate = date;
          showModalBottomSheet<void>(
            context: parentCtx,
            builder: (_) => Container(
              color: th.isDark ? const Color(0xFF2A2640) : Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 완료 버튼 행
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('날짜 선택',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color:
                                    th.isDark ? Colors.white : Colors.black87)),
                        TextButton(
                          onPressed: () {
                            notifier.value = tempDate;
                            Navigator.pop(_);
                          },
                          child: Text('완료',
                              style: TextStyle(
                                  color: th.primaryAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  SizedBox(
                    height: 220,
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                              color: th.isDark ? Colors.white : Colors.black,
                              fontSize: 22),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: date,
                        onDateTimeChanged: (d) => tempDate = d,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      color: th.isDark ? Colors.white70 : Colors.black87,
                      fontSize: 15)),
              Text(_formatDateKorean(date),
                  style: TextStyle(
                      color: th.primaryAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────
  // 3. 시간 선택 행 - '완료' 버튼 추가
  // ──────────────────────────────────────
  Widget _buildTimePickerRow(
      String label, ValueNotifier<DateTime> notifier, BuildContext parentCtx) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: notifier,
      builder: (_, time, __) {
        final disp = _formatHHmm(
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
        return InkWell(
          onTap: () {
            DateTime tempTime = time;
            showModalBottomSheet<void>(
              context: parentCtx,
              builder: (_) => Container(
                color: th.isDark ? const Color(0xFF2A2640) : Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('시간 선택',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: th.isDark
                                      ? Colors.white
                                      : Colors.black87)),
                          TextButton(
                            onPressed: () {
                              notifier.value = tempTime;
                              Navigator.pop(_);
                            },
                            child: Text('완료',
                                style: TextStyle(
                                    color: th.primaryAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 220,
                      child: CupertinoTheme(
                        data: CupertinoThemeData(
                          textTheme: CupertinoTextThemeData(
                            dateTimePickerTextStyle: TextStyle(
                                color: th.isDark ? Colors.white : Colors.black,
                                fontSize: 22),
                          ),
                        ),
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          initialDateTime: time,
                          onDateTimeChanged: (t) => tempTime = t,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: TextStyle(
                        color: th.isDark ? Colors.white70 : Colors.black87,
                        fontSize: 15)),
                Text(disp,
                    style: TextStyle(
                        color: th.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────
  // 일정 추가/수정 다이얼로그
  // ──────────────────────────────────────
  void _showEventDialog({CalendarEvent? existingEvent}) {
    final isEdit = existingEvent != null;
    final ctrl = TextEditingController(text: isEdit ? existingEvent.title : '');

    final startDateN = ValueNotifier<DateTime>(isEdit
        ? DateTime.parse(existingEvent.date)
        : (_selectedDay ?? DateTime.now()));
    final endDateN = ValueNotifier<DateTime>(
        isEdit && existingEvent.endDate != null
            ? DateTime.parse(existingEvent.endDate!)
            : startDateN.value);
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

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: th.isDark ? const Color(0xFF2A2640) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEdit ? '✏️ 일정 수정' : '✨ 새 일정 추가',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: th.isDark ? Colors.white : Colors.black)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                style:
                    TextStyle(color: th.isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: '일정을 입력하세요',
                  hintStyle: TextStyle(
                      color: th.isDark ? Colors.white38 : Colors.grey),
                  filled: true,
                  fillColor:
                      th.isDark ? const Color(0xFF3D3760) : Colors.grey[100],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: th.isDark ? const Color(0xFF3D3760) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: isAllDayN,
                  builder: (_, isAllDay, __) => Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('하루 종일',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: th.isDark
                                      ? Colors.white
                                      : Colors.black87)),
                          CupertinoSwitch(
                              activeTrackColor: th.primaryAccent,
                              value: isAllDay,
                              onChanged: (v) => isAllDayN.value = v),
                        ],
                      ),
                    ),
                    Divider(
                        height: 1,
                        color: th.isDark ? Colors.white12 : Colors.grey[300]),
                    _buildDatePickerRow('시작 날짜', startDateN, dlgCtx),
                    if (!isAllDay)
                      _buildTimePickerRow('시작 시간', startTimeN, dlgCtx),
                    Divider(
                        height: 1,
                        color: th.isDark ? Colors.white12 : Colors.grey[300]),
                    _buildDatePickerRow('종료 날짜', endDateN, dlgCtx),
                    if (!isAllDay)
                      _buildTimePickerRow('종료 시간', endTimeN, dlgCtx),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              _buildColorPicker(colorN),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (dlgCtx.mounted) Navigator.pop(dlgCtx);
            },
            child: Text('취소',
                style:
                    TextStyle(color: th.isDark ? Colors.white54 : Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: th.primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) {
                _showAlert(dlgCtx, '일정을 입력해 주세요.');
                return;
              }
              final sD = startDateN.value, eD = endDateN.value;
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
              final sDStr = _dateKey(sD), eDStr = _dateKey(eD);
              String? sT, eT;
              if (!isAllDay) {
                sT =
                    '${startTimeN.value.hour.toString().padLeft(2, '0')}:${startTimeN.value.minute.toString().padLeft(2, '0')}';
                eT =
                    '${endTimeN.value.hour.toString().padLeft(2, '0')}:${endTimeN.value.minute.toString().padLeft(2, '0')}';
              }
              if (isEdit) {
                await EventStorage.update(existingEvent.id, title, sDStr, eDStr,
                    colorN.value, isAllDay, sT, eT);
              } else {
                await EventStorage.insert(
                    sDStr, eDStr, title, colorN.value, isAllDay, sT, eT);
              }
              await _loadEvents();
              if (dlgCtx.mounted) Navigator.pop(dlgCtx);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ).then((_) {
      ctrl.dispose();
      startDateN.dispose();
      endDateN.dispose();
      isAllDayN.dispose();
      startTimeN.dispose();
      endTimeN.dispose();
      colorN.dispose();
    });
  }

  void _showAlert(BuildContext ctx, String msg) {
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Text('⚠️ 알림', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () {
                if (c.mounted) Navigator.pop(c);
              },
              child: const Text('확인'))
        ],
      ),
    );
  }

  void _showActionSheet(CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isTodoSky
          ? const Color(0xFF3A3F5C)
          : (th.isDark ? const Color(0xFF2A2640) : Colors.white),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
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
                        color: (th.isDark || _isTodoSky)
                            ? Colors.white
                            : Colors.black)),
                onTap: () {
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showEventDialog(existingEvent: event);
                },
              ),
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
                  if (ctx.mounted) Navigator.pop(ctx);
                  await EventStorage.delete(event.id);
                  await _loadEvents();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────
  // 🏗️ 메인 빌드
  // ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // 투두스카이: 상단 흰색 + 하단 어두운 네이비
    if (_isTodoSky) return _buildTodoSkyLayout();

    return Scaffold(
      backgroundColor: th.scaffoldBg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: th.primaryAccent))
          : Column(children: [
              _buildCalendarSection(),
              _buildSectionLabel(),
              Expanded(child: _buildEventList()),
            ]),
      floatingActionButton: _buildFAB(),
    );
  }

  // ──────────────────────────────────────
  // 4. 투두스카이 전용 레이아웃 (calendar3 스타일)
  //    흰 상단 달력 + 어두운 하단 패널
  // ──────────────────────────────────────
  Widget _buildTodoSkyLayout() {
    final panelBg = th.bottomPanelBg ?? const Color(0xFF2D3142);
    final today = DateTime.now();
    final displayDay = _selectedDay ?? _focusedDay;
    final isToday = isSameDay(displayDay, today);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 상단: 흰 달력
                _buildCalendarSection(),

                // 하단: 어두운 패널
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: panelBg,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 날짜 헤더 ("Today" or 선택 날짜)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                          child: Text(
                            isToday ? 'Today' : _formatDateKorean(displayDay),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        // 일정 목록
                        Expanded(child: _buildEventList()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildFAB(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: th.appBarBg,
      elevation: 0,
      centerTitle: true,
      title: Text('My Calendar',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: th.appBarText, fontSize: 18)),
      actions: [
        // 2. '오늘' 버튼 - 오늘 날짜로 즉시 이동
        TextButton(
          onPressed: () {
            final now = DateTime.now();
            setState(() {
              _focusedDay = now;
              _selectedDay = now;
            });
          },
          child: Text('오늘',
              style: TextStyle(
                  color: th.primaryAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
        IconButton(
          onPressed: _showThemePicker,
          icon: Icon(Icons.palette_outlined, color: th.appBarText),
          tooltip: '테마 변경',
        ),
      ],
    );
  }

  Widget _buildFAB() => FloatingActionButton(
        onPressed: () => _showEventDialog(),
        backgroundColor: th.primaryAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      );

  Widget _buildSectionLabel() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('일정 목록',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: th.sectionLabelText)),
        ),
      );

  // ──────────────────────────────────────
  // 달력 섹션
  // ──────────────────────────────────────
  Widget _buildCalendarSection() {
    final isFloating =
        _currentTheme == AppTheme.todoSky || _currentTheme == AppTheme.darkNeon;

    if (isFloating) {
      return Padding(
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
            ],
          ),
          child: _tableCalendar(),
        ),
      );
    } else {
      return Container(
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
          ],
        ),
        child: _tableCalendar(),
      );
    }
  }

  // ──────────────────────────────────────
  // 1. 오늘 날짜 동그라미 커스텀 셀
  // ──────────────────────────────────────
  Widget _buildCustomCell(DateTime day,
      {bool isToday = false, bool isSelected = false, bool isOutside = false}) {
    final events = _getEventsForDay(day);

    // 기본 텍스트 색 결정
    Color textColor;
    if (isOutside) {
      textColor = th.isDark ? Colors.white24 : Colors.grey[350]!;
    } else if (day.weekday == DateTime.sunday) {
      textColor = Colors.redAccent;
    } else if (day.weekday == DateTime.saturday) {
      textColor = Colors.blueAccent;
    } else {
      textColor = th.isDark ? Colors.white : const Color(0xFF333333);
    }

    // 1. 오늘 날짜 동그라미 스타일:
    //    - 테두리 원 + 굵은 글씨 (평일=검정, 토=파랑, 일=빨강)
    //    - 선택된 날짜: 채워진 원(primaryAccent) + 흰 글씨
    final bool todayRing = isToday && !isSelected;
    Color? todayRingColor;
    if (todayRing && !isOutside) {
      if (day.weekday == DateTime.sunday) {
        todayRingColor = Colors.redAccent;
      } else if (day.weekday == DateTime.saturday) {
        todayRingColor = Colors.blueAccent;
      } else {
        todayRingColor = th.isDark ? Colors.white70 : Colors.black87;
      }
    }

    if (isSelected) textColor = Colors.white;

    final bool showTextInside = _showTextInside;

    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 2),
      child: Column(
        crossAxisAlignment: showTextInside
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
        children: [
          // 날짜 숫자 + 오늘 링/선택 원
          Align(
            alignment: showTextInside
                ? (_currentTheme == AppTheme.samsung
                    ? Alignment.topLeft
                    : Alignment.topCenter)
                : Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(
                  top: showTextInside ? 3.0 : 5.0,
                  left: showTextInside ? 4.0 : 0),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  // 선택: 채워진 원
                  color: isSelected ? th.primaryAccent : null,
                  // 오늘: 테두리 원
                  border: todayRingColor != null
                      ? Border.all(color: todayRingColor, width: 1.8)
                      : null,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: (isToday || isSelected)
                        ? FontWeight.bold
                        : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),

          // 삼성/네이버: 셀 안 일정 텍스트 바
          if (showTextInside && events.isNotEmpty)
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 1),
                children: events.take(3).map((e) {
                  final color = e.colorValue != null
                      ? Color(e.colorValue!)
                      : th.primaryAccent;
                  final eStart = DateTime.parse(e.date);
                  final eEnd =
                      e.endDate != null ? DateTime.parse(e.endDate!) : eStart;
                  final cur = DateTime(day.year, day.month, day.day);
                  final isFirst = cur.isAtSameMomentAs(eStart);
                  final isLast = cur.isAtSameMomentAs(eEnd);
                  final dTitle = (!e.isAllDay && e.startTime != null && isFirst)
                      ? '${e.startTime}   ${e.title}'
                      : e.title;
                  return Container(
                    margin: EdgeInsets.only(
                        bottom: 2,
                        left: isFirst ? 3.0 : 0,
                        right: isLast ? 3.0 : 0),
                    padding: EdgeInsets.only(
                        left: isFirst ? 4.0 : 2.0, right: 2, top: 2, bottom: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(isFirst ? 4.0 : 0),
                        right: Radius.circular(isLast ? 4.0 : 0),
                      ),
                    ),
                    child: Text(dTitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.clip),
                  );
                }).toList(),
              ),
            ),

          // 그 외 테마: 하단 도트 마커
          if (!showTextInside && events.isNotEmpty && !isOutside)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: events.take(3).map((e) {
                  final color = e.colorValue != null
                      ? Color(e.colorValue!)
                      : th.primaryAccent;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 4,
                    height: 4,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────
  // TableCalendar
  // ──────────────────────────────────────
  Widget _tableCalendar() {
    String Function(DateTime, dynamic) headerFmt =
        (d, _) => '${d.year}년 ${d.month}월';
    if (_currentTheme == AppTheme.apple || _currentTheme == AppTheme.naver) {
      headerFmt = (d, _) => '${d.year}. ${d.month}';
    }
    if (_isTodoSky) {
      headerFmt = (d, _) => '${d.year}년 ${d.month}월';
    }

    // 헤더 텍스트 색: todoSky 달력은 흰색 배경이므로 어두운 색
    final headerColor = _isTodoSky ? const Color(0xFF2D3142) : th.appBarText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TableCalendar<CalendarEvent>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (sel, foc) => setState(() {
          _selectedDay = sel;
          _focusedDay = foc;
        }),
        eventLoader: _getEventsForDay,
        rowHeight: _showTextInside ? 80 : 56,
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            const dows = ['월', '화', '수', '목', '금', '토', '일'];
            Color c = headerColor.withValues(alpha: 0.6);
            if (day.weekday == DateTime.sunday) {
              c = Colors.redAccent;
            } else if (day.weekday == DateTime.saturday) {
              c = Colors.blueAccent;
            }
            return Center(
                child: Text(dows[day.weekday - 1],
                    style: TextStyle(
                        color: c, fontSize: 12, fontWeight: FontWeight.bold)));
          },
          defaultBuilder: (_, day, __) => _buildCustomCell(day),
          todayBuilder: (_, day, __) => _buildCustomCell(day, isToday: true),
          selectedBuilder: (_, day, __) =>
              _buildCustomCell(day, isSelected: true),
          outsideBuilder: (_, day, __) =>
              _buildCustomCell(day, isOutside: true),
          markerBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextFormatter: headerFmt,
          titleTextStyle: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: headerColor),
          leftChevronIcon: Icon(Icons.chevron_left, color: headerColor),
          rightChevronIcon: Icon(Icons.chevron_right, color: headerColor),
        ),
      ),
    );
  }

  // ──────────────────────────────────────
  // 일정 목록
  // ──────────────────────────────────────
  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay ?? _focusedDay);
    if (events.isEmpty) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Text('이 날의 일정이 없어요',
            style: TextStyle(
                color: th.sectionLabelText.withValues(alpha: 0.5),
                fontSize: 16)),
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: events.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _showActionSheet(events[i]),
        child: _buildListItemByTheme(events[i]),
      ),
    );
  }

  String _makeTimeString(CalendarEvent e) {
    final sD = e.date.substring(5).replaceAll('-', '.');
    final eD =
        e.endDate != null ? e.endDate!.substring(5).replaceAll('-', '.') : sD;
    final same = e.date == (e.endDate ?? e.date);
    if (e.isAllDay) return same ? '하루 종일' : '$sD ~ $eD';
    final sT = _formatHHmm(e.startTime ?? '00:00');
    final eT = _formatHHmm(e.endTime ?? '00:00');
    return same ? '$sT ~ $eT' : '$sD $sT ~ $eD $eT';
  }

  // ──────────────────────────────────────
  // 테마별 일정 카드
  // ──────────────────────────────────────
  Widget _buildListItemByTheme(CalendarEvent event) {
    final color =
        event.colorValue != null ? Color(event.colorValue!) : th.primaryAccent;
    final dateInfo = _makeTimeString(event);

    switch (_currentTheme) {
      // ── 애플 스타일: 왼쪽 컬러 바
      case AppTheme.apple:
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
              border: Border(
                  bottom:
                      BorderSide(color: Colors.grey.withValues(alpha: 0.1)))),
          child: Row(children: [
            Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: th.eventTitleText)),
                if (dateInfo.isNotEmpty)
                  Text(dateInfo,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )),
          ]),
        );

      // ── 삼성/네이버: 컬러 도트 카드
      case AppTheme.samsung:
      case AppTheme.naver:
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: th.cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)
            ],
          ),
          child: Row(children: [
            Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: _currentTheme == AppTheme.samsung
                      ? BoxShape.circle
                      : BoxShape.rectangle,
                  borderRadius: _currentTheme == AppTheme.naver
                      ? BorderRadius.circular(3)
                      : null,
                )),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: th.eventTitleText)),
                if (dateInfo.isNotEmpty)
                  Text(dateInfo,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )),
          ]),
        );

      // ── 투두 스카이: calendar3 스타일 (어두운 배경 + 흰 카드)
      case AppTheme.todoSky:
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: th.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(children: [
            // 컬러 원형 아이콘
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(Icons.event, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white)),
                if (dateInfo.isNotEmpty) const SizedBox(height: 2),
                if (dateInfo.isNotEmpty)
                  Text(dateInfo,
                      style: TextStyle(fontSize: 12, color: th.eventSubText)),
              ],
            )),
            // 진행상태 뱃지 (시간 있는 이벤트만)
            if (event.startTime != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_formatHHmm(event.startTime!),
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ]),
        );

      // ── 기본 (다크네온, 클래식블루): 체크 아이콘 카드
      default:
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: th.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: th.cardBorder),
          ),
          child: Row(children: [
            Icon(Icons.check_circle_outline, color: color),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: th.eventTitleText)),
                if (dateInfo.isNotEmpty)
                  Text(dateInfo,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            )),
          ]),
        );
    }
  }
}
