// v4.3.6
// gemini_date_formatter_test.dart
// test/services/date_formatter_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_calendar/models/models.dart';
import 'package:simple_calendar/services/date_formatter.dart';

void main() {
  group('DateFormatter - 날짜 키 (dateKey)', () {
    test('yyyy-MM-dd 형태 반환', () {
      expect(DateFormatter.dateKey(DateTime(2025, 2, 3)), '2025-02-03');
      expect(DateFormatter.dateKey(DateTime(2026, 12, 25)), '2026-12-25');
    });
  });

  group('DateFormatter - 한국어 포맷 (formatDateKorean)', () {
    test('YYYY년 M월 D일 (요일) 형태 반환', () {
      expect(DateFormatter.formatDateKorean(DateTime(2026, 2, 28)),
          '2026년 2월 28일 (토)');
    });
  });

  group('DateFormatter - 시간 포맷 (formatHHmm)', () {
    // 💡 Dart 3.0 레코드 (input, expected) 구조 적용
    final timeCases = [
      (input: '00:00', expected: '오전 12:00'),
      (input: '09:05', expected: '오전 9:05'),
      (input: '11:59', expected: '오전 11:59'),
      (input: '12:00', expected: '오후 12:00'),
      (input: '13:30', expected: '오후 1:30'),
      (input: '23:59', expected: '오후 11:59'),
    ];

    for (final tc in timeCases) {
      test('입력값 "${tc.input}"은(는) "${tc.expected}"로 변환되어야 한다', () {
        expect(DateFormatter.formatHHmm(tc.input), tc.expected);
      });
    }
  });

  group('DateFormatter - 시간 문자열 조합 (makeTimeString)', () {
    test('종일 일정 및 다중일 시간 표시 검증', () {
      final e1 =
          CalendarEvent(id: 1, title: 'A', date: '2026-02-28', isAllDay: true);
      expect(DateFormatter.makeTimeString(e1), '하루 종일');

      final e2 = CalendarEvent(
          id: 2,
          title: 'B',
          date: '2026-02-28',
          startTime: '09:00',
          endTime: '10:00');
      expect(DateFormatter.makeTimeString(e2), '오전 9:00 ~ 오전 10:00');
    });
  });

  group('DateFormatter - 한글 초성 추출 (getChosung)', () {
    // 💡 Dart 3.0 레코드 (input, expected) 구조 적용
    final chosungCases = [
      (input: '회의', expected: 'ㅎㅇ'),
      (input: '점심 식사', expected: 'ㅈㅅ ㅅㅅ'),
      (input: '팀 미팅 123', expected: 'ㅌ ㅁㅌ 123'),
      (input: 'Apple', expected: 'Apple'),
      (input: '', expected: ''),
    ];

    for (final tc in chosungCases) {
      test('입력값 "${tc.input}"의 초성은 "${tc.expected}"이어야 한다', () {
        expect(DateFormatter.getChosung(tc.input), tc.expected);
      });
    }
  });

  group('DateFormatter - S10 UI 오버플로우 방지 (getLunarLabel)', () {
    test('음력 텍스트 반환 시 공백 없는 압축 형태를 보장해야 한다', () {
      final label1 = DateFormatter.getLunarLabel(DateTime(2026, 2, 26), true);
      expect(label1, '음1.10');

      final label2 = DateFormatter.getLunarLabel(DateTime(2026, 4, 11), true);
      expect(label2, '음2.24');

      // null-check 에러 방지를 위해 느낌표(!) 사용
      expect(label2!.contains(' '), false,
          reason: '작은 화면 UI 오버플로우를 막기 위해 공백이 없어야 합니다.');

      final labelNull =
          DateFormatter.getLunarLabel(DateTime(2026, 4, 11), false);
      expect(labelNull, null);
    });
  });
}
