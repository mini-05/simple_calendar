// v4.3.6
// gemini_models_test.dart
// test/models/models_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_calendar/models/models.dart';

void main() {
  group('RecurrenceRule - OCP 기반 반복 일정 확장 (expand)', () {
    final currentYear = DateTime.now().year;
    final isLeapYear = (currentYear % 4 == 0 && currentYear % 100 != 0) ||
        (currentYear % 400 == 0);
    final daysInYear = isLeapYear ? 366 : 365;

    final start200Years = DateTime(currentYear, 1, 1);
    final end200Years = DateTime(currentYear + 200, 1, 1);
    final exactDaysFor200Years =
        end200Years.difference(start200Years).inDays + 1;

    // 💡 [개선] Dart 3.0 Records 적용: 불필요한 클래스 선언 없이 데이터만 직관적으로 묶음
    final recurrenceCases = [
      (
        description:
            '매일(Daily) 반복 시 종료일을 1년 뒤로 잡으면, 일정도 1년 치(365/366개)가 누락 없이 생성되어야 한다',
        start: DateTime(currentYear, 1, 1),
        rule: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            interval: 1,
            until: DateTime(currentYear, 12, 31)),
        limit: 1000,
        expectedLength: daysInYear,
        expectedLast: DateTime(currentYear, 12, 31),
      ),
      (
        description:
            '매일(Daily) 반복 시 200년 뒤를 종료일로 잡고 limit을 충분히 주면, 7만3천여 개의 일정이 정확히 생성되어야 한다',
        start: start200Years,
        rule: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            interval: 1,
            until: end200Years),
        limit: 100000,
        expectedLength: exactDaysFor200Years,
        expectedLast: end200Years,
      ),
      (
        description: '종료일이 200년 뒤라도 limit을 1로 주면, 정확히 시작일 하루(1개)만 생성하고 멈춰야 한다',
        start: start200Years,
        rule: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            interval: 1,
            until: end200Years),
        limit: 1,
        expectedLength: 1,
        expectedLast: start200Years,
      ),
      (
        description: '종료일이 1년 뒤라도 limit을 3으로 주면, 정확히 3일 치만 생성하고 멈춰야 한다',
        start: DateTime(currentYear, 1, 1),
        rule: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            interval: 1,
            until: DateTime(currentYear, 12, 31)),
        limit: 3,
        expectedLength: 3,
        expectedLast: DateTime(currentYear, 1, 3),
      ),
      (
        description: '매주(Weekly) 반복 시 정확히 7일 간격으로 생성되어야 한다',
        start: DateTime(currentYear, 1, 1),
        rule: RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            interval: 1,
            until: DateTime(currentYear, 1, 15)),
        limit: 100,
        expectedLength: 3,
        expectedLast: DateTime(currentYear, 1, 15),
      ),
      (
        description: '매년(Yearly) 반복 시 정확히 1년 단위로 날짜가 점프해야 한다',
        start: DateTime(currentYear, 1, 1),
        rule: RecurrenceRule(
            frequency: RecurrenceFrequency.yearly,
            interval: 1,
            until: DateTime(currentYear + 2, 1, 1)),
        limit: 100,
        expectedLength: 3,
        expectedLast: DateTime(currentYear + 2, 1, 1),
      ),
    ];

    for (final tc in recurrenceCases) {
      test(tc.description, () {
        // tc.변수명 으로 레코드 데이터에 직접 접근
        final result = tc.rule.expand(tc.start, limit: tc.limit);
        expect(result.length, tc.expectedLength, reason: '생성된 일정 개수가 다릅니다.');
        expect(result.first, tc.start, reason: '시작일이 일치하지 않습니다.');
        expect(result.last, tc.expectedLast, reason: '마지막 일정 날짜가 일치하지 않습니다.');
      });
    }
  });

  group('CalendarEvent - OCP 기반 직렬화/역직렬화 10종 완벽 검증', () {
    final eventCases = [
      CalendarEvent(
          id: 1, title: '1. 기본 종일 일정', date: '2026-02-28', isAllDay: true),
      CalendarEvent(
          id: 2,
          title: '2. 시간 지정 일정',
          date: '2026-02-28',
          endDate: '2026-02-28 14:00',
          isAllDay: false),
      CalendarEvent(
          id: 3,
          title: '3. 다중일(Multi-day) 일정',
          date: '2026-02-28',
          endDate: '2026-03-02',
          isAllDay: true),
      CalendarEvent(
          id: -1,
          title: '4. 시스템 공휴일 (음수 ID)',
          date: '2026-03-01',
          isAllDay: true),
      CalendarEvent(
          id: 5,
          title: '5. 소리+진동 복합 알람',
          date: '2026-02-28',
          isAllDay: false,
          eventAlarmMode: AlarmMode.soundAndVibration,
          soundOption: NotificationSound.bird),
      CalendarEvent(
          id: 6,
          title: '6. 무음(Silent) 모드 알람',
          date: '2026-02-28',
          isAllDay: false,
          eventAlarmMode: AlarmMode.silent),
      CalendarEvent(
          id: 7,
          title: '7. 외부 커스텀 사운드 적용',
          date: '2026-02-28',
          isAllDay: false,
          eventAlarmMode: AlarmMode.soundOnly,
          customSoundPath: '/storage/emulated/0/Music/custom.mp3'),
      CalendarEvent(
          id: 8,
          title: '8. 무한 매일 반복 일정',
          date: '2026-02-28',
          isAllDay: true,
          recurrenceRule: const RecurrenceRule(
              frequency: RecurrenceFrequency.daily, interval: 1)),
      CalendarEvent(
          id: 9,
          title: '9. 종료일이 있는 매주 반복 일정',
          date: '2026-02-28',
          isAllDay: false,
          recurrenceRule: RecurrenceRule(
              frequency: RecurrenceFrequency.weekly,
              interval: 1,
              until: DateTime(2026, 12, 31))),
      CalendarEvent(
          id: 10,
          title: '10. 모든 속성 풀세팅 일정',
          date: '2026-02-28',
          endDate: '2026-02-28 18:00',
          isAllDay: false,
          eventAlarmMode: AlarmMode.vibrationOnly,
          recurrenceRule: const RecurrenceRule(
              frequency: RecurrenceFrequency.monthly, interval: 1)),
    ];

    for (var i = 0; i < eventCases.length; i++) {
      test('CalendarEvent 케이스 ${i + 1} 변환 무결성 검증', () {
        final original = eventCases[i];
        expect(CalendarEvent.fromJson(original.toJson()).toJson(),
            original.toJson());
      });
    }
  });
}
