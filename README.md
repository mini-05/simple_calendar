# 📅 My Calendar — v4.4.2

> Flutter · Android / iOS  
> 오프라인 전용 · 암호화 저장 · 한국 공휴일 자동 계산

---

## ENGLISH

---

### 1. Overview

My Calendar is a private, offline-first calendar app for Android and iOS built with Flutter.  
All data is stored **encrypted on your device** — no accounts, no cloud sync, no ads.

- Korean public holidays (solar & lunar, substitute holidays — auto-calculated every year)
- Lunar date display on Sunday cells
- Per-event notifications with custom sound and vibration
- Gesture-based sliding event panel
- Side drawer for theme, backup, and settings
- Six visual themes and three navigation modes
- Home screen widget (today's events)
- Splash screen with on/off toggle

---

### 2. Key Features

| Feature | Description |
|---|---|
| 📅 Korean Public Holidays | Solar + lunar holidays (Seollal, Chuseok, Buddha's Birthday, substitute holidays) — calculated automatically, no manual updates needed |
| 🔴 Holiday Colors | Holiday dates shown in red automatically — even when holiday display is off, the color data is preloaded |
| 🌙 Lunar Date on Sundays | Shows '음M.D' (e.g. '음5.20') next to every Sunday's date number |
| 🎨 6 Visual Themes | Samsung · Apple · Naver · Dark Neon · Classic Blue · Todo Sky |
| 📐 3 Navigation Modes | Arrow buttons · Vertical swipe · Horizontal swipe |
| 🔔 Per-Event Notifications | Timing, sound, and vibration pattern set individually per event |
| 🔇 Global Silent Mode | Mute all alarms with one toggle — individual settings preserved |
| 🔍 Korean 초성 Search | Type 'ㅎㅇ' to find '회의' — Korean initial-consonant search |
| 📤 ICS Backup & Restore | RFC 5545 standard — compatible with Google Calendar & Apple Calendar |
| 🏠 Home Widget | Today's events (up to 3) displayed on the Android/iOS home screen |
| 🔁 Recurring Events | Daily / weekly / monthly / yearly repeat with optional end date |
| ✨ Splash Screen | Animated intro screen with on/off toggle in settings |
| 🔒 Fully Offline | No internet required, all data encrypted on-device |

---

### 3. Getting Started

#### 3.1 First Launch
1. The app opens on the current month. Public holidays appear in **red** automatically.
2. Tap any date to select it — the event panel slides up from the bottom.
3. Tap **+** (bottom-right) to add your first event.

#### 3.2 Adding an Event
1. Tap **+** to open the event editor.
2. Enter a title.
3. Set start / end date. Toggle **All Day** for full-day events.
4. Configure an alarm: timing, method (sound/vibration), sound, and vibration pattern.
5. Set recurrence (optional): daily / weekly / monthly / yearly, with an optional end date.
6. Pick a color dot for visual identification.
7. Tap **Save**.

#### 3.3 Editing or Deleting
Tap any event in the panel → action sheet appears → choose **Edit** or **Delete**.

#### 3.4 Searching
Tap the 🔍 icon → type a keyword or Korean initial consonants (초성) → tap a result to jump to that date.

#### 3.5 Sliding Event Panel
- **Swipe up** anywhere on the calendar to open the event panel.
- **Swipe down** on the panel handle to close it.
- The panel shows events for the selected date with alarm toggles.

---

### 4. Side Drawer

Open with the **≡** icon (top-left).

| Menu | Description |
|---|---|
| 🎨 Theme | Switch between 6 visual themes |
| 📤 ICS Export | Share your events as a `.ics` file |
| 📥 ICS Import | Import events from a `.ics` file |
| ⚙️ Settings | Notifications, display, navigation settings |

---

### 5. Settings

Open via Side Drawer → Settings.

| Setting | Description |
|---|---|
| Lunar display (Sunday) | Shows lunar date on every Sunday in '음M.D' format |
| Show public holidays | Toggles automatic Korean holiday display in red |
| Navigation mode | Arrow buttons / Vertical swipe / Horizontal swipe |
| Notifications master | Master on/off switch for all event alarms |
| Default sound | System · Chime · Bell · Bird · Piano · Guitar · Rain · Ocean · Wind · Custom music file |
| Default vibration | 9 patterns including Default · Heartbeat · Crescendo · SOS · Triple · Rapid |
| Silent mode | Suppresses all alarm sounds & vibrations globally |
| ✨ Splash screen | Toggle the animated intro screen on/off |
| 📱 Home widget style | Choose the widget display style |

---

### 6. Themes

Open via Side Drawer → Theme.

| Theme | Style |
|---|---|
| 📱 Samsung Calendar | White card, blue accent, inline event bars *(default on Android)* |
| 🍎 Apple Calendar | Clean white, red accent, dot markers *(default on iOS)* |
| 🇳 Naver Calendar | White, green accent, inline bars |
| 🌙 Dark Neon | Dark purple, neon accents, rounded cards |
| ☁️ Classic Blue | Light blue-grey, bordered cards |
| ✅ Todo Sky | White calendar + dark navy event list |

---

### 7. Notifications

#### Per-Event Alarm
- **Timing:** at the time · 5 min · 10 min · 30 min · 1 hour · 1 day before
- **Method:** Sound only · Vibration only · Sound + Vibration · Silent
- **Sound:** System default · Chime · Bell · Bird · Piano · Guitar · Rain · Ocean · Wind · Custom file
- **Vibration:** 9 patterns — Default · Heartbeat · Crescendo · Long · SOS · Triple · Rapid · Gentle · Pulse

#### Global Silent Mode
Pauses all alarms globally. Individual settings are preserved — turning silent mode off restores everything exactly as configured.

> **Note:** Silent mode is independent of your phone's ringer volume.

---

### 8. Backup & Restore (ICS)

#### 8.1 Export
1. Side Drawer → **ICS Export**
2. A `.ics` file is prepared and the share sheet opens
3. Save to Files, email it, or upload to Google Drive

#### 8.2 Import
1. Side Drawer → **ICS Import**
2. Choose a `.ics` file from your device
3. Events are merged into your existing data

> **Note:** Color and alarm settings are not stored in ICS files and will not be restored on import.

---

### 9. Architecture & Execution Flow

*This section is for developers.*

#### 9.1 Module Structure

    lib/
      main.dart                      — App entry point, NotificationService.initMinimal()
      app_config.dart                — AppConfig (appGroupId, widget names)
      models/
        models.dart                  — CalendarEvent · AppSettings · RecurrenceRule · all enums
      providers/
        providers.dart               — CalendarState · CalendarNotifier · Riverpod providers
      services/
        services.dart                — Barrel export (all services)
        storage_service.dart         — EventStorage · AppSettingsStorage · appLog
        notification_service.dart    — NotificationService (alarm scheduling)
        ics_service.dart             — IcsService web-safe entry
        ics_service_io.dart          — ICS export/import (mobile only)
        ics_service_stub.dart        — No-op stub for web
        date_formatter.dart          — Date keys · Korean format · lunar label · 초성
        slot_calculator.dart         — Event-row slot assignment algorithm
        holidays.dart                — HolidayUtil (solar + lunar + substitute)
        home_widget_service.dart     — HomeWidgetService (Android/iOS widget update)
      theme/
        app_theme.dart               — CalendarTheme data + 6 concrete themes
      ui/
        splash_screen.dart           — SplashScreen (respects showSplash setting)
        calendar_screen.dart         — CalendarScreen (ConsumerStatefulWidget)
        widgets/
          app_drawer.dart            — Side drawer (theme, backup, settings)
          calendar_tile.dart         — CalendarTile (date cell renderer)
          event_bar.dart             — EventBar (inline bar for Samsung/Naver themes)
          settings_sheet.dart        — AppSettingsSheet (bottom sheet)
          theme_dialog.dart          — Theme picker bottom sheet
          search_delegate.dart       — Korean 초성 search
        dialogs/
          event_editor.dart          — Event add/edit dialog

#### 9.2 State Management (Riverpod 3.x)

    calendarProvider       — NotifierProvider<CalendarNotifier, CalendarState>
    settingsProvider       — Provider<AppSettings> (derived)
    selectedDayProvider    — Provider<DateTime?> (derived)
    selectedEventsProvider — Provider<List<CalendarEvent>> (derived)

`CalendarState` fields:

| Field | Type | Description |
|---|---|---|
| `masterEvents` | `List<CalendarEvent>` | All user events (no recurrence instances) |
| `eventsByDate` | `Map<String, List<CalendarEvent>>` | Date key → events (expanded window) |
| `slotMap` | `Map<int, int>` | Event id → display row slot |
| `holidayDates` | `Set<String>` | Date keys of holidays for O(1) lookup |
| `selectedEvents` | `List<CalendarEvent>` | Events for the selected day |
| `focusedDay` | `DateTime` | Currently focused calendar month |
| `selectedDay` | `DateTime?` | Tapped day |
| `settings` | `AppSettings` | Current app settings |
| `cachedArrowRowHeight` | `double` | Pre-calculated row height (Samsung/Naver themes) |

#### 9.3 Dependency Direction

    models  ←  services/logic  ←  providers  ←  ui
            ←  theme  ←────────────────────────────┘

    models    : pure Dart — zero Flutter dependency
    services  : models + Flutter foundation (compute, notifications)
    providers : models + services + Riverpod
    ui        : imports everything above

#### 9.4 App Start Sequence (Optimized)

| Step | What happens |
|---|---|
| 1 | `main()` — `NotificationService.initMinimal()` (timezone only) |
| 2 | `ProviderScope` + `MaterialApp` with Korean locale |
| 3 | `SplashScreen` — checks `showSplash` setting, skips if disabled |
| 4 | `CalendarNotifier.build()` — parallel load settings + events via `Future.wait` |
| 5 | `NotificationService.initNotifications()` — heavy plugin initialized safely |
| 6 | `_rebuildIndex()` — expands recurrences, generates holidays via background `Isolate (compute)` |
| 7 | `CalendarScreen.build()` — renders scaffold, drawer, sliding panel, calendar grid |

#### 9.5 _rebuildIndex Flow

Called on: app start / event add·edit·delete / settings change (holidays or theme only) / viewport shift (≥6 months).

1. Calculates ±12 month window from `_windowCenter`
2. `HolidayUtil.generateHolidaysForWindow()` — executed in background `Isolate`
3. Builds `holidayDates: Set<String>` for O(1) lookup in `CalendarTile`
4. `_expandRecurring()` — executed in background `Isolate`
5. `SlotCalculator.calculate()` — assigns display row slots (longest events first)
6. Recalculates `cachedArrowRowHeight` if `showTextInside` theme
7. `state = state.copyWith(...)` — single atomic state update

#### 9.6 Holiday Generation

`HolidayUtil` processes three layers per year:
1. **Solar holidays** — 8 fixed MM/DD dates.
2. **Lunar holidays** — `Lunar.fromYmd()` converts 음력 dates.
3. **Substitute holidays** — Sequential overlap pushing logic applied.

#### 9.7 Slot Assignment (SlotCalculator)

Events sorted by: duration (longest first) → start date → all-day first → start time → title.  
`slotMap: Map<int, int>` persists across `_rebuildIndex` calls (`firstLoad: false`) to prevent row jumping on month navigation.

#### 9.8 Gesture Sliding Panel

    AnimatedPositioned
      bottom: _isPanelOpen ? 0 : -_panelHeight
      duration: 350ms, curve: easeOutCubic

#### 9.9 ICS Export / Import

**Export** — `IcsService.exportToIcs()` builds a `VCALENDAR` string. File written to temp directory, shared via `SharePlus.instance.share(ShareParams(...))` (share_plus ^12.x).  
**Import** — Parses `SUMMARY`, `DTSTART`, `DTEND`. Fresh IDs generated via `EventStorage.generateId()` (`Random.secure()`).

#### 9.10 Conditional Import (Web Safety)

    services.dart exports:
      ics_service_stub.dart       — web (no-op)
      ics_service_io.dart         — dart.library.io (mobile)

This prevents `dart:io` crashes on web builds.

---

### 10. Changelog

---

#### v4.4.2 — Latest

| Type | Detail |
|---|---|
| 🟢 NEW | Splash screen ON/OFF toggle added to Settings |
| 🟢 NEW | `showSplash` field added to `AppSettings` (default: true) |
| 🔧 FIX | `widget_layout.xml` — `wrap_context` → `wrap_content` (Android build error) |
| 🔧 FIX | `settings_sheet.dart` — `_toggle` undefined error → replaced with `_switchTile` |
| ⬆️ DEP | Riverpod 2.x → 3.x migration (`StateNotifier` → `Notifier`, `StateNotifierProvider` → `NotifierProvider`) |
| ⬆️ DEP | `flutter_local_notifications` ^18 → ^19.5 (`uiLocalNotificationDateInterpretation` removed) |
| ⬆️ DEP | `share_plus` ^7 → ^12 (`Share.shareXFiles` → `SharePlus.instance.share(ShareParams(...))`) |
| ⬆️ DEP | `flutter_secure_storage` ^9.0 → ^9.2.4 |
| ⬆️ DEP | `timezone` ^0.9.4 → ^0.10.1 |
| ⬆️ DEP | `permission_handler` ^11 → ^12 |
| ⬆️ DEP | `flutter_lints` ^4 → ^5, `flutter_launcher_icons` ^0.13 → ^0.14.3 |
| 🔧 FIX | `app_drawer.dart` — unused import removed, `app_theme.dart` import restored |
| 🔧 FIX | `providers.dart` — unnecessary cast removed (`isolateResults` type inference) |
| 🔧 CI | `build_apk.yml` — `permissions: contents: write`, heredoc → echo, keystore conditional via steps output |
| 🔧 CI | `build.gradle.kts` — `signingConfigs.release` added (Kotlin DSL) |

---

#### v4.4.1

| Type | Detail |
|---|---|
| 🟢 NEW | Splash screen animation added |
| 🔧 FIX | Substitute holiday naming unified across all holiday types |
| 🔧 FIX | Slide mode "Today" button — `animateToPage` applied correctly |

---

#### v4.4.0

| Type | Detail |
|---|---|
| 🟢 NEW | Conditional import for web safety (`ics_service_stub` / `ics_service_io`) |
| 🟢 NEW | `services.dart` refactored to barrel export |
| 🟢 NEW | Sound options expanded to 8 types + vibration patterns expanded to 9 types |

---

#### v4.3.9

| Type | Detail |
|---|---|
| 🔧 FIX | `NotificationService.initNotifications` — `await` restored to prevent alarm race condition |
| 🔧 FIX | `_rescheduleAllAlarms` — recurrence instances excluded to prevent duplicate/stray alarms |
| 🔧 FIX | `context.mounted` guard added in `app_drawer.dart` ICS import callback |

---

#### v4.3.7

| Type | Detail |
|---|---|
| 🔧 FIX | `_rebuildIndex` windowing applied — `limit:500` removed from recurrence expansion |
| 🟡 PERF | `_calcRowHeight` extracted as helper to eliminate duplication |
| 🟢 NEW | `search_delegate.dart` — Korean 초성 search added |

---

#### v4.3.3

| Type | Detail |
|---|---|
| 🔧 FIX | Restored missing `app_theme.dart` import in `main.dart` |
| 🟢 NEW | `CupertinoDatePicker` month picker on header tap |
| 🟡 PERF | `NotificationService` init split (`initMinimal` + `initNotifications`) |
| 🟡 PERF | `EventStorage` `_cachedEvents` memoization |
| 🟡 PERF | `Future.wait` parallel load for settings + events |
| 🟡 PERF | Holiday generation + recurrence expansion moved to background `Isolate` |

---

#### v4.1.1

| Type | Detail |
|---|---|
| 🔴 FIX | `_safeParse` introduced to prevent crash on corrupted date data |
| 🟠 FIX | `Random.secure()` for event ID generation |
| 🟠 FIX | Advanced substitute holiday logic for Seollal/Chuseok blocks |
| 🟡 PERF | `_panelHeight` cached in `didChangeDependencies` |

---

#### v4.1.0

| Type | Detail |
|---|---|
| 🟢 NEW | Riverpod 2.x migration — `StateNotifierProvider` |
| 🟢 NEW | Side drawer + Gesture sliding event panel |
| 🟢 NEW | `CalendarState.holidayDates: Set<String>` for O(1) holiday lookups |
| 🟢 NEW | Home widget integration (`home_widget`) |

---

---

## 한국어

---

### 1. 개요

My Calendar는 Flutter로 개발된 Android / iOS 전용 오프라인 캘린더 앱입니다.  
모든 데이터는 **기기 내 암호화 저장소**에 보관됩니다 — 계정 가입·클라우드 동기화·광고 없음.

---

### 2. 주요 기능

| 기능 | 설명 |
|---|---|
| 📅 한국 공휴일 | 양력+음력 공휴일 + 대체공휴일 — 매년 자동 계산, 수동 업데이트 불필요 |
| 🔴 공휴일 빨간색 | 공휴일 날짜는 자동으로 빨간색 표시 |
| 🌙 음력 표시 | 매주 일요일 셀에 '음M.D' 형식으로 표시 |
| 🎨 6가지 테마 | 삼성 · 애플 · 네이버 · 다크 네온 · 클래식 블루 · 투두 스카이 |
| 📐 3가지 넘기기 | 화살표 버튼 · 상하 스와이프 · 좌우 스와이프 |
| 🔔 일정별 알림 | 알림 시간·방식·소리·진동을 일정마다 개별 설정 |
| 🔇 전체 무음 모드 | 알림을 일괄 무음 처리 — 개별 설정은 유지 |
| 🔍 초성 검색 | 'ㅎㅇ' 입력으로 '회의' 검색 |
| 📤 ICS 백업·복원 | Google Calendar·Apple Calendar 호환 표준 형식 |
| 🏠 홈 위젯 | 오늘 일정 최대 3개를 홈 화면에 표시 |
| 🔁 반복 일정 | 매일·매주·매월·매년, 종료일 설정 가능 |
| ✨ 스플래시 화면 | 앱 실행 시 애니메이션 화면 — 설정에서 ON/OFF 가능 |
| 🔒 완전 오프라인 | 인터넷 불필요, 모든 데이터 기기 내 암호화 |

---

### 3. 사용 방법

#### 3.1 첫 실행
1. 앱을 열면 이번 달 달력이 표시됩니다. 공휴일은 자동으로 **빨간색**으로 표시됩니다.
2. 날짜를 탭하면 하단에서 일정 패널이 슬라이드 올라옵니다.
3. 우측 하단 **+** 버튼으로 첫 일정을 추가하세요.

#### 3.2 일정 추가
1. **+** 버튼 탭 → 일정 편집기 열림
2. 제목 입력
3. 시작/종료 날짜 설정. **종일** 토글로 하루 종일 일정 설정 가능
4. 알림 설정: 시간·방식(소리/진동)·소리·진동 패턴
5. 반복 설정(선택): 매일·매주·매월·매년, 종료일 선택 가능
6. 색상 점으로 시각적 구분
7. **저장** 탭

#### 3.3 수정 · 삭제
일정 패널에서 일정 탭 → 액션 시트 → **수정** 또는 **삭제** 선택

#### 3.4 검색
🔍 아이콘 탭 → 키워드 또는 초성 입력 → 결과 탭으로 해당 날짜로 이동

#### 3.5 슬라이딩 패널
- 달력 어디서든 **위로 스와이프** → 일정 패널 열림
- 패널 핸들을 **아래로 스와이프** → 패널 닫힘

---

### 4. 사이드 드로어

좌측 상단 **≡** 아이콘으로 열기

| 메뉴 | 설명 |
|---|---|
| 🎨 테마 | 6가지 시각 테마 전환 |
| 📤 ICS 내보내기 | `.ics` 파일로 일정 공유 |
| 📥 ICS 불러오기 | `.ics` 파일에서 일정 가져오기 |
| ⚙️ 설정 | 알림·표시·탐색 설정 |

---

### 5. 설정

| 설정 | 설명 |
|---|---|
| 음력 표시 (일요일) | 매주 일요일에 '음M.D' 형식으로 음력 날짜 표시 |
| 공휴일 표시 | 한국 공휴일 빨간색 자동 표시 ON/OFF |
| 넘기기 모드 | 화살표 / 상하 스와이프 / 좌우 스와이프 |
| 알림 마스터 스위치 | 모든 일정 알림 일괄 ON/OFF |
| 기본 소리 | 시스템 · 차임 · 벨 · 새소리 · 피아노 · 기타 · 빗소리 · 파도 · 바람 · 직접 선택 |
| 기본 진동 | 9가지 패턴 (기본 · 심장박동 · 크레셴도 · SOS · 트리플 · 래피드 등) |
| 무음 모드 | 모든 알림 소리·진동 일괄 차단 |
| ✨ 스플래시 화면 | 앱 실행 시 애니메이션 화면 ON/OFF |
| 📱 홈 위젯 스타일 | 위젯 표시 스타일 선택 |

---

### 6. 테마

| 테마 | 스타일 |
|---|---|
| 📱 삼성 캘린더 | 흰 카드, 파란 강조색, 인라인 이벤트 바 *(Android 기본값)* |
| 🍎 애플 캘린더 | 깔끔한 흰 바탕, 빨간 강조색, 점 마커 *(iOS 기본값)* |
| 🇳 네이버 캘린더 | 흰 바탕, 초록 강조색, 인라인 바 |
| 🌙 다크 네온 | 어두운 보라, 네온 강조색, 둥근 카드 |
| ☁️ 클래식 블루 | 연한 파랑-회색, 테두리 카드 |
| ✅ 투두 스카이 | 흰 달력 + 진한 네이비 일정 목록 |

---

### 10. 변경 이력

---

#### v4.4.2 — 최신

| 구분 | 내용 |
|---|---|
| 🟢 NEW | 설정에 스플래시 화면 ON/OFF 토글 추가 |
| 🟢 NEW | `AppSettings`에 `showSplash` 필드 추가 (기본값: true) |
| 🔧 FIX | `widget_layout.xml` — `wrap_context` → `wrap_content` (Android 빌드 오류 수정) |
| 🔧 FIX | `settings_sheet.dart` — `_toggle` 미정의 오류 → `_switchTile`로 교체 |
| ⬆️ DEP | Riverpod 2.x → 3.x 마이그레이션 (`StateNotifier` → `Notifier`, `StateNotifierProvider` → `NotifierProvider`) |
| ⬆️ DEP | `flutter_local_notifications` ^18 → ^19.5 (`uiLocalNotificationDateInterpretation` 파라미터 제거) |
| ⬆️ DEP | `share_plus` ^7 → ^12 (`Share.shareXFiles` → `SharePlus.instance.share(ShareParams(...))`) |
| ⬆️ DEP | `flutter_secure_storage` ^9.0 → ^9.2.4 |
| ⬆️ DEP | `timezone` ^0.9.4 → ^0.10.1 |
| ⬆️ DEP | `permission_handler` ^11 → ^12 |
| ⬆️ DEP | `flutter_lints` ^4 → ^5, `flutter_launcher_icons` ^0.13 → ^0.14.3 |
| 🔧 FIX | `app_drawer.dart` — 불필요한 import 제거, `app_theme.dart` import 복원 |
| 🔧 FIX | `providers.dart` — 불필요한 타입 캐스팅 제거 |
| 🔧 CI | `build_apk.yml` — `permissions: write`, heredoc → echo 방식, steps output 기반 keystore 조건 처리 |
| 🔧 CI | `build.gradle.kts` — Kotlin DSL `signingConfigs.release` 추가 |

---

#### v4.4.1

| 구분 | 내용 |
|---|---|
| 🟢 NEW | 스플래시 화면 애니메이션 추가 |
| 🔧 FIX | 대체공휴일 명칭 모든 공휴일 유형에서 통일 |
| 🔧 FIX | 슬라이드 모드 "오늘" 버튼 `animateToPage` 정상 적용 |

---

#### v4.4.0

| 구분 | 내용 |
|---|---|
| 🟢 NEW | 웹 안전성을 위한 조건부 임포트 적용 (`ics_service_stub` / `ics_service_io`) |
| 🟢 NEW | `services.dart` 배럴 익스포트 구조로 리팩터링 |
| 🟢 NEW | 알림 소리 8종 + 진동 패턴 9종으로 확장 |

---

#### v4.3.9

| 구분 | 내용 |
|---|---|
| 🔧 FIX | `NotificationService.initNotifications` `await` 누락 복원 → 알람 경쟁 조건 방지 |
| 🔧 FIX | `_rescheduleAllAlarms` — 반복 일정 인스턴스 제외하여 중복/오발 알람 방지 |
| 🔧 FIX | `app_drawer.dart` ICS 불러오기 콜백에 `context.mounted` 가드 추가 |

---

#### v4.3.7

| 구분 | 내용 |
|---|---|
| 🔧 FIX | `_rebuildIndex` 윈도잉 적용 — 반복 확장에서 `limit:500` 제거 |
| 🟡 성능 | `_calcRowHeight` 헬퍼 분리로 중복 코드 제거 |
| 🟢 NEW | `search_delegate.dart` — 초성 검색 추가 |

---

#### v4.3.3

| 구분 | 내용 |
|---|---|
| 🔧 FIX | `main.dart` 누락된 `app_theme.dart` import 복원 |
| 🟢 NEW | 달력 헤더 탭 시 `CupertinoDatePicker` 날짜 이동 |
| 🟡 성능 | `NotificationService` 초기화 분리 (`initMinimal` + `initNotifications`) |
| 🟡 성능 | `EventStorage` `_cachedEvents` 메모이제이션 |
| 🟡 성능 | `Future.wait` 병렬 로드 (설정 + 이벤트) |
| 🟡 성능 | 공휴일 계산 + 반복 일정 확장 백그라운드 `Isolate`로 이동 |

---

#### v4.1.1

| 구분 | 내용 |
|---|---|
| 🔴 FIX | 손상된 날짜 데이터 크래시 방지 (`_safeParse` 도입) |
| 🟠 FIX | 일정 ID 생성에 `Random.secure()` 적용 |
| 🟠 FIX | 설날/추석 대체공휴일 고급 로직 적용 |
| 🟡 성능 | `_panelHeight` `didChangeDependencies`에서 캐싱 |

---

#### v4.1.0

| 구분 | 내용 |
|---|---|
| 🟢 NEW | Riverpod 2.x 전면 전환 및 상태 관리 최적화 |
| 🟢 NEW | 제스처 기반 슬라이딩 패널 및 사이드 드로어 통합 |
| 🟢 NEW | `Set` 자료구조를 활용한 O(1) 공휴일 렌더링 속도 향상 |
| 🟢 NEW | 바탕화면 홈 위젯 연동 기능 추가 |

---

*My Calendar v4.4.2 — last updated 2026-03-06*