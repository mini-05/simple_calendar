// v4.5.3
// gemini_splash_utils.dart
// lib/ui/splash/splash_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;

// ── ISO 8601 주차 계산 ──
int isoWeek(DateTime d) {
  final startOfYear = DateTime(d.year, 1, 1);
  final dayOfYear = d.difference(startOfYear).inDays + 1;
  final weekNum = ((dayOfYear - d.weekday + 10) / 7).floor();
  return weekNum < 1 ? isoWeek(DateTime(d.year - 1, 12, 31)) : weekNum;
}

const _weekdayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const _monthLabels = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

String getWeekday(DateTime d) => _weekdayLabels[d.weekday - 1];
String getMonth(DateTime d) => _monthLabels[d.month - 1];
String getWeekStr(DateTime d) => '${isoWeek(d)}주차';

ui.ImageFilter noBlurOnWeb() =>
    kIsWeb
        ? ui.ImageFilter.blur(sigmaX: 0.1, sigmaY: 0.1)
        : ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20);

// ── 공통 글로우 펄스 애니메이션 ──
class GlowPulse extends StatelessWidget {
  final Widget child;
  final Color color;
  final AnimationController ctrl;

  const GlowPulse({
    super.key,
    required this.child,
    required this.color,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ctrl,
    builder: (_, child) {
      final v = ctrl.value;
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .15 + .25 * v),
              blurRadius: 40 + 40 * v,
              spreadRadius: 0,
            ),
          ],
        ),
        child: child,
      );
    },
    child: child,
  );
}
