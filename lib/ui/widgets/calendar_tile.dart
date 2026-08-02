// v4.4.8
// claude_calendar_tile.dart
// lib/ui/widgets/calendar_tile.dart
// ignore_for_file: curly_braces_in_flow_control_structures
// [v4.4.5] 다중일 일정 바가 이웃 셀과 끊김 없이 이어지도록 셀 좌우 패딩 제거
//   (바 좌우 여백은 EventBar가 시작/종료 날에만 부여 → 중간 날은 셀 가장자리까지 채움)
// [v4.4.6] 긴 제목 줄바꿈 설정(wrapEventText)을 EventBar로 전달
// [v4.4.7] artifact-design 토큰: 외부 날짜 텍스트를 선택된 뉴트럴로
// [v4.4.8] 정리: 전달되지 않던 forcedHeight와 항상 false였던 showLunar 분기 삭제
//   (음력 라벨은 calendar_screen이 Stack 오버레이로 그린다),
//   셀마다 4번씩 만들던 dateKey를 한 번만 계산하도록 정리.
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../services/date_formatter.dart';
import 'event_bar.dart';

class CalendarTile extends StatelessWidget {
  final DateTime day;
  final CalendarTheme th;
  final Map<String, List<CalendarEvent>> eventsByDate;
  final Map<int, int> slotMap;
  final bool isToday;
  final bool isSelected;
  final bool isOutside;
  final bool isHoliday; // 💡 공휴일 표시 OFF라도 백그라운드 데이터로 전달됨
  final bool wrapEventText; // 💡 [v4.4.6] 긴 제목 줄바꿈 표시

  const CalendarTile({
    super.key,
    required this.day,
    required this.th,
    required this.eventsByDate,
    required this.slotMap,
    this.isToday = false,
    this.isSelected = false,
    this.isOutside = false,
    this.isHoliday = false, // 💡 추가됨
    this.wrapEventText = false, // 💡 추가됨
  });

  // ── 날짜 텍스트 색상 ────────────────────────────────────────

  Color _textColor() {
    if (isSelected) return Colors.white;
    if (isOutside) return th.isDark ? Colors.white24 : th.tFaint;
    // 💡 이벤트 여부와 무관하게 isHoliday 판별
    return dayLabelColor(day.weekday, isHoliday: isHoliday) ??
        (th.isDark ? Colors.white : const Color(0xFF333333));
  }

  Color? _todayRingColor() {
    if (!isToday || isSelected || isOutside) return null;
    return dayLabelColor(day.weekday, isHoliday: isHoliday) ??
        (th.isDark ? Colors.white70 : Colors.black87);
  }

  // ── 날짜 원형 뱃지 ──────────────────────────────────────────

  Widget _buildDateBadge() {
    final ring = _todayRingColor();
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? th.primaryAccent : null,
        border: ring != null ? Border.all(color: ring, width: 1.8) : null,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text('${day.day}',
          style: TextStyle(
            color: _textColor(),
            fontWeight:
                (isToday || isSelected) ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          )),
    );
  }

  // ── Dot 표시 (showTextInside = false) ────────────────────────

  Widget _buildDots(List<CalendarEvent> events) => Padding(
        padding: const EdgeInsets.only(top: 3, bottom: 2),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 2.5,
          runSpacing: 2.5,
          children: events.take(8).map((e) {
            final color =
                e.colorValue != null ? Color(e.colorValue!) : th.primaryAccent;
            return Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            );
          }).toList(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // 셀 키는 한 번만 만들어 이벤트 조회와 바 렌더링이 함께 쓴다.
    final dayKey = DateFormatter.dateKey(day);
    final events = eventsByDate[dayKey] ?? const <CalendarEvent>[];
    final hasEvents = events.isNotEmpty && !isOutside;

    if (th.showTextInside) {
      return Container(
        constraints: const BoxConstraints(minHeight: 52),
        // 좌우 패딩 0: 다중일 바가 셀 경계에서 이웃 셀 바와 이어지도록 함
        padding: const EdgeInsets.only(top: 3, bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 3, bottom: 1),
              child: Align(
                  alignment: th.cellTextAlignment, child: _buildDateBadge()),
            ),
            if (hasEvents)
              ...EventBar.buildBars(
                dayKey: dayKey,
                events: events,
                slotMap: slotMap,
                primaryAccent: th.primaryAccent,
                wrapText: wrapEventText,
              ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Center(child: _buildDateBadge())),
          if (hasEvents) _buildDots(events),
        ],
      ),
    );
  }
}
