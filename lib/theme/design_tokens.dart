// v4.4.7
// design_tokens.dart
// lib/theme/design_tokens.dart
// [v4.4.7] artifact-design 원칙 적용 — '선택된 뉴트럴'·타입/반경/간격 스케일.
//   기존 CalendarTheme의 색(eventTitleText 등)은 절대 덮어쓰지 않고,
//   코드 곳곳에 흩어진 raw Colors.grey / black54 / grey[100] 계열을
//   대체하기 위한 '보조 토큰'만 제공한다. (Fill gaps, don't override.)
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 반경 스케일 — 제각각이던 10/12/14/16/20/28을 하나의 램프로 정돈.
class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
}

/// 간격 스케일.
class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// 타입 스케일 — 즉흥적이던 폰트 크기를 하나의 램프로.
class AppType {
  static const double micro = 9;
  static const double caption = 11;
  static const double label = 12.5;
  static const double body = 14;
  static const double bodyLg = 15.5;
  static const double title = 18;
  static const double headline = 22;
}

/// '선택된 뉴트럴' — 액센트 색조를 아주 옅게 머금은 회색.
/// 순수 회색(#888 등)이 '고민 없이 쓴' 느낌인 반면, 액센트 쪽으로 살짝 편향된
/// 뉴트럴은 '선택된' 느낌을 준다. (accent, isDark)만으로 계산 가능하도록 static 제공 —
/// CalendarTheme을 갖지 못한 위젯(settings_sheet 등)에서도 재사용.
class AppNeutral {
  static Color _tint(double hue, double sat, double lightness) =>
      HSLColor.fromAHSL(1, hue, sat, lightness).toColor();

  static double _hue(Color accent) => HSLColor.fromColor(accent).hue;

  /// 본문 보조 텍스트(부제/라벨) — 기존 black54 / white54 대체.
  static Color muted(Color accent, bool isDark) => isDark
      ? _tint(_hue(accent), 0.05, 0.64)
      : _tint(_hue(accent), 0.06, 0.44);

  /// 더 흐린 텍스트/아이콘(힌트/비활성) — 기존 grey / white38 대체.
  static Color faint(Color accent, bool isDark) => isDark
      ? _tint(_hue(accent), 0.04, 0.50)
      : _tint(_hue(accent), 0.05, 0.60);

  /// 구분선 — 기존 grey[300] / white12 대체.
  static Color divider(Color accent, bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : _tint(_hue(accent), 0.05, 0.90);

  /// 옅은 채움 배경(입력 필드/타일) — 기존 grey[100] / Color(0xFF3D3760) 대체.
  static Color fill(Color accent, bool isDark) => isDark
      ? _tint(_hue(accent), 0.06, 0.26)
      : _tint(_hue(accent), 0.05, 0.965);
}

/// CalendarTheme을 가진 위젯에서 짧게 쓰기 위한 편의 확장.
extension CalendarThemeTokens on CalendarTheme {
  Color get tMuted => AppNeutral.muted(primaryAccent, isDark);
  Color get tFaint => AppNeutral.faint(primaryAccent, isDark);
  Color get tDivider => AppNeutral.divider(primaryAccent, isDark);
  Color get tFill => AppNeutral.fill(primaryAccent, isDark);
}
