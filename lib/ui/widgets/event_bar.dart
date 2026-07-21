// v4.4.5
// claude_event_bar.dart
// lib/ui/widgets/event_bar.dart
// ignore_for_file: curly_braces_in_flow_control_structures
// 달력 셀(CalendarTile) 내부에 그려지는 이벤트 막대(Bar) 위젯.
// showTextInside=true 테마(삼성/네이버)에서만 사용됩니다.
// [v4.4.5] 시작/종료 시간이 설정된 일정은 첫 날 셀에 '시간(윗줄)+제목(아랫줄)' 2줄 표시.
// [v4.4.5] 다중일 일정 바 연결: 모든 바를 균일 높이로 유지하고, 중간 날은 셀 가장자리까지 채워 이어짐.
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/date_formatter.dart';

class EventBar {
  // 바 1개(마진 포함)의 세로 점유 높이. 빈 슬롯 SizedBox도 동일해야 슬롯 정렬이 유지됨.
  static const double _barHeight = 22.0;
  static const double _barMargin = 2.0;
  static const double slotHeight = _barHeight + _barMargin; // = 24.0

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
      // 빈 슬롯: 다음 슬롯과 정렬 맞추기 위한 공백 (바 1개 점유 높이와 동일)
      if (e == null) return const SizedBox(height: slotHeight);

      final color = e.colorValue != null ? Color(e.colorValue!) : primaryAccent;
      final isFirst = dayKey == e.date;
      final isLast = dayKey == (e.endDate ?? e.date);

      // 설날·추석은 연속 블록에서 가운데 날에만 텍스트 표시
      bool showText = !e.isMultiDay || isFirst;
      if (e.isHoliday && (e.title == '설날' || e.title == '추석') && e.isMultiDay) {
        showText = dayKey ==
            DateFormatter.dateKey(e.startDt.add(const Duration(days: 1)));
      }

      // 시작/종료 시간이 설정된(하루 종일 아님) 일정은 첫 날에 시간 줄을 함께 표시
      final bool isTimed = !e.isAllDay && e.startTime != null;
      final String? timeLine =
          (showText && isTimed && isFirst) ? e.startTime : null;
      final String title = showText ? e.title : '';

      return _EventBarItem(
        color: color,
        isFirst: isFirst,
        isLast: isLast,
        isMultiDay: e.isMultiDay,
        showText: showText,
        timeLine: timeLine,
        title: title,
      );
    });
  }
}

class _EventBarItem extends StatelessWidget {
  final Color color;
  final bool isFirst, isLast, isMultiDay, showText;
  final String? timeLine;
  final String title;

  const _EventBarItem({
    required this.color,
    required this.isFirst,
    required this.isLast,
    required this.isMultiDay,
    required this.showText,
    required this.timeLine,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: EventBar._barHeight,
      margin: EdgeInsets.only(
        bottom: EventBar._barMargin,
        // 중간 날은 좌우 마진 0으로 셀 가장자리까지 채워 이웃 셀 바와 이어지게 함
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
      child: showText ? _buildContent() : const SizedBox.shrink(),
    );
  }

  Widget _buildContent() {
    return Row(children: [
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
        child: timeLine != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timeLine!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip),
                  Text(title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        height: 1.05,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              )
            : Text(title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
      ),
      const SizedBox(width: 2),
    ]);
  }
}
