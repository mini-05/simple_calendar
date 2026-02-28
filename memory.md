# 🧠 My Calendar Project Memory & Context

> **목적:** AI(Gemini/Claude/Copilot)와의 대화 컨텍스트 한계를 극복하기 위한 프로젝트 통합 히스토리 및 절대 코딩 규칙 저장소. 새로운 채팅 세션을 시작할 때 이 문서 전체를 AI에게 주입하여 기억을 동기화해야 합니다. (Cursor 사용 시 `.cursorrules`로 저장하면 자동 적용됨)

## 📌 1. 프로젝트 개요 및 아키텍처
* **프로젝트명:** My Calendar
* **내부 패키지명:** `simple_calendar` (Android 패키지명 변경 금지)
* **플랫폼:** Flutter (Android / iOS 지원)
* **핵심 가치:** 1. 클라우드 연동 없는 100% 오프라인 동작
  2. `flutter_secure_storage`를 이용한 기기 내 로컬 암호화 저장
  3. 한국 양/음력 공휴일 및 대체공휴일 자동 계산
  4. 개별 일정에 대한 상세 알림 커스터마이징 (소리/진동)
* **상태 관리:** Riverpod 2.x (`StateNotifierProvider` 기반)

## 🤝 2. AI & 개발자 간의 절대 코딩 규칙 (팀 컨벤션)
1. **버전 네이밍 규칙:** 버전은 반드시 **`vx.x.x`** 포맷만 사용한다. (`-fix` 같은 꼬리표 절대 금지. 수정 시 마이너/패치 버전을 올린다.)
2. **Lint 경고(Warning) Zero 원칙:** 에러는 물론이고, 파란줄/노란줄 경고도 코드에 남기지 않는다.
   * `unused_import`: 미사용 패키지(예: `dart:math`)는 즉시 삭제.
   * `curly_braces_in_flow_control_structures`: `if`, `for`, `while` 등 모든 제어문은 코드가 한 줄이더라도 **반드시 중괄호 `{ }`**를 사용하여 블록을 감싼다.
3. **비동기 타입 엄수:** `Future<void>` 반환 콜백(예: `onSave`)은 반드시 `async`와 `await`를 명시하여 `body_might_complete_normally` 경고를 원천 차단한다.
4. **패키지명 강제 유지:** 앱의 표시 이름은 "My Calendar"이지만, `build.gradle`이나 `AndroidManifest.xml` 등에 들어가는 패키지명은 무조건 **`simple_calendar`**를 유지한다. (AI 임의 변경 감시)
5. **파일 헤더 규칙:** 모든 dart 파일 1번째 줄은 `// v실제버전` (예: `// v4.3.6`), 2번째 줄은 작성 AI에 따라 `// claude_파일명.dart` 또는 `// gemini_파일명.dart`, 3번째 줄은 `// lib/경로/파일명.dart`. pubspec.yaml도 1번째 줄에 `# v실제버전` 주석 표기, `version:` 필드는 `x.x.x+y` 형식 유지.
6. **[Claude 전용] 세션 요약 파일 자동 생성:** Claude는 매 작업 세션 종료 시 반드시 세션 요약 파일을 생성한다.
   * 파일명 형식: `claude_summary_YYYYMMDD_v실제버전.md` (예: `claude_summary_20260228_v4.3.6.md`)
   * 같은 날 같은 버전으로 파일이 이미 존재할 경우 `+빌드번호`를 뒤에 추가 (예: `claude_summary_20260228_v4.3.6+2.md`)
   * 내용: 변경 파일 목록, 상세 변경 내용, Gemini 인계 사항.
   * Gemini에게 수정 내용을 전달하는 용도로 사용.
7. **[핵심] AI 컨텍스트 자가 진단:** 대화가 길어지고 복잡해져 AI가 위 규칙들을 망각할 위험이 감지되면, AI는 스스로 답변 맨 마지막에 **`🚥 현재 AI 컨텍스트 상태: [🟡 주의]`** 신호등을 출력하고 개발자에게 `/리마인드` 명령어를 요청한다.
8. **문서 출력 최소화 규칙:** 버전(vx.x.x)이 변경될 때마다 `README.md`와 `memory.md`를 무조건 출력하지 않는다.
   * 메이저 버전(첫 번째 x)이 바뀔 때만 **"[README.md] 또는 [memory.md] 업데이트 사항을 보여드릴까요?"** 라고 묻는다.
   * 단, AI 컨텍스트 상태가 `[🟡 주의]`일 때는 묻지 않고 `memory.md` 전체를 무조건 출력하여 기억을 강제 리프레시한다.
9. **[절대 규칙] 히스토리(Changelog) 보존 및 상세 기록 원칙:** AI는 토큰을 절약한다는 핑계로 `memory.md`의 내용을 절대 임의로 축약, 요약, 또는 과거 내역을 삭제해선 안 된다. **"이전에 작성된 memory의 내용은 절대 지우지 마"** (개발자 특별 지시사항). 아무리 텍스트가 길어져도 기존의 세세한 포맷을 100% 무조건 유지하며 새 버전과 단위 테스트 항목을 하단에 누적해야 한다.
10. **[자동 반영 원칙 및 최적화 철학]** 사용자의 명시적 지시가 없더라도 대화 중 도출된 정책은 자동 누적한다. 
    * **앱 최적화(Windowing):** 무한 생성으로 인한 OOM 방지를 위해 `limit`에 의존하기보다, 달력 화면의 가시 범위(`from` ~ `to`) 내에서만 일정을 동적으로 생성하는 **Windowing(기간 한정 지연 로딩) 기법**을 `RecurrenceRule.expand`에 적용하여 메모리와 디스크 효율을 극대화한다.
    * **UI 오버플로우 방어:** S10 등 좁은 화면 기기에서 음력 일자(2자리)가 잘려 '음'만 표시되는 UI 버그를 원천 차단하기 위해, 날짜 포맷팅 시 공백 없는 초압축 형태('음10.24')를 유지하며, 달력 셀 내 우측 상단 오버레이(Stack/Positioned)를 통해 렌더링을 보장한다.

---

## 🚀 3. 버전별 상세 변천사 (Changelog: v1.0.0 ~ Current)

### [초기 빌드 및 기본 기능 구현기]
* **v1.0.0:** My Calendar 최초 모놀리식(단일 파일) 빌드. 달력 UI, 일정 추가/수정/삭제 기본 구현.
* **v1.0.1:** 일정 중복 시 UI가 겹쳐서 깨지는 현상 1차 수정.
* **v1.0.2:** 일정 구분용 컬러 마커(색상 점) 선택 기능 추가.
* **v1.1.0:** 반복 일정(매일, 매주) 기능 기초 도입.
* **v1.1.1:** Android 13+ 기기에서의 알림 권한 획득 이슈 해결.
* **v2.0.0:** 로컬 오프라인 한계 극복을 위한 ICS(RFC 5545 표준) 파일 내보내기/불러오기 기능 도입.
* **v2.1.0:** 일요일 셀에 한국식 음력 날짜 표시 기능 추가.
* **v3.0.0:** 앱 전체 UI 리뉴얼. 테마 시스템의 뼈대 마련.
* **v3.1.0:** 검색 기능 고도화. 한글 '초성 검색(예: ㅎㅇ -> 회의)' 구현.

### [아키텍처 대공사 및 최적화기]
* **v3.2.0:** 모놀리식 → `models/services/providers/theme/ui` 폴더 구조 완성. 순환 참조 0건.
* **v3.6.0:** 공휴일 판별 로직 리팩터링. 기존의 '타이틀 문자열 비교' 방식을 폐기하고, 식별자 `id < 0`이면 무조건 공휴일로 처리하는 OCP(개방-폐쇄 원칙) 전략 도입.
* **v3.6.1:** 설정에서 '음력 표시' ON 시에도 일요일 음력이 미표시되던 버그 패치.
* **v3.6.2:** 성능 크리티컬 버그 수정.
  * 음력 계산(~750회 변환)으로 인한 UI 스레드 락다운 해결 ➡️ 백그라운드 `Isolate` 이동.
  * 좌우 스와이프 모드에서 2030년을 넘어 무한 스크롤되는 버그 수정.
  * ICS 백업 시 `DTSTART` 시간 포맷 오류로 구글 캘린더 복원 시 UTC 시간차(9시간) 발생 버그 수정.

### [UI/UX 시스템 확립기]
* **v4.0.0:** 하단 슬라이딩 패널, 6테마, 3가지 넘기기 모드.
* **v4.1.0:** * 상태 관리 엔진 Riverpod 2.x 전면 이관 (`StateNotifierProvider`).
  * 사이드 드로어(Drawer) 메뉴 신설하여 설정, 테마, 백업 기능을 통합.
  * 달력 렌더링 최적화: `holidayDates`를 `Set<String>`으로 만들어 달력 그릴 때 O(1) 속도로 공휴일 색상 반영.
  * `home_widget` 패키지 연동으로 스마트폰 홈 화면 오늘 일정 위젯 추가.

### [디테일 완벽주의 및 린트 제로기]
* **v4.1.1:** (구 AI 오진 사태 픽스)
  * ICS 임포트 등에서 손상된 날짜 파싱 시 크래시를 막는 `_safeParse` 도입.
  * 일정 ID 생성기를 단순 `Random()`에서 암호학적 OS 엔트로피 `Random.secure()`로 교체하여 중복 완전 방지.
  * 공휴일법 규정에 맞춘 완벽한 대체공휴일 알고리즘(설/추석 연휴 3일 블록이 다른 공휴일과 겹치면 뒤로 순차적 밀기) 완성.
  * 화면 렌더링 최적화: `build()`에서 수행하던 패널 높이 계산을 `didChangeDependencies` 캐싱으로 변경.
* **v4.2.0:** 사용자 피드백 반영 편의성 고도화.
  * 달력 상단의 "2026년 2월" 텍스트를 누르면 아이폰 스타일의 `CupertinoDatePicker`가 바텀시트로 올라와 년/월 쾌속 이동 가능.
  * 화살표 넘기기 모드 시 화면 하단이 남던 현상을 `Expanded` 및 `shouldFillViewport: true`로 꽉 채우도록 해결.
* **v4.2.1:** `event_editor`의 `onSave` 콜백에 `async/await`를 명시하여 Dart 비동기 반환 타입 린트 경고 완전 소거.
* **v4.2.2:** 특정 테마에서 화살표 모드 사용 시 년/월 표기가 '2026. 2.'로 이질적으로 출력되던 현상 삭제. 어떤 환경이든 '2026년 2월'로 표기 통일.

### [최신 성능 혁신 (Copilot 제안 적용기)]
* **v4.3.0:** 안드로이드 로딩 및 스크롤 성능 비약적 향상.
  * `NotificationService`의 무거운 플러그인 초기화를 렌더링 이후로 지연시키고, 앱 진입점(`main.dart`)에는 가벼운 시간대 설정(`initMinimal`)만 배치.
  * `EventStorage`에 `_cachedEvents` 변수를 두어 디스크 I/O를 메모이제이션 패턴으로 최소화.
  * `CalendarNotifier._init`에서 설정 로드와 이벤트 로드를 `Future.wait`를 통해 병렬(Concurrent) 처리.
  * `_rebuildIndex` 내의 무거운 공휴일 계산 및 반복 일정 확장을 메인 스레드에서 분리하여 `Isolate (compute)`로 넘김 (UI 스터터링 완벽 제거).
  * 일정 목록 `ListView`에 `cacheExtent: 500` 옵션을 주어 스크롤 렌더링 메모리 최적화.
* **v4.3.1:** `intl` 패키지 누락 경고 픽스 및 데스크톱/웹용 DB 백업 코드 주석 복구.
* **v4.3.2:** `main.dart` 내 존재하지 않던 `materialTheme` Getter 호출 제거. 플러터 표준 `ThemeData`를 직접 구성하여 빌드 에러 해결.
* **v4.3.3:** `main.dart` 앱 테마 초기화 시 누락되었던 `app_theme.dart` 임포트 복구 및 빌드 에러 완벽 해결. 새로운 AI 출력 룰(문서 출력 최소화) 적용.

### [UI 디테일 + 플랫폼 분기]
* **v4.3.4:**
  * 초기 실행 모드: 좌우 슬라이드(`swipeHorizontal`)를 기본값으로 변경.
  * 첫 설치 후 최초 실행 시 Android → 삼성 테마, iOS → 애플 테마 자동 적용 (`isFirstRun` 판단).
  * AppBar에 년/월 표시 통합:
    * 좌우/상하 스와이프 모드: AppBar title에 "2026년 2월" 표시 (클릭 → 월 피커).
    * 화살표 모드: AppBar title에 "2026년" 표시 (클릭 → 년도 피커), 달력 위에 "2월" 표시 (클릭 → 월 피커).
  * ICS 백업 파일명 `my_calendar_backup.ics` → `simple_calendar_backup.ics` 통일.
  * 파일 헤더 규칙 명문화: `claude_*` / `gemini_*` 구분.
* **v4.3.5:**
  * 화살표 모드 AppBar UI 통합: 년도/월 어느 것을 터치해도 동일하게 전체 `CupertinoDatePicker`가 호출되도록 수정 (`_showYearPicker` 제거).
  * `pubspec.yaml` 버전 표기법 롤백 (`버전+빌드번호`).
  * `models.dart` 내 Claude가 발생시킨 중괄호 누락 린트 에러 등 클린업 완료.
* **v4.3.6 (현재 버전):**
  * ICS 백업 파일명을 고정된 문자열에서 동적 생성 포맷(`My_Calendar(backup)_YYYYMMDD_hhmmss.ics`)으로 재변경하여 이전 백업 파일 덮어쓰기 방지 및 이력 관리 강화.
  * 앱 최적화를 위한 달력 렌더링 Windowing 도입 및 좁은 화면(S10) 대응용 음력 텍스트 반응형 UI(Stack/Positioned) 패치 적용. 
  * 핵심 로직 5대 단위 테스트(Unit Test)를 Dart 3.0 Records 문법으로 100% 리팩터링 및 구축 완료.

---

## 🎯 4. 향후 마일스톤 (Upcoming Milestones)
### [v4.4.0] UI 아키텍처 전면 리팩터링 계획
> **목적:** 1,400줄을 초과한 God Object(`calendar_screen.dart`)를 OCP 원칙에 맞게 해체하여 유지보수성 극대화. 기능 추가 없이 구조만 변경하는 클린업 버전.
1. **1순위:** `_EventSearchDelegate` ➡️ `lib/ui/widgets/search_delegate.dart`로 독립 분리.
2. **2순위:** `_AppSettingsSheet` ➡️ `lib/ui/widgets/settings_sheet.dart`로 분리 (새로운 설정 추가 시 메인 UI 수정을 막기 위한 OCP 실현). Riverpod의 `ConsumerWidget`을 상속하여 파라미터 전달 최소화.
3. **3순위:** `_buildDrawer` ➡️ `lib/ui/widgets/app_drawer.dart`로 분리 (`ConsumerWidget` 적용).
4. **유지:** `_buildArrowCalendar` 및 `_buildSwipeCalendar`는 메인 캘린더 상태(State)와 생명주기를 밀접하게 공유하므로 내부 메서드로 유지.

---

## 🔬 5. 단위 테스트 (Unit Test) 명세 및 정책
> **목적:** 핵심 비즈니스 로직(공휴일, 슬롯, 상태, 포맷터, 반복일정)이 무너지지 않음을 보장하기 위해 도입. 모든 데이터 기반 테스트(Table-driven) 코드는 Map 대신 **Dart 3.0의 Records 문법**을 활용하여 가독성과 OCP(개방-폐쇄) 확장성을 극대화한다.

### ① `test/services/date_formatter_test.dart` (완료)
* **`formatHHmm` / `getChosung` / `dateKey` 테스트:** Records 적용 완료. 24시간제 변환(자정/정오/경계값), 한글 초성 추출(숫자/영문 혼용 방어), 제로 패딩 문자열 변환 검증.
* **[UI 오버플로우 방어 검증]:** `getLunarLabel` 반환값 내에 공백(' ')이 100% 제거되었는지 검증하여 S10 등 기기의 UI 잘림 현상 방지. 설정(`showLunar`) On/Off에 따른 렌더링 무결성 확인.

### ② `test/models/models_test.dart` (완료)
* **`RecurrenceRule.expand` 동적 엔진 검증:** Records 적용 완료. Windowing(기간 한정 지연 로딩), 극한의 Limit(200년 치), 1년 동적 생성, 주기별 점프 방어벽 검사.
* **`CalendarEvent` 데이터 무결성 검증:** 10종의 극한 엣지 케이스(다중일, 음수 ID, 커스텀 사운드, 복합 반복 등) 대상 JSON 직렬화/역직렬화 데이터 보존율 100% 딥 체킹 수행.

### ③ `test/services/holidays_test.dart` (완료)
* **[하드코딩 완전 탈피] 5년 치 동적 윈도우 스캐닝:** 특정 연도(예: 2026년) 하드코딩 방식을 폐기. 테스트가 실행되는 당해 연도 기준 향후 5년(Window)을 자동 할당하여 대체공휴일 등 엣지 케이스를 자율적으로 찾아내어 검증하는 행위 검증(Behavioral Test) 완료.
* 대체공휴일 동적 산출 여부, 6대 필수 양력 공휴일 누락, 5년 치 명절 연휴 3일 연속 블록 보장 검증.

### ④ `test/services/slot_calculator_test.dart` (완료)
* **슬롯(Slot) 테트리스 배치 검증:** Records 적용 완료. 겹치는 일정 분배 및 빈 슬롯(Slot 0) 스마트 재사용 로직 검증.
* **정렬 최우선순위 검증:** 기간이 긴 다중일(Multi-day) 일정이 짧은 일정보다 무조건 상단 슬롯을 선점하여 캘린더 UI 깨짐을 방지하는지 확인.
* **[아키텍처 대응]:** 도메인 객체(`SlotCalculationResult`)에 `operator []` 오버로딩을 위임 구현하여 OCP를 지키면서 테스트 코드의 가독성 향상.

### ⑤ `test/providers/providers_test.dart` (완료)
* **상태 변이(State Mutation) 비즈니스 로직 검증:** Records 적용 완료. 세부 알람 옵션(소리/진동) 조합의 출력값 검증 및, `globalSilentMode`(무음 모드) 활성화 시 기존 설정을 무시하고 `silent`를 강제 오버라이드하는지 확인.
* **Riverpod 상태 불변성(Immutability) 검증:** `copyWith` 호출 시 기존 객체를 변형하지 않고 완전히 독립된 주소값(`identical` == false)을 반환하여 정상적인 UI 리빌드를 유발하는지 증명.

---
*(End of Context - Version: v4.3.7)*