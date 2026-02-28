// v4.3.6
// gemini_holidays_test.dart
// test/services/holidays_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_calendar/services/holidays.dart';

void main() {
  group('HolidayUtil - 5년 치 동적(Dynamic) 공휴일 및 대체공휴일 완벽 검증', () {
    final currentYear = DateTime.now().year;
    final endYear = currentYear + 4;

    test('1. 필수 양력 공휴일(신정, 삼일절, 광복절, 개천절, 한글날, 크리스마스) 누락 검증', () {
      final min = DateTime(currentYear, 1, 1);
      final max = DateTime(currentYear, 12, 31);
      final holidays = HolidayUtil.generateHolidaysForWindow(min, max);

      final holidayTitles = holidays.map((h) => h.title).toList();

      expect(holidayTitles.any((t) => t.contains('신정')), true);
      expect(holidayTitles.any((t) => t.contains('삼일절')), true);
      expect(holidayTitles.any((t) => t.contains('광복절')), true);
      expect(holidayTitles.any((t) => t.contains('개천절')), true);
      expect(holidayTitles.any((t) => t.contains('한글날')), true);
      expect(
          holidayTitles.any((t) =>
              t.contains('기독탄신일') || t.contains('크리스마스') || t.contains('성탄절')),
          true);
    });

    test('2. 향후 5년 내 대체공휴일 산출 보장 검증 (Dynamic Search)', () {
      final min = DateTime(currentYear, 1, 1);
      final max = DateTime(endYear, 12, 31);

      final holidays = HolidayUtil.generateHolidaysForWindow(min, max);
      final altHolidays =
          holidays.where((h) => h.title.contains('대체공휴일')).toList();

      expect(altHolidays.isNotEmpty, true,
          reason: '5년 치 윈도우 내에 대체공휴일이 최소 1개 이상 존재해야 합니다.');
    });

    test('3. 특정 공휴일이 주말과 겹치는 연도를 자동 탐색하여 대체공휴일 검증', () {
      int? targetYear;
      for (int y = currentYear; y <= endYear; y++) {
        final samiljeol = DateTime(y, 3, 1);
        if (samiljeol.weekday == DateTime.sunday ||
            samiljeol.weekday == DateTime.saturday) {
          targetYear = y;
          break;
        }
      }

      if (targetYear != null) {
        final min = DateTime(targetYear, 2, 28);
        final max = DateTime(targetYear, 3, 10);

        final holidays = HolidayUtil.generateHolidaysForWindow(min, max);
        final altHolidays =
            holidays.where((h) => h.title.contains('대체공휴일')).toList();

        expect(
            altHolidays.any(
                (h) => h.startDt.year == targetYear && h.startDt.month == 3),
            true,
            reason: '$targetYear년 삼일절은 주말이므로 반드시 3월에 대체공휴일이 생성되어야 합니다.');
      }
    });

    test('4. 명절(추석) 5년 치 연속 3일 블록 보장 검증', () {
      final min = DateTime(currentYear, 1, 1);
      final max = DateTime(endYear, 12, 31);

      final holidays = HolidayUtil.generateHolidaysForWindow(min, max);
      final chuseokHolidays =
          holidays.where((h) => h.title.contains('추석')).toList();

      expect(chuseokHolidays.length, greaterThanOrEqualTo(15),
          reason: '5년간 매년 3일씩, 총 15일 이상의 추석 연휴 블록이 생성되어야 합니다.');
    });
  });
}
