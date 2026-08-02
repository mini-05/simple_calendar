// v4.4.6
// date_formatter.dart
// lib/services/date_formatter.dart
// ignore_for_file: curly_braces_in_flow_control_structures
// [v4.4.6] home_widget_service/splash_screen/calendar_screen에 중복되던
//   ISO 주차 계산·영문 요일/월 라벨을 이곳으로 통합 (중복 제거)

import 'package:lunar/lunar.dart';
import '../models/models.dart';

class DateFormatter {
  static String dateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // ── 영문 요일/월 라벨 및 ISO 주차 (여러 화면 공용) ──────────────
  static const _enWeekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _enMonths = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC'
  ];

  /// 영문 요일 약어 (월요일 시작). 예) 월 → 'MON'
  static String weekdayEn(DateTime d) => _enWeekdays[d.weekday - 1];

  /// 영문 월 약어. 예) 3월 → 'MAR'
  static String monthEn(DateTime d) => _enMonths[d.month - 1];

  /// ISO 8601 주차 계산 (월요일 시작).
  static int isoWeek(DateTime d) {
    final startOfYear = DateTime(d.year, 1, 1);
    final dayOfYear = d.difference(startOfYear).inDays + 1;
    final weekNum = ((dayOfYear - d.weekday + 10) / 7).floor();
    if (weekNum < 1) {
      return isoWeek(DateTime(d.year - 1, 12, 31));
    }
    return weekNum;
  }

  /// 'N주차' 형식 주차 라벨.
  static String weekLabelKo(DateTime d) => '${isoWeek(d)}주차';

  /// 한글 요일 라벨(일요일 시작). 달력 헤더와 날짜 표기가 공유한다.
  static const koWeekdays = ['일', '월', '화', '수', '목', '금', '토'];

  /// DateTime.weekday(월=1…일=7)를 위 배열 인덱스로 변환해 반환.
  static String weekdayKo(int weekday) => koWeekdays[weekday % 7];

  static String formatDateKorean(DateTime d) {
    return '${d.year}년 ${d.month}월 ${d.day}일 (${weekdayKo(d.weekday)})';
  }

  static String formatHHmm(String hhmm) {
    final p = hhmm.split(':');
    if (p.length != 2) return '';
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    final period = h < 12 ? '오전' : '오후';
    final disp = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $disp:${m.toString().padLeft(2, '0')}';
  }

  static String makeTimeString(CalendarEvent e) {
    // isMultiDay는 models.dart CalendarEvent에 getter로 선언됨
    final sameDay = !e.isMultiDay;
    if (e.isAllDay) {
      if (sameDay) return '하루 종일';
      return '${e.startDt.month}.${e.startDt.day} ~ ${e.endDt.month}.${e.endDt.day}';
    }
    final sT = formatHHmm(e.startTime ?? '00:00');
    final eT = formatHHmm(e.endTime ?? '00:00');
    if (sameDay) return '$sT ~ $eT';
    return '${e.startDt.month}.${e.startDt.day} $sT ~ ${e.endDt.month}.${e.endDt.day} $eT';
  }

  // [v4.4.8] 음력 변환 결과 캐시.
  // Lunar.fromDate는 테이블 조회가 아니라 실제 천문/율리우스일 계산이라 비용이 크고,
  // 달력 한 화면(42셀)이 리빌드될 때마다 셀마다 호출된다. 날짜만의 순수 함수이므로
  // 캐시해도 결과가 달라지지 않으며, 크기는 사용자가 실제로 이동한 날짜로 제한된다.
  static final Map<int, String?> _lunarLabelCache = {};

  /// 일요일 셀에만 표시하는 음력 레이블.
  /// showLunar가 true일 때 해당 날짜의 음력을 '음M.D' 형식으로 반환.
  /// 예) 양력 2025-06-15(일) → 음력 5월 20일 → '음5.20'
  static String? getLunarLabel(DateTime solarDate, bool showLunar) {
    if (!showLunar) return null;
    final key = solarDate.year * 10000 + solarDate.month * 100 + solarDate.day;
    final cached = _lunarLabelCache[key];
    if (cached != null || _lunarLabelCache.containsKey(key)) return cached;
    String? label;
    try {
      final lunar = Lunar.fromDate(solarDate);
      // 💡 [패치됨] UI 오버플로우 방지를 위해 '음 ' 대신 공백 없는 '음M.D' 형태로 반환
      label = '음${lunar.getMonth()}.${lunar.getDay()}';
    } catch (_) {
      label = null;
    }
    _lunarLabelCache[key] = label;
    return label;
  }

  static String getChosung(String str) {
    const cho = [
      'ㄱ',
      'ㄲ',
      'ㄴ',
      'ㄷ',
      'ㄸ',
      'ㄹ',
      'ㅁ',
      'ㅂ',
      'ㅃ',
      'ㅅ',
      'ㅆ',
      'ㅇ',
      'ㅈ',
      'ㅉ',
      'ㅊ',
      'ㅋ',
      'ㅌ',
      'ㅍ',
      'ㅎ'
    ];
    String result = '';
    for (int i = 0; i < str.length; i++) {
      int code = str.codeUnitAt(i);
      if (code >= 0xAC00 && code <= 0xD7A3)
        result += cho[((code - 0xAC00) ~/ 588)];
      else
        result += str[i];
    }
    return result;
  }
}
