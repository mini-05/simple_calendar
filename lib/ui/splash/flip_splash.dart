// v4.5.8
// gemini_flip_splash.dart
// lib/ui/splash/flip_splash.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'splash_utils.dart'; // 공통 유틸 임포트

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
      duration: const Duration(milliseconds: 1200),
    );

    _flip = CurvedAnimation(parent: _ctrl, curve: Curves.bounceOut);

    // 화면 렌더링되자마자 즉시 시작
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

// 💡 결함이 완전히 수정된 진정한 플립 애니메이션 컴포넌트
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

        final upperFold = (val < 0.5) ? val * 2 : 1.0;
        final lowerFold = (val > 0.5) ? (1.0 - val) * 2 : 1.0;

        return SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            children: [
              // 1. (배경) 항상 존재하는 온전한 형태의 위/아래 베이스 카드
              // 이 두 조각이 만나 완벽하게 균일한 '12'를 형성합니다.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildHalfDigit(digit, isTop: true),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildHalfDigit(digit, isTop: false),
              ),

              // 2. (위쪽 절반 애니메이션) 0도에서 90도로 넘어가는 플립 카드
              // 💡 [버그 픽스] 애니메이션 시작 전(val == 0.0)에는 겹쳐서 색이 2배로 진해지는 것을 막기 위해 숨깁니다.
              if (val > 0.0 && val <= 0.5)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform:
                        Matrix4.identity()
                          ..setEntry(3, 2, 0.002)
                          ..rotateX(math.pi / 2 * upperFold),
                    child: _buildHalfDigit(digit, isTop: true),
                  ),
                ),

              // 3. (아래쪽 절반 애니메이션) 90도에서 0도로 떨어지는 플립 카드
              // 💡 [버그 픽스] 애니메이션 종료 후(val == 1.0)에는 겹쳐서 색이 진해지는 것을 막기 위해 숨깁니다.
              if (val > 0.5 && val < 1.0)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Transform(
                    alignment: Alignment.topCenter,
                    transform:
                        Matrix4.identity()
                          ..setEntry(3, 2, 0.002)
                          ..rotateX(-math.pi / 2 * lowerFold),
                    child: _buildHalfDigit(digit, isTop: false),
                  ),
                ),

              // 중앙 절취선
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 2,
                  width: double.infinity,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 💡 [버그 픽스] isBackground 파라미터를 완전히 제거했습니다!
  // 배경이든 애니메이션 카드든 100% 동일한 하얀색 글자와 파란색 박스를 가집니다.
  Widget _buildHalfDigit(String text, {required bool isTop}) {
    return ClipRect(
      child: Align(
        alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
        heightFactor: 0.5,
        child: Container(
          width: 180,
          height: 180,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blue[600]?.withValues(alpha: 0.2), // 모든 카드가 동일한 배경색
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 160,
              color: Colors.white, // 모든 카드가 100% 순백색 글자
              height: 1.0,
              letterSpacing: -6,
              shadows: [Shadow(blurRadius: 10, color: Color(0x33000000))],
            ),
          ),
        ),
      ),
    );
  }
}
