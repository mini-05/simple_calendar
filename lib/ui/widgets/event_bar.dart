// v4.4.7
// claude_event_bar.dart
// lib/ui/widgets/event_bar.dart
// ignore_for_file: curly_braces_in_flow_control_structures
// 달력 셀(CalendarTile) 내부에 그려지는 이벤트 막대(Bar) 위젯.
// showTextInside=true 테마(삼성/네이버)에서만 사용됩니다.
// [v4.4.5] 시작/종료 시간 일정은 첫 날 셀에 '시간+제목'을 함께 표시.
// [v4.4.6] 시간이 표시되는 일정은 배경색 없이 왼쪽 색상 바만 표시(어두운 글자).
// [v4.4.6] 긴 제목 줄바꿈 설정(wrapText): 제목 2줄(시간 표기 시 3줄) 표시.
//   슬롯 정렬/다중일 연결을 위해 바 높이는 설정에 따라 균일하게 유지됨.
// [v4.4.7] artifact-design 토큰: 시간 일정 글자색을 순수 회색 대신
//   '일정 색에서 파생한 선택된 뉴트럴'로 (색 정체성 유지 + 가독성).
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/date_formatter.dart';

class EventBar {
  static const double _barMargin = 2.0;

  // 바 높이는 줄바꿈 설정에 따라 균일하게 결정 (모든 바 동일 → 다중일 연결/슬롯 정렬 유지)
  static double barHeight(bool wrap) => wrap ? 34.0 : 22.0;
  static double slotHeight(bool wrap) => barHeight(wrap) + _barMargin;

  // 시간 일정(배경 없는 스타일)의 글자색은 순수 회색 대신 '일정 색에서 파생한
  // 선택된 뉴트럴'을 사용 — 각 일정의 색조를 옅게 머금은 어두운 톤으로, 밝은 셀
  // 배경에서 가독성을 유지하면서 색 정체성을 함께 전달한다. (artifact-design 원칙)
  static Color _stripTitleColor(Color base) {
    final hsl = HSLColor.fromColor(base);
    return HSLColor.fromAHSL(
      1,
      hsl.hue,
      (hsl.saturation * 0.55).clamp(0.0, 0.5),
      0.26,
    ).toColor();
  }

  static Color _stripTimeColor(Color base) {
    final hsl = HSLColor.fromColor(base);
    return HSLColor.fromAHSL(
      1,
      hsl.hue,
      (hsl.saturation * 0.45).clamp(0.0, 0.45),
      0.46,
    ).toColor();
  }

  /// 특정 날짜에 표시할 이벤트 Bar 위젯 목록을 반환합니다.
  /// 슬롯 빈칸은 투명 SizedBox로 채워 다중 날 이벤트의 정렬을 유지합니다.
  static List<Widget> buildBars({
    required DateTime day,
    required List<CalendarEvent> events,
    required Map<int, int> slotMap,
    required Color primaryAccent,
    bool wrapText = false,
  }) {
    final dayKey = DateFormatter.dateKey(day);
    final double barH = barHeight(wrapText);
    final double slotH = slotHeight(wrapText);
    final int titleMaxLines = wrapText ? 2 : 1;

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
      if (e == null) return SizedBox(height: slotH);

      final color = e.colorValue != null ? Color(e.colorValue!) : primaryAccent;
      final isFirst = dayKey == e.date;
      final isLast = dayKey == (e.endDate ?? e.date);

      // 설날·추석은 연속 블록에서 가운데 날에만 텍스트 표시
      bool showText = !e.isMultiDay || isFirst;
      if (e.isHoliday && (e.title == '설날' || e.title == '추석') && e.isMultiDay) {
        showText = dayKey ==
            DateFormatter.dateKey(e.startDt.add(const Duration(days: 1)));
      }

      // 시작/종료 시간이 설정된(하루 종일 아님) 일정은 첫 날에 시간 줄 표시
      final bool isTimed = !e.isAllDay && e.startTime != null;
      final bool showTime = showText && isTimed && isFirst;
      final String? timeLine = showTime ? e.startTime : null;
      final String title = showText ? e.title : '';

      return _EventBarItem(
        color: color,
        isFirst: isFirst,
        isLast: isLast,
        isMultiDay: e.isMultiDay,
        showText: showText,
        timeLine: timeLine,
        title: title,
        barHeight: barH,
        titleMaxLines: titleMaxLines,
        // 시간이 표시되는 일정: 배경색 없이 왼쪽 색상 바만 표시
        stripStyle: showTime,
      );
    });
  }
}

class _EventBarItem extends StatelessWidget {
  final Color color;
  final bool isFirst, isLast, isMultiDay, showText;
  final String? timeLine;
  final String title;
  final double barHeight;
  final int titleMaxLines;
  final bool stripStyle;

  const _EventBarItem({
    required this.color,
    required this.isFirst,
    required this.isLast,
    required this.isMultiDay,
    required this.showText,
    required this.timeLine,
    required this.title,
    required this.barHeight,
    required this.titleMaxLines,
    required this.stripStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: barHeight,
      margin: EdgeInsets.only(
        bottom: EventBar._barMargin,
        // 중간 날은 좌우 마진 0으로 셀 가장자리까지 채워 이웃 셀 바와 이어지게 함
        left: isFirst ? 2 : 0,
        right: isLast ? 2 : 0,
      ),
      // 시간 표시 스타일: 배경색 없음 / 그 외: 색상 채움 바
      decoration: stripStyle
          ? null
          : BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(isFirst ? 3 : 0),
                right: Radius.circular(isLast ? 3 : 0),
              ),
            ),
      child: showText
          ? (stripStyle ? _stripContent() : _filledContent())
          : const SizedBox.shrink(),
    );
  }

  // 배경 없이 왼쪽 색상 바 + 어두운 글자 (시간 표시 일정)
  Widget _stripContent() {
    final titleColor = EventBar._stripTitleColor(color);
    final timeColor = EventBar._stripTimeColor(color);
    return Row(children: [
      Container(
        width: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 5),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (timeLine != null)
              Text(timeLine!,
                  style: TextStyle(
                    color: timeColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip),
            Text(title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
                maxLines: titleMaxLines,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      const SizedBox(width: 2),
    ]);
  }

  // 색상 채움 바 + 흰 글자 (하루 종일 / 다중일 밴드)
  Widget _filledContent() {
    return Row(children: [
      // 단일 날짜 이벤트: 왼쪽에 진한 색상 바
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
        child: Text(title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: titleMaxLines,
            overflow: TextOverflow.ellipsis),
      ),
      const SizedBox(width: 2),
    ]);
  }
}
