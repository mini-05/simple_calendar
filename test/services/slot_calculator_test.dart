// v4.3.6
// gemini_slot_calculator_test.dart
// test/services/slot_calculator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_calendar/models/models.dart';
// 💡 실제 SlotCalculator 파일의 경로로 수정해 주세요.
import 'package:simple_calendar/services/slot_calculator.dart';

void main() {
  group('SlotCalculator - 일정 겹침 방지(Tetris) 및 슬롯 배치 엔진 검증', () {
    // 테스트용 단일 일정 생성 헬퍼 함수
    CalendarEvent makeEvent(int id, String start, String end,
        {bool isAllDay = true}) {
      return CalendarEvent(
        id: id,
        title: 'Event $id',
        date: start,
        endDate: end,
        isAllDay: isAllDay,
      );
    }

    // [OCP & Dart 3.0 Records]: 다양한 겹침 시나리오
    final slotCases = [
      (
        description: '1. 전혀 겹치지 않는 일정들은 모두 최상단(Slot 0)을 재사용해야 한다',
        events: [
          makeEvent(1, '2026-03-01', '2026-03-01'), // 1일
          makeEvent(2, '2026-03-03', '2026-03-03'), // 3일
          makeEvent(3, '2026-03-05', '2026-03-06'), // 5~6일
        ],
        // 예상 슬롯: {이벤트ID: 슬롯번호}
        expectedSlots: {1: 0, 2: 0, 3: 0},
      ),
      (
        description: '2. 정확히 같은 날 겹치는 일정들은 순차적으로 슬롯(0, 1, 2)을 나눠 가져야 한다',
        events: [
          makeEvent(1, '2026-03-01', '2026-03-01'),
          makeEvent(2, '2026-03-01', '2026-03-01'),
          makeEvent(3, '2026-03-01', '2026-03-01'),
        ],
        expectedSlots: {1: 0, 2: 1, 3: 2}, // 입력 순서(혹은 정렬 기준)에 따라 배정됨
      ),
      (
        description: '3. 다중일(Multi-day) 일정과 단일일 일정이 겹치면 교차 배정되어야 한다 (Tetris)',
        events: [
          makeEvent(1, '2026-03-01', '2026-03-03'), // 1~3일 (Slot 0 선점)
          makeEvent(
              2, '2026-03-02', '2026-03-04'), // 2~4일 (1번과 2,3일 겹침 -> Slot 1)
          makeEvent(3, '2026-03-04',
              '2026-03-04'), // 4일 (2번과 겹침, 하지만 1번은 끝남 -> Slot 0 재사용)
        ],
        expectedSlots: {1: 0, 2: 1, 3: 0},
      ),
    ];

    for (final tc in slotCases) {
      test(tc.description, () {
        // 💡 SlotCalculator의 실제 호출 함수명으로 변경해 주세요. (예: assignSlots, getSlotMap 등)
        // 여기서는 Map<int, int> (Event ID -> Slot Index)를 반환한다고 가정합니다.
        final SlotCalculationResult slotMap = SlotCalculator.calculate(tc.events, DateTime.now(), {}, false, null);

        tc.expectedSlots.forEach((eventId, expectedSlot) {
          expect(slotMap[eventId], expectedSlot,
              reason:
                  '이벤트 $eventId 번의 슬롯 배치가 틀렸습니다. (기대값: $expectedSlot, 실제값: ${slotMap[eventId]})');
        });
      });
    }

    test('4. 정렬(Sorting) 우선순위 검증: 기간이 긴 다중일 일정이 짧은 일정보다 먼저 슬롯(0)을 차지해야 한다', () {
      final events = [
        makeEvent(1, '2026-03-02', '2026-03-02'), // 짧은 일정 (나중에 배정되어야 함)
        makeEvent(2, '2026-03-01', '2026-03-05'), // 긴 일정 (최우선 배정되어야 함)
      ];

      // 긴 일정인 2번이 Slot 0을 가져가고, 1번이 Slot 1로 밀려나야 달력 UI가 예쁘게 나옵니다.
      final slotMap =
          SlotCalculator.calculate(events, DateTime.now(), {}, true, null);

      expect(slotMap[2], 0, reason: '기간이 가장 긴 이벤트가 슬롯 0을 선점해야 합니다.');
      expect(slotMap[1], 1, reason: '짧은 이벤트는 긴 이벤트 아래로 밀려나야 합니다.');
    });
  });
}
