// v4.5.3
// gemini_flip_splash.dart
// lib/ui/splash/flip_splash.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'splash_utils.dart';

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
    // 💡 스플래시 총 대기 시간(2.2초)에 맞춰, 2.0초 동안 묵직하고 부드럽게 플립되도록 설정
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    // 애니메이션이 천천히 시작해서 부드럽게 가속하다 감속하며 닫히는 커브
    _flip = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);

    // 화면이 뜨자마자 즉시 플립 애니메이션 시작
    _ctrl.forward();
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
      body: Stack(
        children: [
          Positioned(
            top: 56,
            right: 28,
            child: Row(
              children: [
                _iconBtn(Icons.add),
                const SizedBox(width: 10),
                _iconBtn(Icons.search),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 💡 오늘 날짜가 오늘 날짜 위로 접히는 리얼 플립 위젯
                _RealFlipClock(
                  digit: now.day.toString().padLeft(2, '0'),
                  animation: _flip,
                ),
                const SizedBox(height: 12),
                Text(
                  '${getWeekday(now)}  ${getMonth(now)}',
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
                  getWeekStr(now),
                  style: TextStyle(
                    fontFamily: 'CourierPrime',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: .55),
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _bottomBar()),
        ],
      ),
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
        Row(
          children: [
            Icon(
              Icons.wb_sunny_outlined,
              color: Colors.white.withValues(alpha: .65),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              '맑음',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .65),
                fontSize: 13,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              width: 90,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: .7,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.check,
              color: Colors.white.withValues(alpha: .75),
              size: 16,
            ),
          ],
        ),
      ],
    ),
  );
}

class _RealFlipClock extends StatelessWidget {
  final String digit;
  final Animation<double> animation;

  const _RealFlipClock({required this.digit, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final val = animation.value;
        final isFirstHalf = val < 0.5;

        final topAngle =
            isFirstHalf ? (val * 2 * (math.pi / 2)) : (math.pi / 2);
        final bottomAngle =
            !isFirstHalf
                ? ((1.0 - (val - 0.5) * 2) * (-math.pi / 2))
                : (-math.pi / 2);

        // 💡 디테일: 오늘 날짜 위로 동일한 오늘 날짜가 덮일 때, 입체감을 위해 넘어가는 면에 그림자(어두워짐)를 줍니다.
        final topDarkness = isFirstHalf ? (val * 2 * 0.35) : 0.0;
        final bottomDarkness =
            !isFirstHalf ? ((1.0 - (val - 0.5) * 2) * 0.35) : 0.0;

        return SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            children: [
              // 베이스 뼈대: 온전한 오늘 날짜
              _buildHalfDigit(digit, isTop: true, isBackground: true),
              _buildHalfDigit(digit, isTop: false, isBackground: true),

              // 접히는 위쪽 절반
              if (isFirstHalf)
                Transform(
                  alignment: Alignment.bottomCenter,
                  transform:
                      Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX(topAngle),
                  child: _buildHalfDigit(
                    digit,
                    isTop: true,
                    darkness: topDarkness,
                  ),
                ),

              // 떨어지는 아래쪽 절반
              if (!isFirstHalf)
                Transform(
                  alignment: Alignment.topCenter,
                  transform:
                      Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX(bottomAngle),
                  child: _buildHalfDigit(
                    digit,
                    isTop: false,
                    darkness: bottomDarkness,
                  ),
                ),

              // 중앙 절취선
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 2,
                  width: double.infinity,
                  color: const Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHalfDigit(
    String text, {
    required bool isTop,
    bool isBackground = false,
    double darkness = 0.0,
  }) {
    return ClipRect(
      child: Align(
        alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
        heightFactor: 0.5,
        child: Container(
          width: 180,
          height: 180,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                isBackground
                    ? Colors.transparent
                    : const Color(0xFF1E88E5).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'BebasNeue',
                    fontSize: 160,
                    color:
                        isBackground
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.white,
                    height: 1.0,
                    letterSpacing: -6,
                    shadows: const [
                      Shadow(blurRadius: 10, color: Color(0x33000000)),
                    ],
                  ),
                ),
              ),
              if (darkness > 0) // 플립될 때 생기는 그림자
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: darkness),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
