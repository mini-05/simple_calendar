# Gemini 세션 요약 — v4.3.5 (2026-02-28)

## 작업 버전
v4.3.4 → v4.3.5

## 변경 파일 목록

| 파일 | 경로 | 주요 변경 |
|---|---|---|
| calendar_screen.dart | lib/ui/calendar_screen.dart | 화살표 모드 상단 터치 시 통합 월 피커 출력 |
| providers.dart | lib/providers/providers.dart | Windows 등 기타 OS 초기 실행 시 삼성 테마 적용 로직 강화 |
| models.dart | lib/models/models.dart | Claude가 남긴 if문 중괄호 누락(Lint) 에러 완벽 수정 |
| pubspec.yaml | pubspec.yaml | 버전을 `4.3.5+1`로 변경 (빌드 번호 부활) |
| memory.md | memory.md | Lint 중괄호 강제 규칙 명문화 및 v4.3.5 내역 업데이트 |

---

## 상세 변경 내용

### calendar_screen.dart
- `_showYearPicker` 함수 삭제.
- 화살표 모드에서 `_buildAppBar`의 년도 터치와 `_buildCalendarSection`의 월 터치 동작을 모두 `_showMonthPicker`로 통일 연결.

### providers.dart
- `_init()` 내부의 테마 분기 로직에서, `!kIsWeb && Platform.isIOS`가 아닐 경우 모두 `AppTheme.samsung`이 적용되도록 방어벽 강화. (Windows 등 대응)

### models.dart
- `RecurrenceRule` 내부 확장 로직에서 발견된 `{ }` 블록 누락 코드(`if (until != null && cur.isAfter(until!)) break;`)를 엄격한 Lint 규칙에 맞게 100% 수정.

### pubspec.yaml
- `version: 4.3.4+1` → `version: 4.3.5+1`
- `memory.md`의 새로운 버전 규칙 적용.

---

## (Claude 등 타 AI에게) 전달할 주의 사항
1. **Lint 규칙 절대 엄수:** 코드 내의 어떠한 제어문(`if`, `for` 등)도 중괄호 `{}` 없이 쓰여서는 안 된다. `models.dart`를 클린업 해두었으니 다시 훼손하지 말 것.
2. **UI 모드 통합:** `calendar_screen.dart`의 `_showYearPicker`는 의도적으로 삭제되었으니 복구하지 말 것.


# Gemini 세션 요약 — v4.3.6 (2026-02-28)

## 작업 버전
v4.3.5 → v4.3.6

## 변경 파일 목록

| 파일 | 경로 | 주요 변경 |
|---|---|---|
| services.dart | lib/services/services.dart | ICS 백업 파일명을 요청된 시간 스탬프 포맷으로 동적 생성 처리 |
| pubspec.yaml | pubspec.yaml | 버전 4.3.6+1 및 헤더 갱신 |

---

## 상세 변경 내용

### services.dart
- `IcsService.exportToIcs()` 메서드 내부 수정:
  - 기존의 하드코딩된 `simple_calendar_backup.ics` 파일명을 `My_Calendar(backup)_YYYYMMDD_hhmmss.ics` 형식으로 변경.
  - `DateTime.now()`를 호출하고 `padLeft(2, '0')`를 이용하여 두 자리 숫자로 패딩 된 `yyyyMMdd_hhmmss` 문자열(timestamp)을 구성.

### pubspec.yaml
- 버전을 `4.3.5+1`에서 `4.3.6+1`로 변경.

---

## (Claude 등 타 AI에게) 전달할 주의 사항
- 파일명 규칙이나 `pubspec.yaml` 버전 표기법(`x.x.x+y`)을 임의로 변경하지 말 것.
- `.cursorrules` / `memory.md`의 규칙 7에 따라, 첫 번째 메이저/마이너 버전이 바뀌지 않는 한 문서 전체 출력을 최소화할 것.

# Gemini 세션 요약 — v4.3.6 (2026-02-28)

## 작업 버전
v4.3.5 → v4.3.6

## 변경 파일 목록

| 파일 | 경로 | 주요 변경 |
|---|---|---|
| memory.md | memory.md | v4.3.6 업데이트 내역 추가 및 이전 변천사(v1.0.0~) 상세 복구 |

---

## 상세 변경 내용

### memory.md
- 축약되었던 v1.0.0 ~ v3.1.0 구간의 상세 릴리즈 노트 완전 복구.
- v4.3.6 변경 사항(백업 파일명 타임스탬프 적용)을 히스토리 최하단에 명시.
- `pubspec.yaml` 버전 표기법 롤백 규칙(`x.x.x+y`)을 5번 절대 규칙에 통합 명문화.

---

## (Claude 등 타 AI에게) 전달할 주의 사항
- `memory.md` 파일은 프로젝트의 단일 진실 공급원(SSOT)이므로, 이전 버전의 히스토리를 임의로 축약하거나 삭제하지 말 것. 개발자가 "세세하게 적어줘"라고 요청한 포맷을 항상 유지할 것.