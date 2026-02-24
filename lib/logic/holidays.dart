// ignore_for_file: curly_braces_in_flow_control_structures
// v3.6.2
import 'package:lunar/lunar.dart';
import '../models/models.dart';
import 'date_formatter.dart';

class IdGenerator {
  int _currentId = -10000;
  int get nextId {
    return _currentId--;
  }
}

abstract class HolidayProvider {
  void provide(DateTime start, DateTime end, Map<String, String> holidaysMap,
      List<CalendarEvent> events, IdGenerator idGen);
}

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

        if (name.contains('설날') || name.contains('추석')) {
          if (cur.weekday == DateTime.sunday) {
            needsSubstitute = true;
          }
        } else if (['삼일절', '어린이날', '광복절', '개천절', '한글날', '부처님오신날', '크리스마스']
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

class HolidayUtil {
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

    for (var provider in _baseProviders) {
      provider.provide(start, end, holidaysMap, allGeneratedEvents, idGen);
    }

    for (var provider in _substituteProviders) {
      provider.provide(start, end, holidaysMap, allGeneratedEvents, idGen);
    }

    return allGeneratedEvents
        .where((e) => !e.endDt.isBefore(minDate) && !e.startDt.isAfter(maxDate))
        .toList();
  }
}
