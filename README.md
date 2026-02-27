# 📅 My Calendar — v4.3.3

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
| Default sound | System · Chime · Bell · Bird · Custom music file |
| Default vibration | Default pulse · Heartbeat · Crescendo · Long pulse |
| Silent mode | Suppresses all alarm sounds & vibrations globally |

---

### 6. Themes

Open via Side Drawer → Theme.

| Theme | Style |
|---|---|
| 📱 Samsung Calendar | White card, blue accent, inline event bars *(default)* |
| 🍎 Apple Calendar | Clean white, red accent, dot markers |
| 🇳 Naver Calendar | White, green accent, inline bars |
| 🌙 Dark Neon | Dark purple, neon accents, rounded cards |
| ☁️ Classic Blue | Light blue-grey, bordered cards |
| ✅ Todo Sky | White calendar + dark navy event list |

---

### 7. Notifications

#### Per-Event Alarm
- **Timing:** at the time · 5 min · 10 min · 30 min · 1 hour · 1 day before
- **Method:** Sound only · Vibration only · Sound + Vibration · Silent
- **Sound:** System default · Chime · Bell · Bird · custom file
- **Vibration:** Default pulse · Heartbeat · Crescendo · Long pulse

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
      main.dart                    — App entry point, NotificationService.initMinimal()
      app_config.dart              — AppConfig (appGroupId, widget names)
      models/
        models.dart                — CalendarEvent · AppSettings · RecurrenceRule · all enums
      providers/
        providers.dart             — CalendarState · CalendarNotifier · Riverpod providers
      services/
        services.dart              — NotificationService · EventStorage · AppSettingsStorage · IcsService
        date_formatter.dart        — Date keys · Korean format · lunar label · 초성
        slot_calculator.dart       — Event-row slot assignment algorithm
        holidays.dart              — HolidayUtil (solar + lunar + substitute)
        home_widget_service.dart   — HomeWidgetService (Android/iOS widget update)
      theme/
        app_theme.dart             — CalendarTheme data + 6 concrete themes
      ui/
        calendar_screen.dart       — CalendarScreen (ConsumerStatefulWidget)
        widgets/
          calendar_tile.dart       — CalendarTile (date cell renderer)
          event_bar.dart           — EventBar (inline bar for Samsung/Naver themes)
          theme_dialog.dart        — Theme picker bottom sheet
        dialogs/
          event_editor.dart        — Event add/edit dialog

#### 9.2 State Management (Riverpod)

    calendarProvider       — CalendarNotifier / CalendarState (main state)
    settingsProvider       — AppSettings (derived)
    selectedDayProvider    — DateTime? (derived)
    selectedEventsProvider — List<CalendarEvent> (derived)

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
| 3 | `CalendarNotifier._init()` — parallel load settings + events via `Future.wait` |
| 4 | `NotificationService.initNotifications()` — heavy plugin initialized safely |
| 5 | `_rebuildIndex()` — expands recurrences, generates holidays via background `Isolate (compute)` |
| 6 | `CalendarScreen.build()` — renders scaffold, drawer, sliding panel, calendar grid |

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

**Export** — `IcsService.exportToIcs()` builds a `VCALENDAR` string. File written to temp directory, shared via `share_plus`.  
**Import** — Parses `SUMMARY`, `DTSTART`, `DTEND`. Fresh IDs generated via `EventStorage.generateId()` (`Random.secure()`).

---

### 10. Changelog

---

#### v4.3.3 — Latest

| Type | Detail |
|---|---|
| 🔧 FIX | Restored missing `app_theme.dart` import in `main.dart` to resolve build error |
| 🔧 FIX | Replaced undefined `materialTheme` getter with direct `ThemeData` creation |
| 🟢 NEW | iPhone-style `CupertinoDatePicker` month picker added on header tap |
| 🟡 PERF | Split `NotificationService` initialization (`initMinimal` & `initNotifications`) to boost startup time |
| 🟡 PERF | Added `_cachedEvents` memoization in `EventStorage` to prevent redundant disk I/O |
| 🟡 PERF | `CalendarNotifier._init` now loads settings and events concurrently via `Future.wait` |
| 🟡 PERF | Shifted heavy holiday generation and recurrence expansion to background `Isolate` (via `compute`) |
| 🟡 PERF | Added `cacheExtent: 500` to Event ListView for smoother scrolling |
| 🔧 FIX | Arrow navigation mode now correctly fills the entire screen (`shouldFillViewport: true`) |
| 🔧 FIX | Arrow navigation mode header format unified to 'YYYY년 M월' across all themes |

---

#### v4.1.1

| Type | Detail |
|---|---|
| 🔴 FIX | Replaced `DateTime.parse` with `_safeParse` to prevent crashes on corrupted data |
| 🟠 FIX | Replaced Math.Random with `Random.secure()` for ID generation |
| 🟠 FIX | Implemented advanced substitute holiday logic for Seollal/Chuseok blocks |
| 🟡 PERF | Cached `_panelHeight` in `didChangeDependencies` to prevent recalculation on every build |

---

#### v4.1.0

| Type | Detail |
|---|---|
| 🟢 NEW | Riverpod 2.x migration — `StateNotifierProvider` |
| 🟢 NEW | Side drawer and Gesture sliding event panel |
| 🟢 NEW | `CalendarState.holidayDates: Set<String>` for O(1) holiday lookups |
| 🟢 NEW | Home widget integration (`home_widget`) |

---

---

## 한국어

---

### 1. 개요

My Calendar는 Flutter로 개발된 Android / iOS 전용 오프라인 캘린더 앱입니다.  
모든 데이터는 **기기 내 암호화 저장소**에 보관됩니다 — 계정 가입·클라우드 동기화·광고 없음.

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
| 🔒 완전 오프라인 | 인터넷 불필요, 모든 데이터 기기 내 암호화 |

---

### 10. 변경 이력

---

#### v4.3.3 — 최신

| 구분 | 내용 |
|---|---|
| 🔧 FIX | `main.dart` 파일에 누락된 `app_theme.dart` 임포트를 추가하여 테마 빌드 에러 완벽 해결 |
| 🔧 FIX | `main.dart`에서 플러터 표준 `ThemeData`를 직접 생성하도록 수정 |
| 🟢 NEW | 달력 상단 년/월 터치 시 아이폰 스타일의 `CupertinoDatePicker`로 날짜 이동 기능 추가 |
| 🟡 성능 | `NotificationService` 초기화를 분리(`initMinimal`)하여 앱 최초 구동 속도 대폭 개선 |
| 🟡 성능 | `EventStorage`에 메모이제이션(`_cachedEvents`)을 적용하여 불필요한 디스크 읽기 방지 |
| 🟡 성능 | 앱 실행 시 설정과 이벤트를 `Future.wait`로 동시(병렬) 로드하여 UI 논블로킹 최적화 |
| 🟡 성능 | 무거운 공휴일 계산 및 반복 일정 확장을 백그라운드 `Isolate(compute)`로 이동하여 렌더링 스터터링(버벅임) 완전 해결 |
| 🟡 성능 | 일정 목록 `ListView`에 `cacheExtent: 500`을 적용하여 스크롤 성능 최적화 |
| 🔧 FIX | 화살표 모드 사용 시 달력 하단 빈 공간이 생기던 현상 해결 (`Expanded` 및 `shouldFillViewport` 적용) |
| 🔧 FIX | 화살표 모드의 년/월 표시를 모든 테마에서 '2026년 2월' 형식으로 완전 통일 |

---

#### v4.1.1

| 구분 | 내용 |
|---|---|
| 🔴 FIX | `DateTime.parse` 강제 변환 시 발생하는 크래시 방지 (`_safeParse` 도입) |
| 🟠 FIX | 일정 ID 생성 시 OS 엔트로피를 사용하는 `Random.secure()`로 변경하여 중복 방지 |
| 🟠 FIX | 대체공휴일 무한 증식 논리 버그 수정 및 설날/추석 명절 연휴 완벽 대응 |
| 🟡 성능 | `_panelHeight`를 매 프레임 계산하지 않고 `didChangeDependencies`에서 캐싱 처리 |

---

#### v4.1.0

| 구분 | 내용 |
|---|---|
| 🟢 NEW | Riverpod 2.x 전면 전환 및 상태 관리 최적화 |
| 🟢 NEW | 제스처 기반 슬라이딩 패널 및 사이드 드로어 통합 |
| 🟢 NEW | `Set` 자료구조를 활용한 O(1) 공휴일 렌더링 속도 향상 |
| 🟢 NEW | 바탕화면 홈 위젯 연동 기능 추가 |

---

*My Calendar v4.3.3 — last updated 2026-02-28*