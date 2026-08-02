// v4.4.4
// claude_holidays.dart
// lib/services/holidays.dart
// [v4.4.1] 대체공휴일 명칭 통일 → '대체공휴일'
// [v4.4.4] 대체공휴일 로직 법령 준거 수정 (「관공서의 공휴일에 관한 규정」 제3조)
//   - 국경일/어린이날/부처님오신날/크리스마스: 토요일·일요일 겹침 모두 대체공휴일 발생 (기존 일요일만 처리 버그)
//   - 신정·현충일: 대체공휴일 대상에서 제외 (법 제3조①1호 목록에 미포함)
//   - 단일 공휴일이 평일에 다른 공휴일과 겹치는 경우도 대체공휴일 발생 (법 제3조①3호, 예: 2025 어린이날·부처님오신날)
// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:lunar/lunar.dart';
import '../models/models.dart';
import 'date_formatter.dart';

class HolidayUtil {
  // [v4.4.8] 공휴일 이름/색을 상수로 승격.
  //   이름: 생성부(_getSolarHolidays 등)와 대체공휴일 판정부(_getAlternativeHolidays)가
  //   같은 리터럴을 각자 적어두고 있어, 한쪽만 고치면 조용히 어긋났다.
  //   색: 서비스 안에 네 번 하드코딩되어 있던 표시용 상수.
  static const _colorHoliday = 0xFFFF3B30;

  static const _newYear = '신정';
  static const _samil = '삼일절';
  static const _children = '어린이날';
  static const _memorial = '현충일';
  static const _liberation = '광복절';
  static const _foundation = '개천절';
  static const _hangul = '한글날';
  static const _christmas = '크리스마스';
  static const _buddha = '부처님오신날';
  static const _seollal = '설날';
  static const _seollalEve = '설날 연휴';
  static const _chuseok = '추석';
  static const _chuseokEve = '추석 연휴';
  static const _substitute = '대체공휴일';

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
        colorValue: _colorHoliday,
      ));
    }

    add(1, 1, _newYear);
    add(3, 1, _samil);
    add(5, 5, _children);
    add(6, 6, _memorial);
    add(8, 15, _liberation);
    add(10, 3, _foundation);
    add(10, 9, _hangul);
    add(12, 25, _christmas);
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
          colorValue: _colorHoliday,
        ));
      } catch (_) {}
    }

    addLunar(4, 8, _buddha);

    try {
      final seollalLunar = Lunar.fromYmd(year, 1, 1);
      final seollalSolar = seollalLunar.getSolar();
      final dt = DateTime(seollalSolar.getYear(), seollalSolar.getMonth(),
          seollalSolar.getDay());
      _addDirect(list, dt.subtract(const Duration(days: 1)), _seollalEve);
      _addDirect(list, dt, _seollal);
      _addDirect(list, dt.add(const Duration(days: 1)), _seollalEve);
    } catch (_) {}

    try {
      final chuseokLunar = Lunar.fromYmd(year, 8, 15);
      final chuseokSolar = chuseokLunar.getSolar();
      final dt = DateTime(chuseokSolar.getYear(), chuseokSolar.getMonth(),
          chuseokSolar.getDay());
      _addDirect(list, dt.subtract(const Duration(days: 1)), _chuseokEve);
      _addDirect(list, dt, _chuseok);
      _addDirect(list, dt.add(const Duration(days: 1)), _chuseokEve);
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
      colorValue: _colorHoliday,
    ));
  }

  static List<CalendarEvent> _getAlternativeHolidays(
      List<CalendarEvent> current, int year) {
    final result = <CalendarEvent>[];
    final occupiedDates = current.map((h) => h.date).toSet();

    // 법 제3조①1호·3호 대상 단일 공휴일 (신정·현충일은 대상 아님)
    const singleHolidayNames = {
      _samil,
      _children,
      _liberation,
      _foundation,
      _hangul,
      _christmas,
      _buddha,
    };

    const seollalNames = {_seollalEve, _seollal};
    const chuseokNames = {_chuseokEve, _chuseok};

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
          colorValue: _colorHoliday,
        ));
      }
    }

    // 날짜별 공휴일 개수 (평일 겹침 판정용)
    final dateCount = <String, int>{};
    for (final h in current) {
      dateCount[h.date] = (dateCount[h.date] ?? 0) + 1;
    }

    // 1. 단일 공휴일 대체 로직 (법 제3조①1호: 토·일 겹침 / 3호: 평일 다른 공휴일과 겹침)
    final processedDates = <String>{};
    for (final h in current) {
      if (!singleHolidayNames.contains(h.title)) continue;
      final dt = h.startDt;
      if (dt.year != year) continue;
      if (processedDates.contains(h.date)) continue; // 같은 날 중복 처리 방지
      processedDates.add(h.date);

      final isWeekend = dt.weekday == DateTime.saturday ||
          dt.weekday == DateTime.sunday;
      final overlapsOtherHoliday = (dateCount[h.date] ?? 0) > 1;

      if (isWeekend || overlapsOtherHoliday) {
        addAlt(dt.add(const Duration(days: 1)), _substitute);
      }
    }

    // 2. 명절 연휴 대체 로직
    _processHolidayGroup(current, seollalNames, year, _substitute, result, addAlt);
    _processHolidayGroup(current, chuseokNames, year, _substitute, result, addAlt);

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
      // (dateKey는 바깥 루프에서 한 번만 만든다 — 예전에는 current를 훑는
      //  안쪽 루프마다 같은 문자열을 다시 만들고 있었다)
      final dKey = DateFormatter.dateKey(d);
      bool overlapOtherHoliday = false;
      for (final other in current) {
        if (!groupNames.contains(other.title) && other.date == dKey) {
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
