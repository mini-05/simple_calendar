// v4.3.9
// gemini_app_theme.dart
// lib/theme/app_theme.dart
// ignore_for_file: curly_braces_in_flow_control_structures
// 디자인 시스템 (Design System)
// [v4.3.7 변경사항]
// 1. SamsungTheme(76줄) + NaverTheme(75줄) → BarCardTheme 단일 클래스로 통합 (~90줄 감축)
//    - Gemini 원안(BarCardTheme)에서 _type==AppTheme.samsung 삼항 분기 3곳을 named param으로 교체
//    - OCP 완성: 새 테마 추가 시 BarCardTheme 내부 코드 수정 불필요
// 2. AppThemeExt.themeData switch { case: return } 30줄 → switch expression 15줄 압축
import 'package:flutter/material.dart';
import '../models/models.dart';

// ══════════════════════════════════════════════════════════════════
// CalendarTheme — 테마 인터페이스
// ══════════════════════════════════════════════════════════════════

abstract class CalendarTheme {
  AppTheme get type;
  String get name;
  String get emoji;

  // ── 색상 팔레트 ──────────────────────────────────────────────
  Color get scaffoldBg;
  Color get appBarBg;
  Color get appBarText;
  Color get calendarBg;
  Color get primaryAccent;
  Color get secondaryAccent;
  Color get cardBg;
  Color get cardBorder;
  Color get eventTitleText;
  Color get eventSubText;
  Color get iconBg;
  Color get iconColor;
  Color get sectionLabelText;

  // ── 레이아웃 플래그 ──────────────────────────────────────────
  /// true: 날짜 셀 안에 이벤트 Bar + 글씨 표시 (삼성/네이버)
  /// false: 날짜 숫자 아래 Dot만 표시 (애플/다크네온)
  bool get showTextInside => false;

  bool get isDark => false;
  bool get hasRoundedCard => false;

  /// 일정 패널 배경색 (null = scaffoldBg 사용)
  Color? get bottomSheetBg => null;

  /// showTextInside=true 시 날짜 숫자 정렬 방향
  Alignment get cellTextAlignment => Alignment.center;

  // ── 공통 빌더 ────────────────────────────────────────────────

  /// 일정 제목 + 시간 + 알람 아이콘 컬럼
  Widget buildTitleColumn({
    required CalendarEvent event,
    required String dateInfo,
    required bool isGlobalSilent,
    required VoidCallback onToggleAlarm,
    Color? titleColor,
    double titleSize = 15,
    double dateSize = 12,
  }) {
    final effectiveAlarmOn = event.isAlarmOn && !isGlobalSilent;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(event.title,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: titleSize,
                  color: titleColor ?? eventTitleText)),
        ),
        if (event.alarmMinutes != AlarmMinutes.none && !event.isHoliday)
          GestureDetector(
            onTap: onToggleAlarm,
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 8, right: 4, top: 2, bottom: 2),
              child: Icon(
                effectiveAlarmOn
                    ? Icons.notifications_active
                    : Icons.notifications_paused,
                size: 16,
                color: effectiveAlarmOn
                    ? primaryAccent
                    : Colors.grey.withValues(alpha: 0.5),
              ),
            ),
          ),
      ]),
      if (dateInfo.isNotEmpty)
        Text(dateInfo,
            style: TextStyle(fontSize: dateSize, color: Colors.grey)),
    ]);
  }

  /// 테마별 일정 목록 아이템 위젯
  Widget buildEventListItem({
    required BuildContext context,
    required CalendarEvent event,
    required String dateInfo,
    required bool isGlobalSilent,
    required VoidCallback onToggleAlarm,
    required String Function(String) formatHHmm,
  });
}

// ══════════════════════════════════════════════════════════════════
// DynamicWidgetConfig — 스플래시 & 위젯 인포그래픽 디자인 토큰 (v4.3.9 신규)
// sealed class로 OCP 준수: 새 디자인 추가 = 새 subclass만 추가
// ══════════════════════════════════════════════════════════════════

sealed class DynamicWidgetConfig {
  Color get accent;        // 포인트 색상
  Color get bg;            // 위젯 배경색
  Color get textPrimary;   // 날짜 숫자 색상
  Color get textSecondary; // 요일/주차 색상
  String get motionTag;    // 애니메이션 태그 식별자
}

class FlipWidgetConfig extends DynamicWidgetConfig {
  @override Color get accent => const Color(0xFF2196F3);       // 블루
  @override Color get bg => const Color(0xFFF2F2F2);           // 라이트 그레이
  @override Color get textPrimary => const Color(0xFF222222);
  @override Color get textSecondary => const Color(0xFF666666);
  @override String get motionTag => 'flip';
}

class CircleWidgetConfig extends DynamicWidgetConfig {
  @override Color get accent => const Color(0xFF00E5FF);       // 네온 시안
  @override Color get bg => const Color(0xFF0a0a0a);           // 다크 (액체 그라데이션)
  @override Color get textPrimary => Colors.white;
  @override Color get textSecondary => const Color(0xFFB0BEC5);
  @override String get motionTag => 'circle';
}

class ClassicWidgetConfig extends DynamicWidgetConfig {
  @override Color get accent => const Color(0xFF03C75A);       // 그린
  @override Color get bg => const Color(0xFF1a1a2e);           // 깊은 배경 (4링)
  @override Color get textPrimary => Colors.white;
  @override Color get textSecondary => const Color(0xFFcccccc);
  @override String get motionTag => 'classic';
}

class AstronomicalWidgetConfig extends DynamicWidgetConfig {
  @override Color get accent => const Color(0xFFFA233B);       // 레드 포인트
  @override Color get bg => const Color(0xFF08081a);           // 깊은 우주
  @override Color get textPrimary => Colors.white;
  @override Color get textSecondary => const Color(0xFFADB5D0);
  @override String get motionTag => 'astronomical';
}

// ══════════════════════════════════════════════════════════════════
// BarCardTheme — 삼성 / 네이버 공통 클래스
// ══════════════════════════════════════════════════════════════════

class BarCardTheme extends CalendarTheme {
  final AppTheme _type;
  final String _name, _emoji;
  final Color _scaffoldBg; // appBarBg도 동일값 (삼성·네이버 모두 해당)
  final Color _primaryAccent;
  final Color _secondaryAccent;
  final Color _cardBg;
  final Color _iconBg;
  final Color _appBarText;
  final Color _eventTitleText;
  final Color _eventSubText;
  final Color _sectionLabelText;
  final Alignment _cellTextAlignment;
  final double _markerRadius; // 삼성: 12.0(원형), 네이버: 3.0(라운드 사각)

  BarCardTheme(
    this._type,
    this._name,
    this._emoji,
    this._scaffoldBg,
    this._primaryAccent,
    this._secondaryAccent,
    this._cardBg,
    this._iconBg, {
    required Color appBarText,
    required Color eventTitleText,
    required Color eventSubText,
    required Color sectionLabelText,
    Alignment cellTextAlignment = Alignment.center,
    double markerRadius = 12.0,
  })  : _appBarText = appBarText,
        _eventTitleText = eventTitleText,
        _eventSubText = eventSubText,
        _sectionLabelText = sectionLabelText,
        _cellTextAlignment = cellTextAlignment,
        _markerRadius = markerRadius;

  @override AppTheme get type => _type;
  @override String get name => _name;
  @override String get emoji => _emoji;
  @override Color get scaffoldBg => _scaffoldBg;
  @override Color get appBarBg => _scaffoldBg; // 삼성·네이버 둘 다 appBarBg == scaffoldBg
  @override Color get appBarText => _appBarText;
  @override Color get calendarBg => Colors.white;
  @override Color get primaryAccent => _primaryAccent;
  @override Color get secondaryAccent => _secondaryAccent;
  @override Color get cardBg => _cardBg;
  @override Color get cardBorder => Colors.transparent;
  @override Color get eventTitleText => _eventTitleText;
  @override Color get eventSubText => _eventSubText;
  @override Color get iconBg => _iconBg;
  @override Color get iconColor => _primaryAccent;
  @override Color get sectionLabelText => _sectionLabelText;
  @override bool get showTextInside => true;
  @override Alignment get cellTextAlignment => _cellTextAlignment;

  @override
  Widget buildEventListItem({
    required BuildContext context,
    required CalendarEvent event,
    required String dateInfo,
    required bool isGlobalSilent,
    required VoidCallback onToggleAlarm,
    required String Function(String) formatHHmm,
  }) {
    final color =
        event.colorValue != null ? Color(event.colorValue!) : primaryAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)
        ],
      ),
      child: Row(children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color,
                borderRadius:
                    BorderRadius.circular(_markerRadius))), // 삼성:원, 네이버:사각
        const SizedBox(width: 12),
        Expanded(
            child: buildTitleColumn(
                event: event,
                dateInfo: dateInfo,
                isGlobalSilent: isGlobalSilent,
                onToggleAlarm: onToggleAlarm)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 개별 테마 구현체
// ══════════════════════════════════════════════════════════════════

class AppleTheme extends CalendarTheme {
  @override AppTheme get type => AppTheme.apple;
  @override String get name => '애플 캘린더';
  @override String get emoji => '🍎';
  @override Color get scaffoldBg => const Color(0xFFF8F9FF);
  @override Color get appBarBg => Colors.white;
  @override Color get appBarText => const Color(0xFF1A1A2E);
  @override Color get calendarBg => Colors.white;
  @override Color get primaryAccent => const Color(0xFFFA233B);
  @override Color get secondaryAccent => const Color(0xFFFFD1D6);
  @override Color get cardBg => Colors.white;
  @override Color get cardBorder => Colors.transparent;
  @override Color get eventTitleText => const Color(0xFF1A1A2E);
  @override Color get eventSubText => const Color(0xFF888888);
  @override Color get iconBg => const Color(0xFFFFF0F1);
  @override Color get iconColor => const Color(0xFFFA233B);
  @override Color get sectionLabelText => const Color(0xFF1A1A2E);

  @override
  Widget buildEventListItem({
    required BuildContext context,
    required CalendarEvent event,
    required String dateInfo,
    required bool isGlobalSilent,
    required VoidCallback onToggleAlarm,
    required String Function(String) formatHHmm,
  }) {
    final color =
        event.colorValue != null ? Color(event.colorValue!) : primaryAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)))),
      child: Row(children: [
        Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Expanded(
            child: buildTitleColumn(
                event: event,
                dateInfo: dateInfo,
                isGlobalSilent: isGlobalSilent,
                onToggleAlarm: onToggleAlarm,
                titleSize: 16)),
      ]),
    );
  }
}

class TodoSkyTheme extends CalendarTheme {
  @override AppTheme get type => AppTheme.todoSky;
  @override String get name => '투두 스카이';
  @override String get emoji => '✅';
  @override Color get scaffoldBg => Colors.white;
  @override Color get appBarBg => Colors.white;
  @override Color get appBarText => const Color(0xFF2D3142);
  @override Color get calendarBg => Colors.white;
  @override Color get primaryAccent => const Color(0xFFEF6C6C);
  @override Color get secondaryAccent => const Color(0xFFF5E6E6);
  @override Color get cardBg => const Color(0xFF3A3F5C);
  @override Color get cardBorder => const Color(0xFF4A5073);
  @override Color get eventTitleText => Colors.white;
  @override Color get eventSubText => const Color(0xFFADB5D0);
  @override Color get iconBg => const Color(0xFF4A5073);
  @override Color get iconColor => const Color(0xFFEF6C6C);
  @override Color get sectionLabelText => Colors.white;
  @override Color? get bottomSheetBg => const Color(0xFF2D3142);
  @override bool get hasRoundedCard => true;

  @override
  Widget buildEventListItem({
    required BuildContext context,
    required CalendarEvent event,
    required String dateInfo,
    required bool isGlobalSilent,
    required VoidCallback onToggleAlarm,
    required String Function(String) formatHHmm,
  }) {
    final color =
        event.colorValue != null ? Color(event.colorValue!) : primaryAccent;
    final effectiveAlarmOn = event.isAlarmOn && !isGlobalSilent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Icon(Icons.event, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(event.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white))),
            if (event.alarmMinutes != AlarmMinutes.none && !event.isHoliday)
              GestureDetector(
                  onTap: onToggleAlarm,
                  child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                          effectiveAlarmOn
                              ? Icons.notifications_active
                              : Icons.notifications_paused,
                          size: 14,
                          color: effectiveAlarmOn
                              ? primaryAccent
                              : Colors.grey.withValues(alpha: 0.5)))),
          ]),
          if (dateInfo.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(dateInfo, style: TextStyle(fontSize: 12, color: eventSubText)),
          ],
        ])),
        if (event.startTime != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20)),
            child: Text(formatHHmm(event.startTime!),
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }
}

class DefaultCardTheme extends CalendarTheme {
  final AppTheme _type;
  final String _name, _emoji;
  final Color _scaffoldBg,
      _appBarBg,
      _appBarText,
      _calendarBg,
      _primaryAccent,
      _secondaryAccent,
      _cardBg,
      _cardBorder,
      _eventTitleText,
      _eventSubText,
      _iconBg,
      _iconColor,
      _sectionLabelText;
  final bool _isDark, _hasRoundedCard;

  DefaultCardTheme(
      this._type,
      this._name,
      this._emoji,
      this._scaffoldBg,
      this._appBarBg,
      this._appBarText,
      this._calendarBg,
      this._primaryAccent,
      this._secondaryAccent,
      this._cardBg,
      this._cardBorder,
      this._eventTitleText,
      this._eventSubText,
      this._iconBg,
      this._iconColor,
      this._sectionLabelText,
      {bool isDark = false,
      bool hasRoundedCard = false})
      : _isDark = isDark,
        _hasRoundedCard = hasRoundedCard;

  @override AppTheme get type => _type;
  @override String get name => _name;
  @override String get emoji => _emoji;
  @override Color get scaffoldBg => _scaffoldBg;
  @override Color get appBarBg => _appBarBg;
  @override Color get appBarText => _appBarText;
  @override Color get calendarBg => _calendarBg;
  @override Color get primaryAccent => _primaryAccent;
  @override Color get secondaryAccent => _secondaryAccent;
  @override Color get cardBg => _cardBg;
  @override Color get cardBorder => _cardBorder;
  @override Color get eventTitleText => _eventTitleText;
  @override Color get eventSubText => _eventSubText;
  @override Color get iconBg => _iconBg;
  @override Color get iconColor => _iconColor;
  @override Color get sectionLabelText => _sectionLabelText;
  @override bool get isDark => _isDark;
  @override bool get hasRoundedCard => _hasRoundedCard;

  @override
  Widget buildEventListItem({
    required BuildContext context,
    required CalendarEvent event,
    required String dateInfo,
    required bool isGlobalSilent,
    required VoidCallback onToggleAlarm,
    required String Function(String) formatHHmm,
  }) {
    final color =
        event.colorValue != null ? Color(event.colorValue!) : primaryAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Row(children: [
        Icon(Icons.check_circle_outline, color: color),
        const SizedBox(width: 12),
        Expanded(
            child: buildTitleColumn(
                event: event,
                dateInfo: dateInfo,
                isGlobalSilent: isGlobalSilent,
                onToggleAlarm: onToggleAlarm,
                dateSize: 11)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// AppThemeExt — AppTheme enum → CalendarTheme 인스턴스 변환
// ══════════════════════════════════════════════════════════════════

extension AppThemeExt on AppTheme {
  CalendarTheme get themeData => switch (this) {
        AppTheme.samsung => BarCardTheme(
            AppTheme.samsung,
            '삼성 캘린더',
            '📱',
            const Color(0xFFF2F2F2),
            const Color(0xFF2196F3),
            const Color(0xFFBBDEF0),
            Colors.white,
            const Color(0xFFE3F2FD),
            appBarText: const Color(0xFF222222),
            eventTitleText: const Color(0xFF222222),
            eventSubText: const Color(0xFF666666),
            sectionLabelText: const Color(0xFF444444),
            cellTextAlignment: Alignment.topLeft,
            markerRadius: 12.0,
          ),
        AppTheme.naver => BarCardTheme(
            AppTheme.naver,
            '네이버 캘린더',
            '🇳',
            Colors.white,
            const Color(0xFF03C75A),
            const Color(0xFFD4F5E1),
            const Color(0xFFF9F9F9),
            const Color(0xFFE6F9ED),
            appBarText: Colors.black,
            eventTitleText: Colors.black87,
            eventSubText: Colors.black54,
            sectionLabelText: Colors.black,
            markerRadius: 3.0,
          ),
        AppTheme.apple => AppleTheme(),
        AppTheme.todoSky => TodoSkyTheme(),
        AppTheme.darkNeon => DefaultCardTheme(
            AppTheme.darkNeon,
            '다크 네온',
            '🌙',
            const Color(0xFF1E1B2E),
            const Color(0xFF1E1B2E),
            Colors.white,
            const Color(0xFF2A2640),
            const Color(0xFF9C6FE4),
            const Color(0xFF00D4FF),
            const Color(0xFF2A2640),
            const Color(0xFF3D3760),
            Colors.white,
            const Color(0xFF9E9BB8),
            const Color(0xFF3D3760),
            const Color(0xFF9C6FE4),
            Colors.white,
            isDark: true,
            hasRoundedCard: true),
        AppTheme.classicBlue => DefaultCardTheme(
            AppTheme.classicBlue,
            '클래식 블루',
            '☁️',
            const Color(0xFFF8F9FF),
            Colors.white,
            const Color(0xFF1A1A2E),
            Colors.white,
            const Color(0xFF4A90D9),
            const Color(0xFFDDEEFF),
            Colors.white,
            const Color(0xFFEEEEEE),
            const Color(0xFF1A1A2E),
            const Color(0xFF888888),
            const Color(0xFFEEF4FF),
            const Color(0xFF4A90D9),
            const Color(0xFF1A1A2E)),
      };

  // 💡 [v4.3.9] WidgetTheme → DynamicWidgetConfig 변환 (OCP 준수)
  static DynamicWidgetConfig widgetConfig(WidgetTheme t) => switch (t) {
        WidgetTheme.flip => FlipWidgetConfig(),
        WidgetTheme.circle => CircleWidgetConfig(),
        WidgetTheme.classic => ClassicWidgetConfig(),
        WidgetTheme.astronomical => AstronomicalWidgetConfig(),
      };
}