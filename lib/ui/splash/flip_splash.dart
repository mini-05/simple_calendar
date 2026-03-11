// v4.5.4
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
    // 💡 애니메이션 시간을 조금 더 여유롭게 주어 플립되는 맛을 살립니다.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 💡 [에러 수정] easeOutBounce는 존재하지 않으므로 bounceOut으로 교체
    _flip = CurvedAnimation(parent: _ctrl, curve: Curves.bounceOut);

    // 💡 [타이밍 최적화] 화면 렌더링 안정화 후 0.4초 뒤 애니메이션 시작 (총 2.2초 대기 동기화)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _ctrl.forward();
    });
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
                // 💡 리얼 플립 시계 효과 위젯 적용
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

// 💡 진정한 플립 애니메이션 컴포넌트
class _RealFlipClock extends StatelessWidget {
  final String digit;
  final Animation<double> animation;

  const _RealFlipClock({required this.digit, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // 애니메이션 값 (0.0 -> 1.0)
        final val = animation.value;

        // 위쪽 절반 카드는 0 -> 90도 (절반)까지만 넘어가고 사라짐
        final upperFold = (val < 0.5) ? val * 2 : 1.0;

        // 아래쪽 절반 카드는 90도에서 대기하다가 90 -> 0도로 착! 하고 떨어짐
        final lowerFold = (val > 0.5) ? (1.0 - val) * 2 : 1.0;

        return SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            children: [
              // 1. (배경) 항상 보이는 온전한 글자 배경
              _buildHalfDigit(digit, isTop: true, isBackground: true),
              _buildHalfDigit(digit, isTop: false, isBackground: true),

              // 2. (위쪽 절반 애니메이션) 위에서 90도로 넘어감
              if (val <= 0.5)
                Transform(
                  alignment: Alignment.bottomCenter, // 회전축: 정중앙 가로선
                  transform:
                      Matrix4.identity()
                        ..setEntry(3, 2, 0.002) // 원근감
                        ..rotateX(math.pi / 2 * upperFold), // 0 -> 90도
                  child: _buildHalfDigit(digit, isTop: true),
                ),

              // 3. (아래쪽 절반 애니메이션) 90도에서 0도로 착 떨어짐
              if (val > 0.5)
                Transform(
                  alignment: Alignment.topCenter, // 회전축: 정중앙 가로선
                  transform:
                      Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX(-math.pi / 2 * lowerFold), // -90도 -> 0도
                  child: _buildHalfDigit(digit, isTop: false),
                ),

              // 중앙 절취선 (시계 가운데 갈라진 선)
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 2,
                  width: double.infinity,
                  color: Colors.blue[800], // 배경색과 약간 다른 짙은 선
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 글자의 위쪽/아래쪽 절반을 잘라내는 헬퍼 위젯
  Widget _buildHalfDigit(
    String text, {
    required bool isTop,
    bool isBackground = false,
  }) {
    return ClipRect(
      child: Align(
        alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
        heightFactor: 0.5, // 💡 핵심: 위아래 정확히 절반만 보이게 자름!
        child: Container(
          width: 180,
          height: 180,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                isBackground
                    ? Colors.transparent
                    : Colors.blue[600]?.withValues(alpha: 0.2), // 넘어가는 카드 느낌
            borderRadius: BorderRadius.circular(16),
          ),
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
              shadows: const [Shadow(blurRadius: 10, color: Color(0x33000000))],
            ),
          ),
        ),
      ),
    );
  }
}
