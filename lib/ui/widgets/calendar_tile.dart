// v4.1.0
// calendar_tile.dart
// lib/ui/widgets/calendar_tile.dart
// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
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
  final bool showLunar;
  final double? forcedHeight;

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
    this.showLunar = false,
    this.forcedHeight,
  });

  List<CalendarEvent> get _events =>
      eventsByDate[DateFormatter.dateKey(day)] ?? [];

  // ── 날짜 텍스트 색상 ────────────────────────────────────────

  Color _textColor() {
    if (isSelected) return Colors.white;
    if (isOutside) return th.isDark ? Colors.white24 : Colors.grey[400]!;
    if (day.weekday == DateTime.sunday || isHoliday)
      return Colors.redAccent; // 💡 이벤트 여부와 무관하게 isHoliday 판별
    if (day.weekday == DateTime.saturday) return Colors.blueAccent;
    return th.isDark ? Colors.white : const Color(0xFF333333);
  }

  Color? _todayRingColor() {
    if (!isToday || isSelected || isOutside) return null;
    if (day.weekday == DateTime.sunday || isHoliday) return Colors.redAccent;
    if (day.weekday == DateTime.saturday) return Colors.blueAccent;
    return th.isDark ? Colors.white70 : Colors.black87;
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

  // ── 음력 레이블 (일요일 한정) ─────────────────────────────────

  Widget _buildHeader() {
    final lunar = (!isOutside && showLunar && day.weekday == DateTime.sunday)
        ? (DateFormatter.getLunarLabel(day, true) ?? '')
        : null;
    final badge = _buildDateBadge();

    if (lunar != null && lunar.isNotEmpty) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        badge,
        const SizedBox(width: 6),
        Flexible(
          child: Text(lunar,
              style: TextStyle(
                color: _textColor(),
                fontSize: 9.5,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip),
        ),
      ]);
    }
    return badge;
  }

  // ── Dot 표시 (showTextInside = false) ────────────────────────

  Widget _buildDots() => Padding(
        padding: const EdgeInsets.only(top: 3, bottom: 2),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 2.5,
          runSpacing: 2.5,
          children: _events.take(8).map((e) {
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
    if (th.showTextInside) {
      return Container(
        constraints: forcedHeight != null
            ? BoxConstraints(minHeight: forcedHeight!)
            : const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.only(top: 3, left: 1, right: 1, bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 3, bottom: 1),
              child:
                  Align(alignment: th.cellTextAlignment, child: _buildHeader()),
            ),
            if (_events.isNotEmpty && !isOutside)
              ...EventBar.buildBars(
                day: day,
                events: _events,
                slotMap: slotMap,
                primaryAccent: th.primaryAccent,
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
              child: Center(child: _buildHeader())),
          if (_events.isNotEmpty && !isOutside) _buildDots(),
        ],
      ),
    );
  }
}
