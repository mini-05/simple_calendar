// v4.4.8
// claude_slot_calculator.dart
// lib/services/slot_calculator.dart
// ignore_for_file: curly_braces_in_flow_control_structures
// [v4.4.8] 아무도 읽지 않던 windowEvents 필드 제거.
//   결과 객체가 24개월 창의 전체 이벤트 목록(공휴일 포함)을 상태 수명 내내
//   붙잡고 있을 이유가 없다. 계산 중 쓰이는 지역 변수는 그대로 유지된다.
//   (operator []는 단위 테스트가 사용하므로 유지)
import '../models/models.dart';
import 'date_formatter.dart';

class SlotCalculationResult {
  final Map<String, List<CalendarEvent>> eventsByDate;
  final Map<int, int> slotMap;

  SlotCalculationResult(this.eventsByDate, this.slotMap);

  int? operator [](int eventId) => slotMap[eventId];
}

class SlotCalculator {
  static SlotCalculationResult calculate(
      List<CalendarEvent> allEvents,
      DateTime windowCenter,
      Map<int, int> existingSlotMap,
      bool isFirstLoad,
      List<CalendarEvent>? holidays) {
    final minDate = DateTime(windowCenter.year, windowCenter.month - 12, 1);
    final maxDate = DateTime(windowCenter.year, windowCenter.month + 13, 0);

    final windowEvents = allEvents
        .where((e) => !e.endDt.isBefore(minDate) && !e.startDt.isAfter(maxDate))
        .toList();

    if (holidays != null) {
      windowEvents.addAll(holidays);
    }

    windowEvents.sort((a, b) {
      final aDays = a.endDt.difference(a.startDt).inDays;
      final bDays = b.endDt.difference(b.startDt).inDays;
      if (aDays != bDays) {
        return bDays.compareTo(aDays);
      }
      final dc = a.date.compareTo(b.date);
      if (dc != 0) {
        return dc;
      }
      if (a.isAllDay != b.isAllDay) {
        return a.isAllDay ? -1 : 1;
      }
      if (!a.isAllDay) {
        final tc = (a.startTime ?? '00:00').compareTo(b.startTime ?? '00:00');
        if (tc != 0) {
          return tc;
        }
      }
      return a.title.compareTo(b.title);
    });

    final newSlotMap = <int, int>{};
    final dateSlots = <String, Set<int>>{};

    for (final e in windowEvents) {
      if (!isFirstLoad && existingSlotMap.containsKey(e.id)) {
        final slot = existingSlotMap[e.id]!;
        newSlotMap[e.id] = slot;
        _forEachDayInWindow(e, minDate, maxDate, (key) {
          (dateSlots[key] ??= {}).add(slot);
        });
        continue;
      }

      final occupied = <int>{};
      _forEachDayInWindow(e, minDate, maxDate, (key) {
        occupied.addAll(dateSlots[key] ?? {});
      });

      int slot = 0;
      while (occupied.contains(slot)) {
        slot++;
      }
      newSlotMap[e.id] = slot;

      _forEachDayInWindow(e, minDate, maxDate, (key) {
        (dateSlots[key] ??= {}).add(slot);
      });
    }

    final map = <String, List<CalendarEvent>>{};
    for (final e in windowEvents) {
      _forEachDayInWindow(e, minDate, maxDate, (key) {
        (map[key] ??= []).add(e);
      });
    }
    for (final key in map.keys) {
      map[key]!.sort(
          (a, b) => (newSlotMap[a.id] ?? 0).compareTo(newSlotMap[b.id] ?? 0));
    }

    return SlotCalculationResult(map, newSlotMap);
  }

  static void _forEachDayInWindow(CalendarEvent e, DateTime minD, DateTime maxD,
      void Function(String key) cb) {
    DateTime cur = e.startDt.isBefore(minD)
        ? minD
        : DateTime(e.startDt.year, e.startDt.month, e.startDt.day);
    final end = e.endDt.isAfter(maxD)
        ? maxD
        : DateTime(e.endDt.year, e.endDt.month, e.endDt.day);
    while (!cur.isAfter(end)) {
      cb(DateFormatter.dateKey(cur));
      cur = cur.add(const Duration(days: 1));
    }
  }
}
