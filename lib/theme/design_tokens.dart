// v4.4.8
// design_tokens.dart
// lib/theme/design_tokens.dart
// [v4.4.7] artifact-design 원칙 적용 — '선택된 뉴트럴'.
//   기존 CalendarTheme의 색(eventTitleText 등)은 절대 덮어쓰지 않고,
//   코드 곳곳에 흩어진 raw Colors.grey / black54 / grey[100] 계열을
//   대체하기 위한 '보조 토큰'만 제공한다. (Fill gaps, don't override.)
// [v4.4.8] 정리:
//   - 호출자가 하나도 없고 실제 사용값과도 어긋나던 AppRadius/AppSpace/AppType 삭제.
//   - HSL 변환 결과 메모이제이션(입력이 같으면 결과가 같은 순수 함수) — 셀/시트가
//     리빌드될 때마다 반복되던 RGB↔HSL 왕복 제거.
//   - event_bar.dart에 따로 살던 '일정 색 파생 뉴트럴'을 이곳으로 이관해 틴트 정책을 일원화.
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// '선택된 뉴트럴' — 액센트 색조를 아주 옅게 머금은 회색.
/// 순수 회색(#888 등)이 '고민 없이 쓴' 느낌인 반면, 액센트 쪽으로 살짝 편향된
/// 뉴트럴은 '선택된' 느낌을 준다. (accent, isDark)만으로 계산 가능하도록 static 제공 —
/// CalendarTheme을 갖지 못한 위젯(settings_sheet 등)에서도 재사용.
///
/// 모든 함수는 입력에만 의존하는 순수 함수라 결과를 캐시해도 안전하다.
/// (테마/다크모드가 바뀌면 키가 달라지므로 stale 값이 나올 수 없다.)
class AppNeutral {
  static final _muted = <(Color, bool), Color>{};
  static final _faint = <(Color, bool), Color>{};
  static final _divider = <(Color, bool), Color>{};
  static final _fill = <(Color, bool), Color>{};
  static final _onSurfaceFrom = <Color, Color>{};
  static final _subduedFrom = <Color, Color>{};

  static Color _tint(double hue, double sat, double lightness) =>
      HSLColor.fromAHSL(1, hue, sat, lightness).toColor();

  static double _hue(Color accent) => HSLColor.fromColor(accent).hue;

  /// 본문 보조 텍스트(부제/라벨) — 기존 black54 / white54 대체.
  static Color muted(Color accent, bool isDark) =>
      _muted.putIfAbsent((accent, isDark), () {
        final h = _hue(accent);
        return isDark ? _tint(h, 0.05, 0.64) : _tint(h, 0.06, 0.44);
      });

  /// 더 흐린 텍스트/아이콘(힌트/비활성) — 기존 grey / white38 대체.
  static Color faint(Color accent, bool isDark) =>
      _faint.putIfAbsent((accent, isDark), () {
        final h = _hue(accent);
        return isDark ? _tint(h, 0.04, 0.50) : _tint(h, 0.05, 0.60);
      });

  /// 구분선 — 기존 grey[300] / white12 대체.
  static Color divider(Color accent, bool isDark) =>
      _divider.putIfAbsent((accent, isDark), () {
        return isDark
            ? Colors.white.withValues(alpha: 0.10)
            : _tint(_hue(accent), 0.05, 0.90);
      });

  /// 옅은 채움 배경(입력 필드/타일) — 기존 grey[100] / Color(0xFF3D3760) 대체.
  static Color fill(Color accent, bool isDark) =>
      _fill.putIfAbsent((accent, isDark), () {
        final h = _hue(accent);
        return isDark ? _tint(h, 0.06, 0.26) : _tint(h, 0.05, 0.965);
      });

  /// 밝은 배경 위 본문 글자색을, 주어진 색(일정 색)에서 파생한 어두운 톤으로.
  /// 달력 셀의 '시간 일정' 바처럼 배경 채움 없이 글자만 얹을 때 사용.
  static Color onSurfaceFrom(Color base) =>
      _onSurfaceFrom.putIfAbsent(base, () {
        final hsl = HSLColor.fromColor(base);
        return HSLColor.fromAHSL(
          1,
          hsl.hue,
          (hsl.saturation * 0.55).clamp(0.0, 0.5),
          0.26,
        ).toColor();
      });

  /// 위 색의 보조(시간 등) 톤.
  static Color subduedFrom(Color base) => _subduedFrom.putIfAbsent(base, () {
        final hsl = HSLColor.fromColor(base);
        return HSLColor.fromAHSL(
          1,
          hsl.hue,
          (hsl.saturation * 0.45).clamp(0.0, 0.45),
          0.46,
        ).toColor();
      });
}

/// 바텀시트/다이얼로그 표면색 — 여러 파일에 리터럴로 흩어져 있던
/// `isDark ? const Color(0xFF2A2640) : Colors.white` 조합을 한곳으로.
/// 값 자체는 그대로 유지하므로 렌더링 결과는 동일하다.
class AppSurface {
  static const Color _darkSheet = Color(0xFF2A2640);

  static Color sheet(bool isDark) => isDark ? _darkSheet : Colors.white;
}

/// 일·토요일 및 공휴일 날짜 라벨 색 규칙 — 달력 셀과 요일 헤더 네 곳에
/// 흩어져 있던 동일한 규칙을 한곳으로. 해당 없으면 null을 반환해
/// 호출부가 각자의 기본색을 유지하도록 한다(렌더링 동일).
Color? dayLabelColor(int weekday, {bool isHoliday = false}) {
  if (weekday == DateTime.sunday || isHoliday) return Colors.redAccent;
  if (weekday == DateTime.saturday) return Colors.blueAccent;
  return null;
}

/// CalendarTheme을 가진 위젯에서 짧게 쓰기 위한 편의 확장.
extension CalendarThemeTokens on CalendarTheme {
  Color get tMuted => AppNeutral.muted(primaryAccent, isDark);
  Color get tFaint => AppNeutral.faint(primaryAccent, isDark);
  Color get tDivider => AppNeutral.divider(primaryAccent, isDark);
  Color get tFill => AppNeutral.fill(primaryAccent, isDark);

  /// 시트/다이얼로그 배경: 테마가 지정한 값이 있으면 그것, 없으면 공용 표면색.
  Color get tSheet => bottomSheetBg ?? AppSurface.sheet(isDark);
}
