# 📅 My Calendar — v3.6.0

> Flutter 기반 한국형 개인 캘린더 앱.  
> 공휴일 자동 표시, 음력, 초성 검색, ICS 백업, 다중 테마, 스케줄 알림을 지원합니다.

---

## 목차

1. [주요 기능](#주요-기능)
2. [프로젝트 구조](#프로젝트-구조)
3. [아키텍처 설계 원칙](#아키텍처-설계-원칙)
4. [파일별 역할](#파일별-역할)
5. [테마 시스템](#테마-시스템)
6. [공휴일 시스템](#공휴일-시스템)
7. [데이터 흐름](#데이터-흐름)
8. [설치 및 빌드](#설치-및-빌드)
9. [사용 라이브러리](#사용-라이브러리)
10. [설계 의도 및 주요 결정 사항](#설계-의도-및-주요-결정-사항)
11. [버전 히스토리](#버전-히스토리)

---

## 주요 기능

### 📆 달력
- **3가지 네비게이션 모드**: 화살표 버튼 / 상하 스와이프 / 좌우 스와이프
- **음력 표시**: 일요일 셀에 음력 1일·15일·30일만 표시 (셀 공간 효율 최적화)
- **공휴일 자동 표시**: 양력 고정 공휴일, 음력 연휴(설날·추석·부처님오신날), 대체공휴일 포함
- **슬롯 배정 알고리즘**: 다중일 이벤트가 겹쳐도 바 형태로 올바르게 정렬
- **Viewport 최적화**: 현재 달 기준 앞뒤 12개월만 인덱싱하여 메모리·연산 최소화

### 📝 일정 관리
- 일정 추가 / 수정 / 삭제
- 하루 종일 / 시간 지정 / 다중일 이벤트
- 5가지 색상 선택
- 최대 500개 등록 제한

### 🔔 알림
- 7단계 알림 시간 (정각 / 5·10·30분 전 / 1시간·1일 전)
- 4가지 알람 모드: 무음 / 소리 / 진동 / 소리+진동
- 5가지 알림 소리 (시스템 기본 / 종소리 / 벨소리 / 새소리 / 내 음악 파일)
- 4가지 진동 패턴
- 전역 무음 모드 토글
- 알림 테스트 기능

### 🔍 검색
- **초성 검색** 지원 (예: `ㅎㄱ` → `회의`, `ㅎㄱ장`)
- 띄어쓰기 무시 검색
- 검색 결과 탭 시 해당 날짜로 이동

### 💾 백업 / 복구
- **ICS 내보내기**: 구글 캘린더·애플 캘린더 호환 표준 형식
- **ICS 가져오기**: 기존 데이터와 병합
- 보안 저장소 (`flutter_secure_storage`) 사용

### 🎨 테마
| 테마 | 스타일 |
|------|--------|
| 📱 삼성 캘린더 | 텍스트 바 이벤트, 좌상단 정렬 |
| 🍎 애플 캘린더 | 측면 컬러 바, 미니멀 |
| 🇳 네이버 캘린더 | 텍스트 바, 그린 계열 |
| ✅ 투두 스카이 | 다크 패널, 둥근 카드 |
| 🌙 다크 네온 | 다크 + 네온 퍼플 |
| ☁️ 클래식 블루 | 밝은 블루 카드 |

---

## 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점, NotificationService 초기화
│
├── models/
│   └── models.dart                    # 데이터 모델 및 enum 전체
│
├── theme/
│   └── app_theme.dart                 # 테마 추상 클래스 + 6개 구현체
│
├── logic/                             # ★ Flutter 의존성 0 — 순수 Dart
│   ├── date_formatter.dart            # 날짜 포맷, 음력 레이블, 초성 추출
│   ├── slot_calculator.dart           # 이벤트 슬롯 배정 알고리즘
│   └── holidays.dart                  # OCP 기반 공휴일 생성 시스템
│
├── services/
│   └── services.dart                  # 저장소, 알림, ICS 서비스
│
└── ui/
    └── calendar_screen.dart           # 메인 화면 + 설정 시트 + 검색

test/
├── logic/
│   ├── event_slot_calculator_test.dart
│   └── date_formatter_test.dart
├── models/
│   ├── app_settings_test.dart
│   └── calendar_event_test.dart
└── services/
    └── event_storage_test.dart
```

---

## 아키텍처 설계 원칙

### 1. 단방향 의존성 (순환 참조 0)

```
models/ ← logic/ ← services/ ← ui/
theme/  ←─────────────────────┘
```

- `logic/` 레이어는 Flutter 패키지를 import하지 않음 → `dart test`로 에뮬레이터 없이 테스트 가능
- `models/`는 어떤 레이어도 import하지 않음

### 2. OCP (개방-폐쇄 원칙)

**테마 시스템**: 새 테마 추가 시 `CalendarTheme`을 구현하는 class만 작성하면 되고, `calendar_screen.dart`를 수정할 필요 없음.

```dart
// 새 테마 추가 예시 — calendar_screen 수정 불필요
class MyCustomTheme extends CalendarTheme {
  @override AppTheme get type => AppTheme.myCustom;
  @override Widget buildEventListItem({...}) { ... }
  @override Widget buildScaffoldLayout({...}) { ... }
  // hasRoundedCard, bottomSheetBg 등 필요한 것만 override
}
```

**공휴일 시스템**: 새 공휴일 규칙 추가 시 `HolidayProvider`를 구현하고 `HolidayUtil._baseProviders`에 추가.

```dart
// 예: 어버이날 추가 시 기존 클래스 수정 없이
class ParentsDayProvider implements HolidayProvider { ... }
// HolidayUtil에만 추가
static final _baseProviders = [
  SolarHolidayProvider(),
  LunarHolidayProvider(),
  ParentsDayProvider(), // ← 이것만 추가
];
```

### 3. 다형성 (Polymorphism)

`CalendarTheme`의 `buildEventListItem()`과 `buildScaffoldLayout()`이 테마별로 완전히 다른 UI를 렌더링. `calendar_screen.dart`의 호출부는 `_th.buildEventListItem(...)` 한 줄로 통일.

### 4. 의존성 주입 (Dependency Injection)

`SlotCalculator.calculate()`는 공휴일 생성 로직(`HolidayUtil`)을 직접 호출하지 않고, 외부에서 생성된 공휴일 리스트를 주입받음. `logic/` 내부에서 `logic/` 간 의존성 없음.

```dart
// calendar_screen에서 공휴일 생성 후 주입
final holidays = _appSettings.showHolidays
    ? HolidayUtil.generateHolidaysForWindow(minDate, maxDate) : null;
SlotCalculator.calculate(all, _windowCenter, _slotMap, firstLoad, holidays);
```

---

## 파일별 역할

### `models/models.dart`
| 클래스/Enum | 역할 |
|------------|------|
| `AppTheme` | 테마 식별 enum |
| `CalendarNavMode` | 달력 네비게이션 모드 (arrow / swipeVertical / swipeHorizontal) |
| `AlarmMode` | 알림 방식 (silent / soundOnly / vibrationOnly / soundAndVibration) |
| `NotificationSound` | 알림 소리 종류 |
| `VibrationPattern` | 진동 패턴 |
| `AlarmMinutes` | 알림 시간 (none / 0 / 5 / 10 / 30 / 60 / 1440분) |
| `AppSettings` | 앱 전체 설정 (toJson / fromJson / copyWith) |
| `CalendarEvent` | 일정 모델 (toJson / fromJson / copyWith / computed properties) |
| `_safeEnum<T>` | enum 역직렬화 시 index 범위 초과 크래시 방지 (라이브러리 private) |

**`CalendarEvent` 주요 computed properties:**
- `isHoliday`: `id < 0` 이면 공휴일 (공휴일 ID는 음수로 생성)
- `isMultiDay`: 시작/종료 날짜가 다른 경우
- `alarmDateTime`: 알림 발생 시각 계산

### `theme/app_theme.dart`
`abstract class CalendarTheme`의 주요 속성:

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `isDark` | `bool` | `false` | 다크 모드 여부 |
| `showTextInside` | `bool` | `false` | 셀 안에 텍스트 바 표시 (삼성·네이버 방식) |
| `hasRoundedCard` | `bool` | `false` | 달력을 둥근 카드로 감쌈 (투두스카이·다크네온) |
| `bottomSheetBg` | `Color?` | `null` | 바텀시트 전용 배경색 |
| `cellTextAlignment` | `Alignment` | `center` | 셀 내 텍스트 정렬 방향 |

### `logic/date_formatter.dart`
| 메서드 | 설명 |
|--------|------|
| `dateKey(DateTime)` | `yyyy-MM-dd` 포맷 키 생성 |
| `formatDateKorean(DateTime)` | `2025년 6월 15일 (일)` 형식 |
| `formatHHmm(String)` | `HH:mm` → `오전/오후 H:MM` 변환 |
| `makeTimeString(CalendarEvent)` | 일정 목록의 시간 부제목 생성 |
| `getLunarLabel(DateTime, bool)` | 음력 1일·15일·30일이면 레이블 반환, 나머지는 null |
| `getChosung(String)` | 한국어 초성 추출 (검색용) |

### `logic/slot_calculator.dart`
이벤트 슬롯 배정 알고리즘.

- 다중일 이벤트 우선 배치 (기간 긴 순서)
- `prevSlotMap` 재사용: 이벤트 수정 후에도 기존 슬롯 위치 유지
- 날짜별 `slot 순` 정렬 반환
- 공휴일 이벤트는 외부에서 주입받아 내부 의존성 없음

### `logic/holidays.dart`
OCP 기반 3단계 공휴일 생성:

1. `SolarHolidayProvider`: 양력 고정 8개 (신정·삼일절·어린이날·현충일·광복절·개천절·한글날·크리스마스)
2. `LunarHolidayProvider`: 음력 연휴 (설날 3일·추석 3일·부처님오신날)
3. `SubstituteHolidayProvider`: 2023년 개정 대체공휴일 규칙

### `services/services.dart`
| 클래스 | 역할 |
|--------|------|
| `NotificationService` | 알림 초기화·스케줄·취소·테스트·권한 요청 |
| `AppSettingsStorage` | 설정 암호화 저장/로드 |
| `EventStorage` | 이벤트 암호화 저장/로드 (Isolate compute 직렬화) |
| `IcsService` | ICS 표준 내보내기·가져오기 |
| `appLog()` | 릴리즈 빌드에서 로그 차단 |

---

## 테마 시스템

### CalendarTheme 상속 구조

```
CalendarTheme (abstract)
├── SamsungTheme       — showTextInside: true, cellTextAlignment: topLeft
├── AppleTheme         — 측면 컬러 바, 미니멀 리스트
├── NaverTheme         — showTextInside: true, 그린 계열
├── TodoSkyTheme       — hasRoundedCard: true, bottomSheetBg 별도 지정
└── DefaultCardTheme   — darkNeon(hasRoundedCard: true), classicBlue 공용
```

### 테마 추가 방법

1. `models.dart`의 `AppTheme` enum에 값 추가
2. `app_theme.dart`에 `class NewTheme extends CalendarTheme` 작성
3. `AppThemeExt.themeData` switch에 case 추가
4. 다른 파일 수정 불필요

---

## 공휴일 시스템

### 공휴일 ID 규칙
공휴일 이벤트는 `id < 0` (음수). `IdGenerator`가 -10000부터 감소하며 할당.  
`CalendarEvent.isHoliday` getter로 구분.

### 표시 규칙
- 공휴일 날짜의 일자 텍스트: `Colors.redAccent` (일요일과 동일)
- 공휴일 이벤트는 수정/삭제/알림 불가 (`isHoliday` 체크로 차단)
- 설날·추석은 다중일 바로 표시, 중앙 날짜에 제목 표시

### Viewport 필터링
`_rebuildIndex` 호출 시 현재 달 기준 ±12개월 창(window)만 생성.  
페이지 이동으로 창 밖 6개월 이상 벗어나면 자동 재계산.

---

## 데이터 흐름

```
사용자 액션
    │
    ▼
_CalendarScreenState
    │
    ├─ _allEvents (List<CalendarEvent>) — 실제 저장된 이벤트
    │
    ├─ _rebuildIndex()
    │       │
    │       ├─ HolidayUtil.generateHolidaysForWindow()  ← holidays.dart
    │       │
    │       └─ SlotCalculator.calculate()              ← slot_calculator.dart
    │               │
    │               └─ SlotCalculationResult
    │                       ├─ eventsByDate  (Map<String, List<CalendarEvent>>)
    │                       ├─ slotMap       (Map<int, int>)
    │                       └─ windowEvents  (List<CalendarEvent>)
    │
    ├─ _eventsByDate → _buildCustomCell() → 달력 셀 렌더링
    │
    └─ _selectedEvents → ListView → 일정 목록 렌더링
```

### 저장 흐름

```
CalendarEvent
    │
    ├─ toJson() → jsonEncode (Isolate compute)
    │                   │
    │                   └─ FlutterSecureStorage (AES 암호화)
    │
    └─ fromJson() ← jsonDecode (Isolate compute)
                         │
                         └─ FlutterSecureStorage (복호화)
```

---

## 설치 및 빌드

### 요구 사항
- Flutter SDK `>=3.3.0`
- Dart SDK `>=3.3.0 <4.0.0`
- Java 17 (Android 빌드)
- Android SDK (minSdk 21 권장)

### 로컬 실행

```bash
# 의존성 설치
flutter pub get

# 디버그 실행
flutter run

# 릴리즈 APK 빌드 (arm64)
flutter build apk --release --target-platform android-arm64

# App Bundle 빌드
flutter build appbundle --release
```

### CI/CD (GitHub Actions)

`main` / `master` 브랜치 push 시 자동 빌드.  
결과물: `app-release.apk`, `app-release.aab` (Actions Artifacts)

```yaml
# .github/workflows/build_apk.yml
on:
  push:
    branches: [ "main", "master" ]
```

### Android 권한 (`AndroidManifest.xml` 필요)

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
```

---

## 사용 라이브러리

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `table_calendar` | ^3.1.2 | 달력 위젯 (arrow 모드) |
| `flutter_secure_storage` | ^9.0.0 | AES 암호화 로컬 저장소 |
| `flutter_local_notifications` | ^18.0.0 | 스케줄 알림 |
| `timezone` | ^0.9.4 | 타임존 처리 |
| `flutter_timezone` | ^5.0.1 | 기기 타임존 자동 감지 |
| `file_picker` | ^8.1.0 | 음악 파일·ICS 파일 선택 |
| `permission_handler` | ^11.3.0 | 런타임 권한 요청 |
| `lunar` | ^1.7.6 | 양력 → 음력 변환 |
| `path_provider` | ^2.1.2 | ICS 임시 파일 경로 |
| `share_plus` | ^7.2.1 | ICS 파일 공유 |
| `flutter_localizations` | SDK | 한국어 로케일 |

---

## 설계 의도 및 주요 결정 사항

### 음력 표시 설계 의도
- **표시 위치**: 일요일 셀에만 표시
  - 평일·토요일 셀은 이벤트 바 공간이 부족해 음력 표시 시 레이아웃 깨짐
  - 일요일은 주의 시작점으로 시각적으로 의미 있는 기준점
- **표시 조건**: 음력 1일(초하루)·15일(보름)·30일(그믐)만 표시
  - 모든 날짜를 표시하면 셀이 과밀해지고 읽기 어려움
  - 음력 월의 주요 절기(초하루·보름·그믐)만 표시하는 전통 캘린더 방식 채택

### 슬롯 배정 알고리즘
- 다중일 이벤트 (기간 긴 순서) → 하루 이벤트 순으로 정렬 후 슬롯 배정
- `prevSlotMap` 재사용: 이벤트를 수정해도 슬롯 위치가 변하지 않아 UX 안정
- 날짜별 슬롯 순 정렬 후 캐싱

### 공휴일 id 음수 설계
공휴일을 일반 이벤트와 같은 `List<CalendarEvent>`에 혼합 저장하되, `id < 0`으로 구분. `isHoliday` getter 하나로 모든 분기 처리 가능.

### Viewport 슬라이딩 윈도우
앱 전체 이벤트 수가 수백 개여도, 인덱싱은 현재 달 기준 ±12개월(25개월)만 수행. 6개월 이상 이동 시 자동 재계산.

### 보안 저장소 키 난독화
`AppSettingsStorage`와 `EventStorage`의 키를 `String.fromCharCodes([...])` 패턴으로 난독화. 바이너리에서 키 문자열 직접 추출 방지.

---

## 버전 히스토리

### v3.6.0 (현재)
- **구조**: `logic/` 레이어 신설 — `date_formatter`, `slot_calculator`, `holidays` 분리
- **OCP 강화**: `CalendarTheme` 다형성 도입 — 테마별 `buildEventListItem()`, `buildScaffoldLayout()` 위임
- **공휴일**: `HolidayProvider` 인터페이스 기반 OCP 설계 — 양력·음력·대체공휴일 분리
- **네비게이션**: `swipeHorizontal` 모드 추가 (좌우 스와이프)
- **결합도 감소**: `SlotCalculator`가 공휴일을 외부 주입받아 `holidays.dart` 의존성 제거
- **버그 수정**: `_rescheduleAllAlarms`에 공휴일 guard 추가
- **가독성**: `generateId` 연산자 괄호 명시

### v3.5.0
- 단일 파일 → `models`, `services`, `theme`, `ui` 4개 파일로 분리
- Viewport 슬라이딩 윈도우 렌더링 최적화
- 초성 검색, ICS 백업/복구, 수직 스와이프 추가
- `defaultEventColor` 전역 상수 위치 `models`로 이동 (순환 참조 해결)

### v3.2.0
- `logic/` 폴더 신설 (Flutter 의존성 0)
- 15개 파일 분리, 5개 단위 테스트 파일 작성
- `EventEditDialog` class화 (CalendarScreen에서 ~400줄 분리)
- 순환 참조 없는 단방향 의존성 구조 확립