// v4.3.6
// claude_event_bar.dart
// lib/ui/widgets/event_bar.dart
// ignore_for_file: curly_braces_in_flow_control_structures
// 달력 셀(CalendarTile) 내부에 그려지는 이벤트 막대(Bar) 위젯.
// showTextInside=true 테마(삼성/네이버)에서만 사용됩니다.
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/date_formatter.dart';

class EventBar {
  /// 특정 날짜에 표시할 이벤트 Bar 위젯 목록을 반환합니다.
  /// 슬롯 빈칸은 투명 SizedBox로 채워 다중 날 이벤트의 정렬을 유지합니다.
  static List<Widget> buildBars({
    required DateTime day,
    required List<CalendarEvent> events,
    required Map<int, int> slotMap,
    required Color primaryAccent,
  }) {
    final dayKey = DateFormatter.dateKey(day);

    // 슬롯 번호 → 이벤트 매핑
    int maxSlot = -1;
    final slotted = <int, CalendarEvent>{};
    for (final e in events) {
      final s = slotMap[e.id] ?? 0;
      slotted[s] = e;
      if (s > maxSlot) maxSlot = s;
    }

    return List.generate(maxSlot + 1, (slot) {
      final e = slotted[slot];
      // 빈 슬롯: 다음 슬롯과 정렬 맞추기 위한 공백
      if (e == null) return const SizedBox(height: 20);

      final color = e.colorValue != null ? Color(e.colorValue!) : primaryAccent;
      final isFirst = dayKey == e.date;
      final isLast = dayKey == (e.endDate ?? e.date);

      // 설날·추석은 연속 블록에서 가운데 날에만 텍스트 표시
      bool showText = !e.isMultiDay || isFirst;
      if (e.isHoliday && (e.title == '설날' || e.title == '추석') && e.isMultiDay) {
        showText = dayKey ==
            DateFormatter.dateKey(e.startDt.add(const Duration(days: 1)));
      }

      final label = showText
          ? ((!e.isAllDay && e.startTime != null && isFirst)
              ? '${e.startTime} ${e.title}'
              : e.title)
          : '';

      return _EventBarItem(
        color: color,
        isFirst: isFirst,
        isLast: isLast,
        isMultiDay: e.isMultiDay,
        showText: showText,
        label: label,
      );
    });
  }
}

class _EventBarItem extends StatelessWidget {
  final Color color;
  final bool isFirst, isLast, isMultiDay, showText;
  final String label;

  const _EventBarItem({
    required this.color,
    required this.isFirst,
    required this.isLast,
    required this.isMultiDay,
    required this.showText,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      margin: EdgeInsets.only(
        bottom: 2,
        left: isFirst ? 2 : 0,
        right: isLast ? 2 : 0,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(isFirst ? 3 : 0),
          right: Radius.circular(isLast ? 3 : 0),
        ),
      ),
      child: showText
          ? Row(children: [
              // 단일 날짜 이벤트: 왼쪽에 색상 바
              if (!isMultiDay)
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      bottomLeft: Radius.circular(3),
                    ),
                  ),
                ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ])
          : const SizedBox.shrink(),
    );
  }
}
