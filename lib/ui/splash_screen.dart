// v4.5.3
// lib/ui/splash_screen.dart
// [v4.5.3] 스플래시 2.2초 지속 타이밍 고정 및 파일 구조 분리 최적화

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import 'calendar_screen.dart';

// 💡 분리된 유틸과 플립 위젯 임포트
import 'splash/splash_utils.dart';
import 'splash/flip_splash.dart';

// ════════════════════════════════════════════════════════════════
// SplashScreen — 진입점
// ════════════════════════════════════════════════════════════════

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  // 💡 정확히 2.2초 동안 머뭅니다. 이 시간 안에 flip_splash에서 2.0초의 애니메이션이 재생됩니다.
  static const _splashDuration = Duration(milliseconds: 2200);

  @override
  void initState() {
    super.initState();
    final showSplash = ref.read(settingsProvider).showSplash;
    if (showSplash) {
      Future.delayed(_splashDuration, _goToCalendar);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToCalendar());
    }
  }

  void _goToCalendar() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CalendarScreen(),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    if (!settings.showSplash) {
      return const Scaffold(backgroundColor: Colors.transparent);
    }
    return switch (settings.dynamicWidgetTheme) {
      WidgetTheme.flip => const FlipSplash(),
      WidgetTheme.circle => const CircleSplash(),
      WidgetTheme.classic => const ClassicSplash(),
      WidgetTheme.astronomical => const AstronomicalSplash(),
    };
  }
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
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: const Color(0xFF020208),
      body: Stack(
        children: [
          ImageFiltered(
            imageFilter: noBlurOnWeb(),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder:
                  (_, __) => CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: _LiquidGradientPainter(_ctrl.value),
                  ),
            ),
          ),
          Positioned(
            left: 32,
            right: 32,
            top: 80,
            bottom: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .18),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: GlowPulse(
              color: Colors.white,
              ctrl: _pulseCtrl,
              child: _dateColumn(now),
            ),
          ),
        ],
      ),
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
        getWeekday(now),
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
        getWeekStr(now),
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
        size.width * .38,
      ),
      _node(
        size,
        .72 - .1 * math.cos(t * math.pi * 1.7),
        .62 + .12 * math.sin(t * math.pi * 1.5),
        const Color(0xFF00C8FF),
        .85,
        size.width * .45,
      ),
      _node(
        size,
        .42 + .08 * math.sin(t * math.pi * 2.8),
        .78 - .1 * math.cos(t * math.pi * 2.1),
        const Color(0xFF6400FF),
        .85,
        size.width * .38,
      ),
      _node(
        size,
        .78 - .09 * math.cos(t * math.pi * 1.9),
        .22 + .08 * math.sin(t * math.pi * 2.5),
        const Color(0xFFFFC800),
        .55,
        size.width * .30,
      ),
      _node(
        size,
        .55 + .06 * math.sin(t * math.pi * 3.1),
        .50 - .07 * math.cos(t * math.pi * 2.7),
        const Color(0xFF00FF96),
        .4,
        size.width * .28,
      ),
    ];
    for (final n in nodes) {
      canvas.drawCircle(n.$1, n.$2, Paint()..shader = n.$3);
    }
  }

  (Offset, double, Shader) _node(
    Size s,
    double fx,
    double fy,
    Color c,
    double opacity,
    double radius,
  ) {
    final center = Offset(s.width * fx, s.height * fy);
    return (
      center,
      radius,
      RadialGradient(
        colors: [c.withValues(alpha: opacity), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius)),
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
    _ctrls =
        _specs
            .map(
              (s) => AnimationController(
                vsync: this,
                duration: Duration(milliseconds: s.$1),
              )..repeat(),
            )
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
      body: Stack(
        children: [
          ...List.generate(4, (i) {
            final (dia, color, stroke) = ringDefs[i];
            final reverse = _specs[i].$2;
            return AnimatedBuilder(
              animation: _ctrls[i],
              builder:
                  (_, __) => Positioned(
                    left: cx - dia / 2,
                    top: cy - dia / 2,
                    child: Transform.rotate(
                      angle: (reverse ? -1 : 1) * _ctrls[i].value * 2 * math.pi,
                      child: CustomPaint(
                        size: Size(dia, dia),
                        painter: _ArcPainter(color, stroke),
                      ),
                    ),
                  ),
            );
          }),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 52,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                  ),
                ),
                child: _dateColumn(now),
              ),
            ),
          ),
        ],
      ),
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
        getWeekday(now),
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
        getWeekStr(now),
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
    _nebCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
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
      Color(0xFF2196F3),
    ];
    const ringReverse = [false, true, false];

    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _nebCtrl,
            builder:
                (_, __) => CustomPaint(
                  size: size,
                  painter: _NebulaPainter(_nebCtrl.value),
                ),
          ),
          AnimatedBuilder(
            animation: _starCtrl,
            builder:
                (_, __) => CustomPaint(
                  size: size,
                  painter: _StarsPainter(_stars, _starCtrl.value),
                ),
          ),
          ...List.generate(3, (i) {
            final dia = ringDias[i],
                color = ringColors[i],
                reverse = ringReverse[i];
            return AnimatedBuilder(
              animation: _rings[i],
              builder:
                  (_, __) => Positioned(
                    left: cx - dia / 2,
                    top: cy - dia / 2,
                    child: Transform.rotate(
                      angle: (reverse ? -1 : 1) * _rings[i].value * 2 * math.pi,
                      child: CustomPaint(
                        size: Size(dia, dia),
                        painter: _GlowRingPainter(color),
                      ),
                    ),
                  ),
            );
          }),
          Center(
            child: GlowPulse(
              color: const Color(0xFFFA233B),
              ctrl: _pulseCtrl,
              child: _dateColumn(now),
            ),
          ),
        ],
      ),
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
            Shadow(blurRadius: 10, color: Color(0x44FA233B)),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Text(
        getWeekday(now),
        style: TextStyle(
          fontFamily: 'CourierPrime',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: .85),
          letterSpacing: 4,
          shadows: [
            Shadow(
              blurRadius: 8,
              color: const Color(0xFFFA233B).withValues(alpha: .3),
            ),
          ],
        ),
      ),
      const SizedBox(height: 4),
      Text(
        getWeekStr(now),
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
      final rect = Rect.fromCenter(
        center: center,
        width: rx * 2,
        height: ry * 2,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [c, Colors.transparent],
          ).createShader(rect),
      );
    }

    final scale = 1.0 + 0.06 * math.sin(t * math.pi);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-size.width / 2, -size.height / 2);
    ellipse(
      .30,
      .25,
      size.width * .55,
      size.height * .5,
      const Color(0xFFFA233B).withValues(alpha: .13),
    );
    ellipse(
      .70,
      .70,
      size.width * .55,
      size.height * .5,
      const Color(0xFF2196F3).withValues(alpha: .10),
    );
    ellipse(
      .50,
      .50,
      size.width * .5,
      size.height * .5,
      const Color(0xFFFFB74D).withValues(alpha: .07),
    );
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
  _StarData({
    required this.x,
    required this.y,
    required this.size,
    required this.phaseOffset,
  });
}

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
