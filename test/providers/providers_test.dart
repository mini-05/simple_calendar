// v4.3.6
// gemini_providers_test.dart
// test/providers/providers_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_calendar/models/models.dart';

void main() {
  group('AppSettings (Provider State) - 상태 변이 및 비즈니스 로직 검증', () {
    test(
        '1. 무음 모드(globalSilentMode) 활성화 시, 기존 설정과 무관하게 effectiveMode는 강제로 silent가 되어야 한다',
        () {
      // 기존 사용자가 소리와 진동을 모두 켜둔 상태 (Riverpod State)
      const initialSettings = AppSettings(
        soundEnabled: true,
        vibrationEnabled: true,
        globalSilentMode: false,
      );

      expect(initialSettings.effectiveMode, AlarmMode.soundAndVibration);

      // 상단 패널에서 '무음 모드' 스위치를 ON (copyWith를 통한 상태 변이)
      final silentSettings = initialSettings.copyWith(globalSilentMode: true);

      // 검증: 내부의 소리/진동 속성이 true로 남아있더라도, 최종 출력되는 알람 모드는 무조건 silent여야 함
      expect(silentSettings.effectiveMode, AlarmMode.silent,
          reason: 'globalSilentMode가 켜지면 무조건 silent를 반환해야 합니다.');
    });

    test('2. 세부 알람 옵션(소리/진동) 조합에 따른 effectiveMode 상태 변이 완벽 검증', () {
      // Dart 3.0 Records 적용
      final testCases = [
        (
          description: '소리O, 진동O -> soundAndVibration',
          settings: const AppSettings(
              soundEnabled: true,
              vibrationEnabled: true,
              globalSilentMode: false),
          expected: AlarmMode.soundAndVibration,
        ),
        (
          description: '소리O, 진동X -> soundOnly',
          settings: const AppSettings(
              soundEnabled: true,
              vibrationEnabled: false,
              globalSilentMode: false),
          expected: AlarmMode.soundOnly,
        ),
        (
          description: '소리X, 진동O -> vibrationOnly',
          settings: const AppSettings(
              soundEnabled: false,
              vibrationEnabled: true,
              globalSilentMode: false),
          expected: AlarmMode.vibrationOnly,
        ),
        (
          description: '소리X, 진동X -> silent',
          settings: const AppSettings(
              soundEnabled: false,
              vibrationEnabled: false,
              globalSilentMode: false),
          expected: AlarmMode.silent,
        ),
      ];

      for (final tc in testCases) {
        expect(tc.settings.effectiveMode, tc.expected, reason: tc.description);
      }
    });

    test('3. copyWith를 통한 상태 객체 불변성(Immutability) 및 깊은 복사 검증', () {
      // Riverpod이 상태 변화를 감지하려면 객체의 주소값(Reference)이 달라져야 합니다.
      const original = AppSettings(
        currentTheme: AppTheme.samsung,
        calendarNavMode: CalendarNavMode.swipeHorizontal,
      );

      // 사용자가 앱 설정에서 테마만 '애플'로 변경한 상황
      final updated = original.copyWith(currentTheme: AppTheme.apple);

      expect(updated.currentTheme, AppTheme.apple,
          reason: '변경된 필드는 새 값이 적용되어야 합니다.');
      expect(updated.calendarNavMode, CalendarNavMode.swipeHorizontal,
          reason: '변경하지 않은 필드는 원본 값을 유지해야 합니다.');

      // 💡 [가장 중요한 Riverpod 원칙 검증]
      expect(identical(original, updated), false,
          reason:
              'copyWith는 기존 객체를 수정하지 않고 항상 새로운 불변 객체를 반환해야 Riverpod이 UI를 리빌드합니다.');
    });
  });
}
