# Claude 세션 요약 — v4.3.4 (2026-02-28)

## 작업 버전
v4.3.3 → v4.3.4

## 변경 파일 목록

| 파일 | 경로 | 주요 변경 |
|---|---|---|
| models.dart | lib/models/models.dart | 기본 navMode: arrow → swipeHorizontal |
| providers.dart | lib/providers/providers.dart | 첫 실행 시 Platform 분기 (Android=삼성, iOS=애플) |
| services.dart | lib/services/services.dart | isFirstRun() 추가, 백업파일명 simple_calendar_backup.ics |
| calendar_screen.dart | lib/ui/calendar_screen.dart | AppBar 년/월 통합 UI (아래 상세) |
| pubspec.yaml | pubspec.yaml | 버전 4.3.4+1, 헤더 vx.x.x |
| memory.md | memory.md | 규칙 업데이트, v4.3.4 changelog 추가 |

---

## 상세 변경 내용

### models.dart
- `calendarNavMode` 기본값: `CalendarNavMode.arrow` → `CalendarNavMode.swipeHorizontal`
- `fromJson` fallback index: `0`(arrow) → `2`(swipeHorizontal)
- 헤더: `v4.1.0-fix1` → `vx.x.x`, `claude_models.dart`

### providers.dart
- `import 'dart:io' show Platform;` 추가
- `_init()` 수정: `AppSettingsStorage.isFirstRun()` 호출 → true면 Platform 분기로 기본 테마 결정 후 저장
- 헤더: `v4.3.3 gemini_providers.dart` → `vx.x.x claude_providers.dart`

### services.dart
- `AppSettingsStorage`에 `isFirstRun()` 메서드 추가:
  ```dart
  static Future<bool> isFirstRun() async {
    final raw = await _ss.read(key: _key);
    return raw == null;
  }
  ```
- ICS 내보내기 파일명: `my_calendar_backup.ics` → `simple_calendar_backup.ics`
- 헤더: `v4.3.3 gemini_services.dart` → `vx.x.x claude_services.dart`

### calendar_screen.dart
- `_buildAppBar` 전면 수정:
  - 스와이프(좌우/상하) 모드: AppBar title에 "2026년 2월" 표시, 탭 → `_showMonthPicker`
  - 화살표 모드: AppBar title에 "2026년" 표시, 탭 → `_showYearPicker` (새로 추가)
  - 공통 dateTextStyle: fontSize 22, fontWeight w300
- `_showYearPicker()` 신규 추가: CupertinoDatePicker(monthYear) 사용, 년도만 변경 (월 유지)
- `_buildCalendarSection` 수정:
  - 화살표 모드: 달력 위에 "2월" 텍스트 표시 (fontSize 22, w300), 탭 → `_showMonthPicker`
  - 스와이프 모드: 달력 위 헤더 제거 (SizedBox.shrink) — AppBar에서 처리
- `_buildArrowCalendar` headerStyle 수정: titleTextFormatter → 빈 문자열, titleTextStyle fontSize 0 (화살표 chevron만 유지)
- 헤더: `v4.3.3 gemini_calendar_screen.dart` → `vx.x.x claude_calendar_screen.dart`

### pubspec.yaml
- `version: 4.1.0+10` → `version: 4.3.4+1`
- 헤더 주석 `# vx.x.x` 추가
- description 간소화

### memory.md
- **규칙 5 추가:** 파일 헤더 규칙 명문화 (claude_* / gemini_* 구분)
- **v4.3.4 changelog** 추가
- Changelog 초기 버전 압축 정리

---

## Gemini에게 전달할 사항

1. **providers.dart** — `dart:io` import 추가됨. `_init()`에 `isFirstRun()` 호출 로직 있음. 기존 `_init` 구조(Future.wait 병렬 처리) 유지.

2. **services.dart** — `AppSettingsStorage` 클래스에 `isFirstRun()` 메서드 추가됨. `save()` 메서드 바로 뒤에 위치.

3. **calendar_screen.dart** — `_buildAppBar` 시그니처 동일. `_showYearPicker` 신규 메서드 추가. 기존 `_showMonthPicker`는 그대로 유지.

4. **ICS 백업 파일명** — `my_calendar_backup.ics` → `simple_calendar_backup.ics` 전체 교체 필요.

5. **버전 표기 규칙** — 모든 파일 헤더 1번째 줄 `// vx.x.x`, 수정 시 숫자 올림 (`-fix` 꼬리표 금지).

---

## 미적용 항목 (추후 작업)
- README_MyCalendar_v4.md 버전 업데이트 (v4.3.4 반영)
- holidays.dart 헤더 `gemini_` → 작성자 확인 후 통일
- date_formatter.dart / slot_calculator.dart 헤더 버전 통일
