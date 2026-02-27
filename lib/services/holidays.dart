// v4.1.1
// gemini_holidays.dart
// lib/services/holidays.dart
import 'package:lunar/lunar.dart';
import '../models/models.dart';
import 'date_formatter.dart';

class HolidayUtil {
  static List<CalendarEvent> generateHolidaysForWindow(
      DateTime minDate, DateTime maxDate) {
    final holidays = <CalendarEvent>[];
    for (int y = minDate.year - 1; y <= maxDate.year + 1; y++) {
      holidays.addAll(_getSolarHolidays(y));
      holidays.addAll(_getLunarHolidays(y));
      // 대체공휴일은 solar+lunar가 모두 확정된 후 판단
      holidays.addAll(_getAlternativeHolidays(holidays, y));
    }
    return holidays
        .where(
            (h) => !h.startDt.isBefore(minDate) && !h.startDt.isAfter(maxDate))
        .toList();
  }

  static List<CalendarEvent> _getSolarHolidays(int year) {
    final list = <CalendarEvent>[];
    void add(int m, int d, String name) {
      final dt = DateTime(year, m, d);
      list.add(CalendarEvent(
        id: -dt.millisecondsSinceEpoch,
        title: name,
        date: DateFormatter.dateKey(dt),
        endDate: DateFormatter.dateKey(dt),
        isAllDay: true,
        colorValue: 0xFFFF3B30,
      ));
    }

    add(1, 1, '신정');
    add(3, 1, '삼일절');
    add(5, 5, '어린이날');
    add(6, 6, '현충일');
    add(8, 15, '광복절');
    add(10, 3, '개천절');
    add(10, 9, '한글날');
    add(12, 25, '크리스마스');
    return list;
  }

  static List<CalendarEvent> _getLunarHolidays(int year) {
    final list = <CalendarEvent>[];

    void addLunar(int m, int d, String name) {
      try {
        final lunar = Lunar.fromYmd(year, m, d);
        final solar = lunar.getSolar();
        final dt = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
        list.add(CalendarEvent(
          id: -(dt.millisecondsSinceEpoch + 100),
          title: name,
          date: DateFormatter.dateKey(dt),
          endDate: DateFormatter.dateKey(dt),
          isAllDay: true,
          colorValue: 0xFFFF3B30,
        ));
      } catch (_) {}
    }

    addLunar(4, 8, '부처님오신날');

    try {
      final seollalLunar = Lunar.fromYmd(year, 1, 1);
      final seollalSolar = seollalLunar.getSolar();
      final dt = DateTime(seollalSolar.getYear(), seollalSolar.getMonth(),
          seollalSolar.getDay());
      _addDirect(list, dt.subtract(const Duration(days: 1)), '설날 연휴');
      _addDirect(list, dt, '설날');
      _addDirect(list, dt.add(const Duration(days: 1)), '설날 연휴');
    } catch (_) {}

    try {
      final chuseokLunar = Lunar.fromYmd(year, 8, 15);
      final chuseokSolar = chuseokLunar.getSolar();
      final dt = DateTime(chuseokSolar.getYear(), chuseokSolar.getMonth(),
          chuseokSolar.getDay());
      _addDirect(list, dt.subtract(const Duration(days: 1)), '추석 연휴');
      _addDirect(list, dt, '추석');
      _addDirect(list, dt.add(const Duration(days: 1)), '추석 연휴');
    } catch (_) {}

    return list;
  }

  static void _addDirect(List<CalendarEvent> list, DateTime dt, String name) {
    list.add(CalendarEvent(
      id: -(dt.millisecondsSinceEpoch + name.hashCode),
      title: name,
      date: DateFormatter.dateKey(dt),
      endDate: DateFormatter.dateKey(dt),
      isAllDay: true,
      colorValue: 0xFFFF3B30,
    ));
  }

  static List<CalendarEvent> _getAlternativeHolidays(
      List<CalendarEvent> current, int year) {
    final result = <CalendarEvent>[];
    final occupiedDates = current.map((h) => h.date).toSet();

    const singleHolidayNames = {
      '신정',
      '삼일절',
      '어린이날',
      '현충일',
      '광복절',
      '개천절',
      '한글날',
      '크리스마스',
      '부처님오신날',
    };

    const seollalNames = {'설날 연휴', '설날'};
    const chuseokNames = {'추석 연휴', '추석'};

    void addAlt(DateTime dt, String label) {
      var candidate = dt;
      while (occupiedDates.contains(DateFormatter.dateKey(candidate)) ||
          candidate.weekday == DateTime.saturday ||
          candidate.weekday == DateTime.sunday) {
        candidate = candidate.add(const Duration(days: 1));
      }
      final key = DateFormatter.dateKey(candidate);
      if (!occupiedDates.contains(key)) {
        occupiedDates.add(key);
        result.add(CalendarEvent(
          id: -(candidate.millisecondsSinceEpoch + label.hashCode + 999),
          title: label,
          date: key,
          endDate: key,
          isAllDay: true,
          colorValue: 0xFFFF3B30,
        ));
      }
    }

    // 1. 단일 공휴일 대체 로직
    for (final h in current) {
      if (!singleHolidayNames.contains(h.title)) continue;
      final dt = h.startDt;
      if (dt.year != year) continue;
      if (dt.weekday == DateTime.sunday) {
        addAlt(dt.add(const Duration(days: 1)), '${h.title} 대체공휴일');
      }
    }

    // 2. 명절 연휴 대체 로직
    _processHolidayGroup(
        current, seollalNames, year, '설날 대체공휴일', result, addAlt);
    _processHolidayGroup(
        current, chuseokNames, year, '추석 대체공휴일', result, addAlt);

    return result;
  }

  static void _processHolidayGroup(
    List<CalendarEvent> current,
    Set<String> groupNames,
    int year,
    String altLabel,
    List<CalendarEvent> result,
    void Function(DateTime, String) addAlt,
  ) {
    final groupEvents = current
        .where((h) => groupNames.contains(h.title) && h.startDt.year == year)
        .toList();

    if (groupEvents.isEmpty) return;

    final groupDays = groupEvents.map((h) => h.startDt).toList()..sort();
    final afterLast = groupDays.last.add(const Duration(days: 1));

    int altCount = 0;
    for (final d in groupDays) {
      // 자신 그룹 제외한 '다른 공휴일'과 겹치는지 체크
      bool overlapOtherHoliday = false;
      for (final other in current) {
        if (!groupNames.contains(other.title) &&
            other.date == DateFormatter.dateKey(d)) {
          overlapOtherHoliday = true;
          break;
        }
      }

      if (d.weekday == DateTime.sunday || overlapOtherHoliday) {
        altCount++;
      }
    }

    // 찾아낸 겹침 횟수만큼 연휴 직후로 대체공휴일 생성 (addAlt가 빈자리 자동 계산)
    for (int i = 0; i < altCount; i++) {
      addAlt(afterLast, altLabel);
    }
  }
}
