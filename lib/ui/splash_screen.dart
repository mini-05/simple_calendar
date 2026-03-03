// v4.4.1
// claude_splash_screen.dart
// lib/ui/splash_screen.dart
// ignore_for_file: curly_braces_in_flow_control_structures
// [v4.4.1 버그수정]
// - Bug1: CircleSplash _pulseCtrl dead code 제거 (_GlowPulse 내부 자체 ctrl 사용)
// - Bug2: CircleSplash 유리 오버레이 BackdropFilter 추가 (blur 없이 색상만 있던 문제)

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
// 💡 미사용 import '../theme/app_theme.dart'; 제거 완료
import 'calendar_screen.dart';

// ── ISO 8601 주차 계산 ────────────────────────────────────────────
int _isoWeek(DateTime d) {
  final startOfYear = DateTime(d.year, 1, 1);
  final dayOfYear = d.difference(startOfYear).inDays + 1;
  final weekNum = ((dayOfYear - d.weekday + 10) / 7).floor();
  return weekNum < 1 ? _isoWeek(DateTime(d.year - 1, 12, 31)) : weekNum;
}

// ── 날짜 포맷 헬퍼 ───────────────────────────────────────────────
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
  'DEC'
];
String _weekday(DateTime d) => _weekdayLabels[d.weekday - 1];
String _month(DateTime d) => _monthLabels[d.month - 1];
String _weekStr(DateTime d) => '${_isoWeek(d)}주차';

// ════════════════════════════════════════════════════════════════
// SplashScreen — 진입점
// ════════════════════════════════════════════════════════════════

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _splashDuration = Duration(milliseconds: 2200);

  @override
  void initState() {
    super.initState();
    Future.delayed(_splashDuration, _goToCalendar);
  }

  void _goToCalendar() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CalendarScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(settingsProvider).dynamicWidgetTheme;
    return switch (theme) {
      WidgetTheme.flip => const FlipSplash(),
      WidgetTheme.circle => const CircleSplash(),
      WidgetTheme.classic => const ClassicSplash(),
      WidgetTheme.astronomical => const AstronomicalSplash(),
    };
  }
}

// ════════════════════════════════════════════════════════════════
// A · FlipSplash — 플립 시계 스타일
// ════════════════════════════════════════════════════════════════

class FlipSplash extends StatefulWidget {
  const FlipSplash({super.key});

  @override
  State<FlipSplash> createState() => _FlipSplashState();
}

class _FlipSplashState extends State<FlipSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _flip;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _flip = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutBack);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const bg = Color(0xFF1E88E5);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        Positioned(
          top: 56,
          right: 28,
          child: Row(children: [
            _iconBtn(Icons.add),
            const SizedBox(width: 10),
            _iconBtn(Icons.search),
          ]),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _flip,
            builder: (_, __) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX((_flip.value - 0.5) * 0.4),
              child: _dateColumn(now),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _bottomBar(),
        ),
      ]),
    );
  }

  Widget _iconBtn(IconData icon) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      );

  Widget _dateColumn(DateTime now) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(alignment: Alignment.center, children: [
            Text(
              now.day.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 160,
                color: Colors.white,
                height: .9,
                letterSpacing: -6,
                shadows: [Shadow(blurRadius: 24, color: Color(0x33000000))],
              ),
            ),
            Positioned(
              left: -20,
              right: -20,
              child: Container(
                  height: 1.5, color: Colors.white.withValues(alpha: .15)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            '${_weekday(now)}  ${_month(now)}',
            style: const TextStyle(
              fontFamily: 'CourierPrime',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _weekStr(now),
            style: TextStyle(
              fontFamily: 'CourierPrime',
              fontSize: 13,
              color: Colors.white.withValues(alpha: .55),
              letterSpacing: 3,
            ),
          ),
        ],
      );

  Widget _bottomBar() => Container(
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: .15)],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(Icons.wb_sunny_outlined,
                  color: Colors.white.withValues(alpha: .65), size: 18),
              const SizedBox(width: 6),
              Text('맑음',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: .65),
                      fontSize: 13)),
            ]),
            Row(children: [
              Container(
                width: 90,
                height: 7,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(4)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: .7,
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4))),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.check,
                  color: Colors.white.withValues(alpha: .75), size: 16),
            ]),
          ],
        ),
      );
}

// ════════════════════════════════════════════════════════════════
// B · CircleSplash — 영롱한 액체 그라데이션
// ════════════════════════════════════════════════════════════════

class CircleSplash extends StatefulWidget {
  const CircleSplash({super.key});

  @override
  State<CircleSplash> createState() => _CircleSplashState();
}

class _CircleSplashState extends State<CircleSplash>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  // [v4.4.1 Bug1 수정] _pulseCtrl 제거 — 펄스는 _GlowPulse 위젯 내부 ctrl이 전담

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFF020208),
      body: Stack(children: [
        ImageFiltered(
          imageFilter: _noBlurOnWeb(),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = _ctrl.value;
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _LiquidGradientPainter(t),
              );
            },
          ),
        ),
        Positioned(
          left: 32,
          right: 32,
          top: 80,
          bottom: 80,
          // [v4.4.1 Bug2 수정] BackdropFilter 추가 — 기존은 blur 없이 색상 패널만 존재
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: _noBlurOnWeb(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: .18), width: 1),
                ),
              ),
            ),
          ),
        ),
        Center(
          child: _GlowPulse(
            color: Colors.white,
            child: _dateColumn(now),
          ),
        ),
      ]),
    );
  }

  Widget _dateColumn(DateTime now) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            now.day.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 160,
              color: Colors.white,
              height: .9,
              letterSpacing: -4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _weekday(now),
            style: TextStyle(
              fontFamily: 'CourierPrime',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: .9),
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _weekStr(now),
            style: TextStyle(
              fontFamily: 'CourierPrime',
              fontSize: 13,
              color: Colors.white.withValues(alpha: .52),
              letterSpacing: 2,
            ),
          ),
        ],
      );
}

class _LiquidGradientPainter extends CustomPainter {
  final double t;
  _LiquidGradientPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = [
      _node(
          size,
          .28 + .12 * math.sin(t * math.pi * 2),
          .28 + .1 * math.cos(t * math.pi * 2.3),
          const Color(0xFFFF0080),
          .85,
          size.width * .38),
      _node(
          size,
          .72 - .1 * math.cos(t * math.pi * 1.7),
          .62 + .12 * math.sin(t * math.pi * 1.5),
          const Color(0xFF00C8FF),
          .85,
          size.width * .45),
      _node(
          size,
          .42 + .08 * math.sin(t * math.pi * 2.8),
          .78 - .1 * math.cos(t * math.pi * 2.1),
          const Color(0xFF6400FF),
          .85,
          size.width * .38),
      _node(
          size,
          .78 - .09 * math.cos(t * math.pi * 1.9),
          .22 + .08 * math.sin(t * math.pi * 2.5),
          const Color(0xFFFFC800),
          .55,
          size.width * .30),
      _node(
          size,
          .55 + .06 * math.sin(t * math.pi * 3.1),
          .50 - .07 * math.cos(t * math.pi * 2.7),
          const Color(0xFF00FF96),
          .4,
          size.width * .28),
    ];

    for (final n in nodes) {
      canvas.drawCircle(n.$1, n.$2, Paint()..shader = n.$3);
    }
  }

  (Offset, double, Shader) _node(
      Size s, double fx, double fy, Color c, double opacity, double radius) {
    final center = Offset(s.width * fx, s.height * fy);
    return (
      center,
      radius,
      RadialGradient(colors: [c.withValues(alpha: opacity), Colors.transparent])
          .createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_LiquidGradientPainter old) => old.t != t;
}

// ════════════════════════════════════════════════════════════════
// C · ClassicSplash — 4개 링 독자 회전
// ════════════════════════════════════════════════════════════════

class ClassicSplash extends StatefulWidget {
  const ClassicSplash({super.key});

  @override
  State<ClassicSplash> createState() => _ClassicSplashState();
}

class _ClassicSplashState extends State<ClassicSplash>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  static const _specs = [
    (11000, false),
    (7000, true),
    (17000, false),
    (5000, true),
  ];

  @override
  void initState() {
    super.initState();
    _ctrls = _specs
        .map((s) => AnimationController(
              vsync: this,
              duration: Duration(milliseconds: s.$1),
            )..repeat())
        .toList();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final size = MediaQuery.of(context).size;
    final cx = size.width / 2, cy = size.height / 2;

    const ringDefs = [
      (390.0, Color(0xFF03C75A), 2.5),
      (272.0, Color(0xFFFA233B), 2.5),
      (450.0, Color(0xFF2196F3), 2.0),
      (188.0, Color(0xFFFFB74D), 2.5),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0E0F1A),
      body: Stack(children: [
        ...List.generate(4, (i) {
          final (dia, color, stroke) = ringDefs[i];
          final reverse = _specs[i].$2;
          return AnimatedBuilder(
            animation: _ctrls[i],
            builder: (_, __) {
              final angle = (reverse ? -1 : 1) * _ctrls[i].value * 2 * math.pi;
              return Positioned(
                left: cx - dia / 2,
                top: cy - dia / 2,
                child: Transform.rotate(
                  angle: angle,
                  child: CustomPaint(
                      size: Size(dia, dia),
                      painter: _ArcPainter(color, stroke)),
                ),
              );
            },
          );
        }),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 52, vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: .08)),
                ),
                child: _dateColumn(now),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _dateColumn(DateTime now) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            now.day.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 120,
              color: Colors.white,
              height: .9,
              letterSpacing: -4,
              shadows: [Shadow(blurRadius: 16, color: Color(0x80000000))],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _weekday(now),
            style: TextStyle(
              fontFamily: 'CourierPrime',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: .85),
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _weekStr(now),
            style: TextStyle(
              fontFamily: 'CourierPrime',
              fontSize: 12,
              color: Colors.white.withValues(alpha: .42),
              letterSpacing: 2,
            ),
          ),
        ],
      );
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _ArcPainter(this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .05),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      math.pi * .7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

// ════════════════════════════════════════════════════════════════
// D · AstronomicalSplash — 성운 + 글로우 링 + 별빛
// ════════════════════════════════════════════════════════════════

class AstronomicalSplash extends StatefulWidget {
  const AstronomicalSplash({super.key});

  @override
  State<AstronomicalSplash> createState() => _AstronomicalSplashState();
}

class _AstronomicalSplashState extends State<AstronomicalSplash>
    with TickerProviderStateMixin {
  late final List<AnimationController> _rings;
  late final AnimationController _nebCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _starCtrl;

  final List<_StarData> _stars = List.generate(45, (_) {
    final rng = math.Random();
    return _StarData(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: rng.nextDouble() * 2.2 + 0.8,
      phaseOffset: rng.nextDouble(),
    );
  });

  @override
  void initState() {
    super.initState();
    _rings = [
      AnimationController(vsync: this, duration: const Duration(seconds: 14))
        ..repeat(),
      AnimationController(vsync: this, duration: const Duration(seconds: 9))
        ..repeat(),
      AnimationController(vsync: this, duration: const Duration(seconds: 22))
        ..repeat(),
    ];
    _nebCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..repeat(reverse: true);
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3500))
      ..repeat(reverse: true);
    _starCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    for (final c in _rings) {
      c.dispose();
    }
    _nebCtrl.dispose();
    _pulseCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final size = MediaQuery.of(context).size;
    final cx = size.width / 2, cy = size.height / 2;

    const ringDias = [340.0, 230.0, 410.0];
    const ringColors = [
      Color(0xFFFA233B),
      Color(0xFFFFB74D),
      Color(0xFF2196F3)
    ];
    const ringReverse = [false, true, false];

    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: Stack(children: [
        AnimatedBuilder(
          animation: _nebCtrl,
          builder: (_, __) =>
              CustomPaint(size: size, painter: _NebulaPainter(_nebCtrl.value)),
        ),
        AnimatedBuilder(
          animation: _starCtrl,
          builder: (_, __) => CustomPaint(
              size: size, painter: _StarsPainter(_stars, _starCtrl.value)),
        ),
        ...List.generate(3, (i) {
          final dia = ringDias[i],
              color = ringColors[i],
              reverse = ringReverse[i];
          return AnimatedBuilder(
            animation: _rings[i],
            builder: (_, __) {
              final angle = (reverse ? -1 : 1) * _rings[i].value * 2 * math.pi;
              return Positioned(
                left: cx - dia / 2,
                top: cy - dia / 2,
                child: Transform.rotate(
                  angle: angle,
                  child: CustomPaint(
                      size: Size(dia, dia), painter: _GlowRingPainter(color)),
                ),
              );
            },
          );
        }),
        Center(
          child: _GlowPulse(
            color: const Color(0xFFFA233B),
            child: _dateColumn(now),
          ),
        ),
      ]),
    );
  }

  Widget _dateColumn(DateTime now) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            now.day.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 160,
              color: Colors.white,
              height: .9,
              letterSpacing: -4,
              shadows: [
                Shadow(blurRadius: 40, color: Color(0x99FA233B)),
                Shadow(blurRadius: 10, color: Color(0x44FA233B))
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _weekday(now),
            style: TextStyle(
              fontFamily: 'CourierPrime',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: .85),
              letterSpacing: 4,
              shadows: [
                Shadow(
                    blurRadius: 8,
                    color: const Color(0xFFFA233B).withValues(alpha: .3))
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _weekStr(now),
            style: TextStyle(
              fontFamily: 'CourierPrime',
              fontSize: 13,
              color: const Color(0xFFFFB74D).withValues(alpha: .65),
              letterSpacing: 2,
            ),
          ),
        ],
      );
}

class _NebulaPainter extends CustomPainter {
  final double t;
  _NebulaPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    void ellipse(double fx, double fy, double rx, double ry, Color c) {
      final center = Offset(size.width * fx, size.height * fy);
      final rect =
          Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(colors: [c, Colors.transparent])
              .createShader(rect),
      );
    }

    final scale = 1.0 + 0.06 * math.sin(t * math.pi);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-size.width / 2, -size.height / 2);

    ellipse(.30, .25, size.width * .55, size.height * .5,
        const Color(0xFFFA233B).withValues(alpha: .13));
    ellipse(.70, .70, size.width * .55, size.height * .5,
        const Color(0xFF2196F3).withValues(alpha: .10));
    ellipse(.50, .50, size.width * .5, size.height * .5,
        const Color(0xFFFFB74D).withValues(alpha: .07));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NebulaPainter old) => old.t != t;
}

class _GlowRingPainter extends CustomPainter {
  final Color color;
  _GlowRingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      math.pi * .8,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = color.withValues(alpha: .4),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      math.pi * .8,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: .55),
    );
  }

  @override
  bool shouldRepaint(_GlowRingPainter old) => old.color != color;
}

class _StarData {
  final double x, y, size, phaseOffset;
  _StarData(
      {required this.x,
      required this.y,
      required this.size,
      required this.phaseOffset});
}

// 💡 [버그수정 1] Claude가 누락시켰던 별 그리기 화가(Painter)를 최상위 레벨에 완벽하게 선언
class _StarsPainter extends CustomPainter {
  final List<_StarData> stars;
  final double t;

  _StarsPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final star in stars) {
      final cx = star.x * size.width;
      final cy = star.y * size.height;
      // phase: 0.0 ~ 1.0 사이를 반복하며 반짝임 효과
      final phase = (t + star.phaseOffset) % 1.0;
      final opacity = 0.08 + 0.92 * math.sin(phase * math.pi);
      final scale = 0.8 + 0.5 * math.sin(phase * math.pi);

      paint.color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(cx, cy), (star.size / 2) * scale, paint);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.t != t;
}

// ════════════════════════════════════════════════════════════════
// 공통 유틸
// ════════════════════════════════════════════════════════════════

// [v4.4.1 Bug1 수정] StatelessWidget → StatefulWidget 변환
// 기존: 외부 ctrl을 주입받아 사용 (CircleSplash._pulseCtrl dead code 유발)
// 수정: 자체 AnimationController를 보유하여 독립적으로 펄스 구동
class _GlowPulse extends StatefulWidget {
  final Widget child;
  final Color color;

  const _GlowPulse({required this.child, required this.color});

  @override
  State<_GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<_GlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          final v = _ctrl.value;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: .15 + .25 * v),
                  blurRadius: 40 + 40 * v,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: child,
          );
        },
        child: widget.child,
      );
}

// 💡 [버그수정 4] 실제 kIsWeb 환경을 검사하여 웹에서만 블러를 최소화하도록 수정 완료!
ui.ImageFilter _noBlurOnWeb() => kIsWeb
    ? ui.ImageFilter.blur(sigmaX: 0.1, sigmaY: 0.1)
    : ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20);