// v4.4.8
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
// [v4.4.8] 정리: 틴트 계산을 AppNeutral로 이관(정책 일원화 + 캐시),
//   timeLine과 중복이던 stripStyle 필드 제거, 도달 불가였던 설날/추석 분기 삭제.
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/design_tokens.dart';

class EventBar {
  static const double _barMargin = 2.0;

  // 바 높이는 줄바꿈 설정에 따라 균일하게 결정 (모든 바 동일 → 다중일 연결/슬롯 정렬 유지)
  static double barHeight(bool wrap) => wrap ? 34.0 : 22.0;
  static double slotHeight(bool wrap) => barHeight(wrap) + _barMargin;

  /// 특정 날짜에 표시할 이벤트 Bar 위젯 목록을 반환합니다.
  /// 슬롯 빈칸은 투명 SizedBox로 채워 다중 날 이벤트의 정렬을 유지합니다.
  /// [dayKey]는 호출부(CalendarTile)가 이미 만들어 둔 날짜 키를 그대로 받는다 —
  /// 셀마다 같은 문자열을 다시 만들지 않기 위함.
  static List<Widget> buildBars({
    required String dayKey,
    required List<CalendarEvent> events,
    required Map<int, int> slotMap,
    required Color primaryAccent,
    bool wrapText = false,
  }) {
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

      // 다중일 일정은 첫 날에만 텍스트를 표시한다.
      final bool showText = !e.isMultiDay || isFirst;

      // 시작/종료 시간이 설정된(하루 종일 아님) 일정은 첫 날에 시간 줄 표시
      final bool isTimed = !e.isAllDay && e.startTime != null;
      final bool showTime = showText && isTimed && isFirst;
      final String? timeLine = showTime ? e.startTime : null;

      return _EventBarItem(
        color: color,
        isFirst: isFirst,
        isLast: isLast,
        isMultiDay: e.isMultiDay,
        showText: showText,
        // timeLine != null 이면 '시간 표시 일정' — 배경 없이 왼쪽 바만 그린다.
        timeLine: timeLine,
        title: e.title,
        barHeight: barH,
        titleMaxLines: titleMaxLines,
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

  bool get _stripStyle => timeLine != null;

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
      decoration: _stripStyle
          ? null
          : BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(isFirst ? 3 : 0),
                right: Radius.circular(isLast ? 3 : 0),
              ),
            ),
      child: showText
          ? (_stripStyle ? _stripContent() : _filledContent())
          : const SizedBox.shrink(),
    );
  }

  // 배경 없이 왼쪽 색상 바 + 어두운 글자 (시간 표시 일정)
  Widget _stripContent() {
    final titleColor = AppNeutral.onSurfaceFrom(color);
    final timeColor = AppNeutral.subduedFrom(color);
    final time = timeLine!; // _stripStyle이 true일 때만 호출된다
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
            Text(time,
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
