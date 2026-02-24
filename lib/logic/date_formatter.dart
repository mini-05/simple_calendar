// ignore_for_file: curly_braces_in_flow_control_structures
// v3.6.0
import 'package:lunar/lunar.dart';
import '../models/models.dart';

class DateFormatter {
  static String dateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String formatDateKorean(DateTime d) {
    const wd = ['일', '월', '화', '수', '목', '금', '토'];
    return '${d.year}년 ${d.month}월 ${d.day}일 (${wd[d.weekday % 7]})';
  }

  static String formatHHmm(String hhmm) {
    final p = hhmm.split(':');
    if (p.length != 2) {
      return '';
    }
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    final period = h < 12 ? '오전' : '오후';
    final disp = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $disp:${m.toString().padLeft(2, '0')}';
  }

  static String makeTimeString(CalendarEvent e) {
    final sameDay = !e.isMultiDay;
    if (e.isAllDay) {
      if (sameDay) {
        return '하루 종일';
      }
      return '${e.startDt.month}.${e.startDt.day} ~ ${e.endDt.month}.${e.endDt.day}';
    }
    final sT = formatHHmm(e.startTime ?? '00:00');
    final eT = formatHHmm(e.endTime ?? '00:00');
    if (sameDay) {
      return '$sT ~ $eT';
    }
    return '${e.startDt.month}.${e.startDt.day} $sT ~ ${e.endDt.month}.${e.endDt.day} $eT';
  }

  static String? getLunarLabel(DateTime solarDate, bool showLunar) {
    if (!showLunar) {
      return null;
    }
    try {
      final lunar = Lunar.fromDate(solarDate);
      return '${lunar.getMonth()}. ${lunar.getDay()}';
    } catch (_) {
      return '';
    }
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
      if (code >= 0xAC00 && code <= 0xD7A3) {
        result += cho[((code - 0xAC00) ~/ 588)];
      } else {
        result += str[i];
      }
    }
    return result;
  }
}
