// ignore_for_file: curly_braces_in_flow_control_structures
// v3.6.0
import 'package:lunar/lunar.dart';
import '../models/models.dart';
import 'date_formatter.dart';

/// 공휴일 ID를 안전하게 음수로 생성하기 위한 제네레이터
class IdGenerator {
  int _currentId = -10000;
  int get nextId {
    return _currentId--;
  }
}

/// [OCP 인터페이스] 새로운 공휴일 규칙이 생기면 이 인터페이스만 구현하면 됩니다.
abstract class HolidayProvider {
  void provide(DateTime start, DateTime end, Map<String, String> holidaysMap,
      List<CalendarEvent> events, IdGenerator idGen);
}

/// 1. 양력 고정 공휴일 제공자
class SolarHolidayProvider implements HolidayProvider {
  final Map<String, String> _solarHolidays = {
    '01-01': '신정',
    '03-01': '삼일절',
    '05-05': '어린이날',
    '06-06': '현충일',
    '08-15': '광복절',
    '10-03': '개천절',
    '10-09': '한글날',
    '12-25': '크리스마스',
  };

  @override
  void provide(DateTime start, DateTime end, Map<String, String> holidaysMap,
      List<CalendarEvent> events, IdGenerator idGen) {
    DateTime cur = start;
    while (!cur.isAfter(end)) {
      final mmdd =
          '${cur.month.toString().padLeft(2, '0')}-${cur.day.toString().padLeft(2, '0')}';
      final name = _solarHolidays[mmdd];
      if (name != null) {
        final dateKey = DateFormatter.dateKey(cur);
        holidaysMap[dateKey] = name;
        events.add(CalendarEvent(
          id: idGen.nextId,
          title: name,
          date: dateKey,
          isAllDay: true,
          colorValue: 0xFFE53935,
          isAlarmOn: false,
        ));
      }
      cur = cur.add(const Duration(days: 1));
    }
  }
}

/// 2. 음력 연휴 제공자 (설날, 추석, 부처님오신날)
class LunarHolidayProvider implements HolidayProvider {
  @override
  void provide(DateTime start, DateTime end, Map<String, String> holidaysMap,
      List<CalendarEvent> events, IdGenerator idGen) {
    DateTime cur = start;
    while (!cur.isAfter(end)) {
      try {
        final lunar = Lunar.fromDate(cur);
        final lMonth = lunar.getMonth();
        final lDay = lunar.getDay();

        // 설날 연휴 (3일 연속 블록)
        if (lMonth == 1 && lDay == 1) {
          final dayBefore = cur.subtract(const Duration(days: 1));
          final dayAfter = cur.add(const Duration(days: 1));

          holidaysMap[DateFormatter.dateKey(dayBefore)] = '설날';
          holidaysMap[DateFormatter.dateKey(cur)] = '설날';
          holidaysMap[DateFormatter.dateKey(dayAfter)] = '설날';

          events.add(CalendarEvent(
            id: idGen.nextId,
            title: '설날',
            date: DateFormatter.dateKey(dayBefore),
            endDate: DateFormatter.dateKey(dayAfter),
            isAllDay: true,
            colorValue: 0xFFE53935,
            isAlarmOn: false,
          ));
        }

        // 추석 연휴 (3일 연속 블록)
        if (lMonth == 8 && lDay == 15) {
          final dayBefore = cur.subtract(const Duration(days: 1));
          final dayAfter = cur.add(const Duration(days: 1));

          holidaysMap[DateFormatter.dateKey(dayBefore)] = '추석';
          holidaysMap[DateFormatter.dateKey(cur)] = '추석';
          holidaysMap[DateFormatter.dateKey(dayAfter)] = '추석';

          events.add(CalendarEvent(
            id: idGen.nextId,
            title: '추석',
            date: DateFormatter.dateKey(dayBefore),
            endDate: DateFormatter.dateKey(dayAfter),
            isAllDay: true,
            colorValue: 0xFFE53935,
            isAlarmOn: false,
          ));
        }

        // 부처님오신날
        if (lMonth == 4 && lDay == 8) {
          final dateKey = DateFormatter.dateKey(cur);
          holidaysMap[dateKey] = '부처님오신날';
          events.add(CalendarEvent(
            id: idGen.nextId,
            title: '부처님오신날',
            date: dateKey,
            isAllDay: true,
            colorValue: 0xFFE53935,
            isAlarmOn: false,
          ));
        }
      } catch (_) {}
      cur = cur.add(const Duration(days: 1));
    }
  }
}

/// 3. 대체공휴일 제공자 (2023년 개정안 적용)
class SubstituteHolidayProvider implements HolidayProvider {
  @override
  void provide(DateTime start, DateTime end, Map<String, String> holidaysMap,
      List<CalendarEvent> events, IdGenerator idGen) {
    DateTime cur = start;
    while (!cur.isAfter(end)) {
      final key = DateFormatter.dateKey(cur);
      final name = holidaysMap[key];

      if (name != null) {
        bool needsSubstitute = false;

        // 설날, 추석은 일요일에만 대체공휴일 부여
        if (name.contains('설날') || name.contains('추석')) {
          if (cur.weekday == DateTime.sunday) {
            needsSubstitute = true;
          }
        }
        // 기타 지정 공휴일은 토/일요일에 대체공휴일 부여
        else if (['삼일절', '어린이날', '광복절', '개천절', '한글날', '부처님오신날', '크리스마스']
            .contains(name)) {
          if (cur.weekday == DateTime.saturday ||
              cur.weekday == DateTime.sunday) {
            needsSubstitute = true;
          }
        }

        if (needsSubstitute) {
          DateTime subDate = cur.add(const Duration(days: 1));
          while (true) {
            final subKey = DateFormatter.dateKey(subDate);
            if (subDate.weekday != DateTime.saturday &&
                subDate.weekday != DateTime.sunday &&
                !holidaysMap.containsKey(subKey)) {
              holidaysMap[subKey] = '대체공휴일';
              events.add(CalendarEvent(
                id: idGen.nextId,
                title: '대체공휴일',
                date: subKey,
                isAllDay: true,
                colorValue: 0xFFE53935,
                isAlarmOn: false,
              ));
              break;
            }
            subDate = subDate.add(const Duration(days: 1));
          }
        }
      }
      cur = cur.add(const Duration(days: 1));
    }
  }
}

/// 외부에서 접근하는 파사드(Facade) 역할의 실행부
class HolidayUtil {
  // 💡 [OCP 핵심] 새로운 로직이 추가되면 기존 클래스 수정 없이 여기에 인스턴스만 추가하면 됩니다.
  static final List<HolidayProvider> _baseProviders = [
    SolarHolidayProvider(),
    LunarHolidayProvider(),
  ];

  static final List<HolidayProvider> _substituteProviders = [
    SubstituteHolidayProvider(),
  ];

  static List<CalendarEvent> generateHolidaysForWindow(
      DateTime minDate, DateTime maxDate) {
    DateTime start = minDate.subtract(const Duration(days: 10));
    DateTime end = maxDate.add(const Duration(days: 10));

    Map<String, String> holidaysMap = {};
    List<CalendarEvent> allGeneratedEvents = [];
    IdGenerator idGen = IdGenerator();

    // 1단계: 기본 공휴일 주입
    for (var provider in _baseProviders) {
      provider.provide(start, end, holidaysMap, allGeneratedEvents, idGen);
    }

    // 2단계: 대체공휴일 주입 (기본 공휴일을 바탕으로 계산)
    for (var provider in _substituteProviders) {
      provider.provide(start, end, holidaysMap, allGeneratedEvents, idGen);
    }

    // 뷰포트 바깥의 데이터 필터링 후 반환
    return allGeneratedEvents
        .where((e) => !e.endDt.isBefore(minDate) && !e.startDt.isAfter(maxDate))
        .toList();
  }
}
