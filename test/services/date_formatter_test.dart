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
    });
  });

  group('DateFormatter - 한국어 포맷 (formatDateKorean)', () {
    test('YYYY년 M월 D일 (요일) 형태 반환', () {
      expect(DateFormatter.formatDateKorean(DateTime(2026, 2, 28)),
          '2026년 2월 28일 (토)');
    });
  });

  group('DateFormatter - 시간 포맷 (formatHHmm)', () {
    test('오전/오후 포맷 반환', () {
      expect(DateFormatter.formatHHmm('09:05'), '오전 9:05');
      expect(DateFormatter.formatHHmm('00:00'), '오전 12:00');
      expect(DateFormatter.formatHHmm('13:30'), '오후 1:30');
    });
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
    test('검색용 초성 변환', () {
      expect(DateFormatter.getChosung('회의'), 'ㅎㅇ');
      expect(DateFormatter.getChosung('점심 식사'), 'ㅈㅅ ㅅㅅ');
    });
  });

  // 💡 [에러 해결 및 S10 오버플로우 테스트]
  group('DateFormatter - S10 UI 오버플로우 방지 (getLunarLabel)', () {
    test('음력 텍스트 반환 시 공백 없는 압축 형태를 보장해야 한다', () {
      // 2026년 2월 26일 = 음력 1월 10일
      final label1 = DateFormatter.getLunarLabel(DateTime(2026, 2, 26), true);
      expect(label1, '음1.10');

      // 2026년 4월 11일 = 음력 2월 24일 (S10 등에서 '음 2.24'로 공백이 있으면 잘림)
      final label2 = DateFormatter.getLunarLabel(DateTime(2026, 4, 11), true);
      expect(label2, '음2.24');

      // unchecked_use_of_nullable_value 에러 픽스 (! 추가)
      expect(label2!.contains(' '), false,
          reason: '작은 화면 UI 오버플로우를 막기 위해 공백이 없어야 합니다.');

      // showLunar가 false일 때
      final labelNull =
          DateFormatter.getLunarLabel(DateTime(2026, 4, 11), false);
      expect(labelNull, null);
    });
  });
}
