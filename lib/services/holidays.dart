// v4.1.0
// holidays.dart
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
        // 💡 isHoliday: true 제거 완료 (자동 판별됨)
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
    add(12, 25, '기독탄신일');
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
          // 💡 isHoliday: true 제거 완료
          colorValue: 0xFFFF3B30,
        ));
      } catch (_) {}
    }

    // 부처님오신날
    addLunar(4, 8, '부처님오신날');

    // 설날 연휴 처리 (전날, 당일, 다음날)
    try {
      final seollalLunar = Lunar.fromYmd(year, 1, 1);
      final seollalSolar = seollalLunar.getSolar();
      final dt = DateTime(seollalSolar.getYear(), seollalSolar.getMonth(),
          seollalSolar.getDay());

      final dtBefore = dt.subtract(const Duration(days: 1));
      final dtAfter = dt.add(const Duration(days: 1));

      _addDirect(list, dtBefore, '설날 연휴');
      _addDirect(list, dt, '설날');
      _addDirect(list, dtAfter, '설날 연휴');
    } catch (_) {}

    // 추석 연휴 처리 (전날, 당일, 다음날)
    try {
      final chuseokLunar = Lunar.fromYmd(year, 8, 15);
      final chuseokSolar = chuseokLunar.getSolar();
      final dt = DateTime(chuseokSolar.getYear(), chuseokSolar.getMonth(),
          chuseokSolar.getDay());

      final dtBefore = dt.subtract(const Duration(days: 1));
      final dtAfter = dt.add(const Duration(days: 1));

      _addDirect(list, dtBefore, '추석 연휴');
      _addDirect(list, dt, '추석');
      _addDirect(list, dtAfter, '추석 연휴');
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
      // 💡 isHoliday: true 제거 완료
      colorValue: 0xFFFF3B30,
    ));
  }

  static List<CalendarEvent> _getAlternativeHolidays(
      List<CalendarEvent> current, int year) {
    return []; // 간단화를 위해 임시 비활성화 (필요시 대체공휴일 로직 추가 가능)
  }
}
