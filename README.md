# 📅 My Calendar — v4.1.1

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
main.dart                    — App entry point, NotificationService.init()
app_config.dart              — AppConfig (appGroupId, widget names)
models/
models.dart                — CalendarEvent · AppSettings · RecurrenceRule · all enums
providers/
providers.dart             — CalendarState · CalendarNotifier · Riverpod providers
services/
services.dart              — NotificationService · EventStorage
AppSettingsStorage · IcsService
date_formatter.dart        — Date keys · Korean format · lunar label · 초성
slot_calculator.dart       — Event-row slot assignment algorithm
holidays.dart              — HolidayUtil (solar + lunar + substitute)
home_widget_service.dart   — HomeWidgetService (Android/iOS widget update)
theme/
app_theme.dart             — CalendarTheme data + 6 concrete themes
ui/
calendar_screen.dart       — CalendarScreen (ConsumerStatefulWidget)
Side drawer · sliding panel · SwipeHint
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


#### 9.4 App Start Sequence

| Step | What happens |
|---|---|
| 1 | `main()` — `NotificationService.init()` (timezone + plugin) |
| 2 | `ProviderScope` + `MaterialApp` with Korean locale |
| 3 | `CalendarNotifier._init()` — loads settings + events from encrypted storage |
| 4 | `_rebuildIndex(events, firstLoad: true)` — expands recurrences, generates holidays, calculates slots |
| 5 | `CalendarScreen.build()` — renders scaffold, drawer, sliding panel, calendar grid |

#### 9.5 _rebuildIndex Flow

Called on: app start / event add·edit·delete / settings change (holidays or theme only) / viewport shift (≥6 months).

1. Calculates ±12 month window from `_windowCenter`
2. `HolidayUtil.generateHolidaysForWindow()` — solar + lunar + substitute holidays
3. Builds `holidayDates: Set<String>` for O(1) lookup in `CalendarTile`
4. `_expandRecurring()` — expands recurring events within the window
5. `SlotCalculator.calculate()` — assigns display row slots (longest events first)
6. Recalculates `cachedArrowRowHeight` if `showTextInside` theme
7. `state = state.copyWith(...)` — single atomic state update

> **Performance note:** `updateSettings()` only triggers `_rebuildIndex` when `showHolidays` or `showTextInside` changes. Theme color / silent mode / alarm sound changes update state only — no rebuild.

#### 9.6 Holiday Generation

`HolidayUtil` processes three layers per year:

1. **Solar holidays** — 8 fixed MM/DD dates (신정, 삼일절, 어린이날, 현충일, 광복절, 개천절, 한글날, 크리스마스)
2. **Lunar holidays** — `Lunar.fromYmd()` converts 음력 dates. Seollal (음력 1/1) and Chuseok (음력 8/15) each generate a 3-day block (연휴 전날 · 당일 · 다음날). Buddha's Birthday (음력 4/8).
3. **Substitute holidays** — If a single holiday falls on Sunday → next available weekday. If Seollal/Chuseok block overlaps a Sunday or another holiday → one substitute day added after the block per overlap.

All holiday events use `id < 0` as the canonical `isHoliday` identifier.

#### 9.7 Slot Assignment (SlotCalculator)

Events sorted by: duration (longest first) → start date → all-day first → start time → title.  
Each event assigned the lowest available row slot that doesn't overlap with any event already placed on the same days.  
`slotMap: Map<int, int>` persists across `_rebuildIndex` calls (`firstLoad: false`) to prevent row jumping on month navigation.

#### 9.8 Gesture Sliding Panel

_isPanelOpen: bool  (setState)
_panelHeight: double  (cached in didChangeDependencies — not recalculated every build)

AnimatedPositioned
bottom: _isPanelOpen ? 0 : -_panelHeight
duration: 350ms, curve: easeOutCubic

Triggers:
GestureDetector.onVerticalDragEnd  velocity < -300 → open
velocity > 300  → close
Panel handle drag                  velocity > 200  → close
Drawer "Today" button              → open
Day selection                      → open


#### 9.9 ICS Export / Import

**Export** — `IcsService.exportToIcs()` builds a `VCALENDAR` string. All-day → `DATE` format. Timed → `DTSTART:YYYYMMDDTHHmmss` format. File written to temp directory, shared via `share_plus`. Recurring events export `RRULE:FREQ=...;INTERVAL=...;UNTIL=...`.

**Import** — Line-by-line parser reads `SUMMARY`, `DTSTART`, `DTEND`. New `CalendarEvent`s created with fresh IDs via `EventStorage.generateId()` (`Random.secure()`). Events appended to existing list and saved.

---

### 10. Changelog

---

#### v4.1.1 — Latest

| # | File | Severity | Fix |
|---|---|---|---|
| ① | `models.dart` | 🔴 Crash | `DateTime.parse` → `_safeParse` (tryParse + fallback): prevents FormatException crash on corrupted data or ICS import |
| ② | `calendar_screen.dart` | 🔴 Crash | `primaryVelocity!` force-unwrap → `?? 0` null-safe: prevents crash on certain devices where gesture velocity is null |
| ③ | `services.dart` | 🔴 Data loss | `AppSettingsStorage.save()` missing `await` fixed; `catch (_)` → `catch (e)` with log |
| ④ | `models.dart` | 🟠 Logic bug | Monthly/yearly recurrence end-of-month overflow fixed: `DateTime(y, m+1, 0).day` clamp (Jan 31 → monthly was overflowing to Mar 3) |
| ⑤ | `services.dart` | 🟠 ID collision | `generateId()` `math.Random()` → `math.Random.secure()`: uses OS entropy pool |
| ⑥ | `holidays.dart` | 🟠 Missing feature | `_getAlternativeHolidays()` substitute holiday logic implemented: Sunday overlap → next weekday; Seollal/Chuseok block overlap → sequential substitute days after block |
| ⑦ | `calendar_screen.dart` | 🟡 Performance | `panelHeight` recalculated every `build()` → cached in `didChangeDependencies()` as `_panelHeight` |
| ⑧ | `providers.dart` | 🟡 Performance | `updateSettings()` unconditional `_rebuildIndex` → only when `showHolidays` or `showTextInside` changes |

---

#### v4.1.0

| Type | Detail |
|---|---|
| 🟢 NEW | Riverpod 2.x migration — `StateNotifierProvider` + `CalendarNotifier` + `CalendarState` |
| 🟢 NEW | Side drawer — theme / ICS export / ICS import / settings in one place |
| 🟢 NEW | Gesture sliding event panel — swipe up to reveal, swipe down to dismiss |
| 🟢 NEW | `CalendarState.holidayDates: Set<String>` — O(1) holiday lookup per cell |
| 🟢 NEW | `CalendarTile.isHoliday` parameter — holiday date numbers shown in red |
| 🟢 NEW | Full alarm field persistence — `eventAlarmMode`, `soundOption`, `vibrationPattern` correctly saved on new event creation |
| 🟢 NEW | Home widget integration (`home_widget: ^0.7.0`) — today's events on home screen |
| 🟢 NEW | Holiday name refinement — '명절 연휴' → '설날 연휴' / '추석 연휴' |
| 🟢 NEW | AppBar today button with date badge |
| 🟢 NEW | `app_config.dart` — `AppConfig` constants for widget group ID and provider names |
| 🔧 FIX | `_switchTile` `disabled` parameter — sound/vibration switches visually disabled when silent mode is on |

---

#### v3.6.2

| Type | Detail |
|---|---|
| 🔴 FIX | Stored `showHolidays=OFF` ignored on launch |
| 🔴 FIX | Holiday generation (~750 lunar conversions) blocked UI thread — moved to background Isolate |
| 🔴 FIX | `PageView` swipe mode allowed infinite scroll past 2030 |
| 🔴 FIX | Multi-day holiday title placement used hardcoded title string comparison |
| 🔴 FIX | ICS export used bare `DTSTART` causing 9-hour UTC offset in Google/Apple Calendar |
| 🔴 FIX | `generateId()` applied `0x7FFFFFFF` mask twice, halving entropy |

---

#### v3.6.0

| Type | Detail |
|---|---|
| 🟢 NEW | Holiday system OCP refactoring — strategy pattern providers |
| 🟢 NEW | Holiday identification: title string → `id < 0` |
| 🔴 FIX | Lunar labels never displayed despite setting ON |

---

#### v3.2.0

| Type | Detail |
|---|---|
| 🟢 NEW | `lib/` split into `models` / `services` / `logic` / `theme` / `ui` |
| 🟢 NEW | Zero circular dependencies |

---

#### v1.0.0

| Type | Detail |
|---|---|
| 🟢 NEW | Initial releases: event CRUD, notifications, Korean holidays, monolithic → multi-file split |

---

---

## 한국어

---

### 1. 개요

My Calendar는 Flutter로 개발된 Android / iOS 전용 오프라인 캘린더 앱입니다.  
모든 데이터는 **기기 내 암호화 저장소**에 보관됩니다 — 계정 가입·클라우드 동기화·광고 없음.

- 한국 공휴일 자동 계산 (양력 + 음력 + 대체공휴일, 매년 자동 생성)
- 일요일 셀 음력 표시
- 일정별 알림 커스터마이징 (소리·진동 패턴 개별 설정)
- 제스처 슬라이딩 이벤트 패널
- 사이드 드로어 (테마·백업·설정 통합)
- 6가지 테마, 3가지 달력 넘기기 방식
- 홈 위젯 (오늘 일정 표시)

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
| 🔒 완전 오프라인 | 인터넷 불필요, 모든 데이터 기기 내 암호화 |

---

### 3. 시작하기

#### 3.1 첫 실행
1. 앱이 현재 월로 열립니다. 공휴일은 자동으로 **빨간색**으로 표시됩니다.
2. 날짜를 탭하면 하단에서 이벤트 패널이 슬라이드 올라옵니다.
3. 우측 하단 **+** 버튼으로 첫 일정을 추가하세요.

#### 3.2 일정 추가
1. **+** 탭 → 일정 편집 화면
2. 제목 입력
3. 시작/종료 날짜 설정. **하루 종일** 토글로 종일 일정 지정
4. 알림 설정: 알림 시간, 소리, 진동 패턴
5. 반복 설정 (선택): 매일·매주·매월·매년 + 종료일
6. 색상 점 선택
7. **저장**

#### 3.3 수정·삭제
패널에서 일정 탭 → **수정** 또는 **삭제**

#### 3.4 검색
🔍 아이콘 탭 → 키워드 또는 초성 입력 → 결과 탭하면 해당 날짜로 이동

#### 3.5 슬라이딩 패널
- 달력 화면에서 **위로 스와이프** → 이벤트 패널 열림
- 패널 핸들 **아래로 스와이프** → 닫힘
- 선택한 날짜의 일정 목록과 알람 토글 표시

---

### 4. 사이드 드로어

**≡** 아이콘(왼쪽 상단)으로 열기.

| 메뉴 | 설명 |
|---|---|
| 🎨 테마 | 6가지 테마 중 선택 |
| 📤 ICS 내보내기 | 일정을 `.ics` 파일로 공유 |
| 📥 ICS 불러오기 | `.ics` 파일에서 일정 가져오기 |
| ⚙️ 설정 | 알림·표시·넘기기 방식 설정 |

---

### 5. 설정

드로어 → 설정.

| 설정 | 설명 |
|---|---|
| 음력 표시 (일요일) | 매주 일요일에 음력 날짜 '음M.D' 표시 |
| 공휴일 표시 | 한국 공휴일 빨간색 표시 ON/OFF |
| 달력 넘기기 방식 | 화살표 / 상하 스와이프 / 좌우 스와이프 |
| 알림 마스터 | 모든 알림 일괄 ON/OFF |
| 기본 알림음 | 시스템 · 차임 · 벨 · 새소리 · 내 음악 파일 |
| 기본 진동 패턴 | 기본 진동 · 심장 박동 · 크레센도 · 길게 한 번 |
| 전체 무음 모드 | 소리·진동 전체 무음 처리 |

---

### 6. 테마

드로어 → 테마.

| 테마 | 스타일 |
|---|---|
| 📱 삼성 캘린더 | 흰색 배경, 파란색 포인트, 인라인 이벤트 바 *(기본값)* |
| 🍎 애플 캘린더 | 깔끔한 흰색 배경, 빨간색 포인트, 점(Dot) 마커 |
| 🇳 네이버 캘린더 | 흰색 배경, 초록색 포인트, 인라인 바 |
| 🌙 다크 네온 | 어두운 보라색 배경, 네온 포인트, 둥근 카드 |
| ☁️ 클래식 블루 | 밝은 블루그레이 배경, 테두리가 있는 카드 |
| ✅ 투두 스카이 | 흰색 달력 + 어두운 네이비색 일정 목록 패널 |

---

### 7. 알림

#### 일정별 알림
- **알림 시간:** 정각 · 5분 전 · 10분 전 · 30분 전 · 1시간 전 · 1일 전
- **알림 방식:** 소리만 · 진동만 · 소리+진동 · 무음
- **알림음:** 시스템 기본 · 차임 · 벨 · 새소리 · 내 음악 파일
- **진동:** 기본 진동 · 심장 박동 · 크레센도 · 길게 한 번

#### 전체 무음 모드
모든 알림을 일괄 무음 처리합니다. 개별 설정은 그대로 유지되며, 무음 모드 해제 시 설정이 복원됩니다.

> **참고:** 전체 무음 모드는 기기 벨소리 볼륨과 독립적으로 동작합니다.

---

### 8. 백업·복원 (ICS)

#### 8.1 내보내기
1. 드로어 → **ICS 내보내기**
2. `.ics` 파일 생성 후 공유 시트 열림
3. 파일로 저장하거나 이메일·Google Drive로 전송

#### 8.2 불러오기
1. 드로어 → **ICS 불러오기**
2. 기기에서 `.ics` 파일 선택
3. 기존 일정에 병합 (중복 자동 제거 없음)

> **참고:** ICS 파일에는 색상·알림 설정이 저장되지 않아 복원 시 기본값으로 설정됩니다.

---

### 9. 아키텍처 및 실행 흐름

*개발자용 섹션입니다.*

#### 9.1 모듈 구조

lib/
main.dart                    — 앱 진입점, NotificationService.init()
app_config.dart              — AppConfig (appGroupId, 위젯 이름 상수)
models/
models.dart                — CalendarEvent · AppSettings · RecurrenceRule · 모든 Enum
providers/
providers.dart             — CalendarState · CalendarNotifier · Riverpod Provider
services/
services.dart              — NotificationService · EventStorage
AppSettingsStorage · IcsService
date_formatter.dart        — 날짜 키 · 한국어 포맷 · 음력 레이블 · 초성
slot_calculator.dart       — 이벤트 행 슬롯 할당 알고리즘
holidays.dart              — HolidayUtil (양력 + 음력 + 대체공휴일)
home_widget_service.dart   — HomeWidgetService (Android/iOS 위젯 갱신)
theme/
app_theme.dart             — CalendarTheme 데이터 + 6가지 테마
ui/
calendar_screen.dart       — CalendarScreen (ConsumerStatefulWidget)
사이드 드로어 · 슬라이딩 패널 · SwipeHint
widgets/
calendar_tile.dart       — CalendarTile (날짜 셀 렌더러)
event_bar.dart           — EventBar (삼성/네이버 테마 인라인 바)
theme_dialog.dart        — 테마 선택 바텀 시트
dialogs/
event_editor.dart        — 일정 추가/수정 다이얼로그


#### 9.2 상태 관리 (Riverpod)

calendarProvider       — CalendarNotifier / CalendarState (메인 상태)
settingsProvider       — AppSettings (파생)
selectedDayProvider    — DateTime? (파생)
selectedEventsProvider — List<CalendarEvent> (파생)


`CalendarState` 주요 필드:

| 필드 | 타입 | 설명 |
|---|---|---|
| `masterEvents` | `List<CalendarEvent>` | 사용자 일정 전체 (반복 인스턴스 제외) |
| `eventsByDate` | `Map<String, List<CalendarEvent>>` | 날짜 키 → 이벤트 (확장 윈도우) |
| `slotMap` | `Map<int, int>` | 이벤트 id → 표시 행 슬롯 |
| `holidayDates` | `Set<String>` | 공휴일 날짜 키 Set (O(1) 조회용) |
| `selectedEvents` | `List<CalendarEvent>` | 선택된 날짜의 이벤트 |
| `focusedDay` | `DateTime` | 현재 포커스된 달력 월 |
| `selectedDay` | `DateTime?` | 탭된 날짜 |
| `settings` | `AppSettings` | 현재 앱 설정 |
| `cachedArrowRowHeight` | `double` | 사전 계산된 행 높이 (삼성/네이버 테마) |

#### 9.3 의존성 방향 (순환 참조 0건)

models  ←  services/logic  ←  providers  ←  ui
←  theme  ←────────────────────────────┘

models    : 순수 Dart — Flutter 의존성 없음
services  : models + Flutter foundation (compute, 알림)
providers : models + services + Riverpod
ui        : 위 모든 계층 import


#### 9.4 앱 시작 순서

| 단계 | 내용 |
|---|---|
| 1 | `main()` — `NotificationService.init()` (시간대 설정 + 알림 플러그인 초기화) |
| 2 | `ProviderScope` + 한국어 로케일 `MaterialApp` |
| 3 | `CalendarNotifier._init()` — 암호화 저장소에서 설정 + 이벤트 로드 |
| 4 | `_rebuildIndex(events, firstLoad: true)` — 반복 일정 확장, 공휴일 생성, 슬롯 계산 |
| 5 | `CalendarScreen.build()` — 스캐폴드·드로어·슬라이딩 패널·달력 그리드 렌더링 |

#### 9.5 _rebuildIndex 흐름

호출 시점: 앱 시작 / 일정 추가·수정·삭제 / 설정 변경 (공휴일·테마만) / 뷰포트 이동 (6개월 이상).

1. `_windowCenter` 기준 ±12개월 윈도우 계산
2. `HolidayUtil.generateHolidaysForWindow()` — 양력 + 음력 + 대체공휴일 생성
3. `holidayDates: Set<String>` 구성 — `CalendarTile`에서 O(1) 공휴일 판별
4. `_expandRecurring()` — 반복 일정을 윈도우 내 인스턴스로 확장
5. `SlotCalculator.calculate()` — 표시 행 슬롯 할당 (긴 일정 우선)
6. `showTextInside` 테마일 경우 `cachedArrowRowHeight` 재계산
7. `state = state.copyWith(...)` — 단일 원자적 상태 업데이트

> **성능 참고:** `updateSettings()`는 `showHolidays` 또는 `showTextInside`가 변경될 때만 `_rebuildIndex`를 호출합니다. 테마 색상·무음모드·알람 소리 변경은 상태만 업데이트하며 리빌드하지 않습니다.

#### 9.6 공휴일 생성

`HolidayUtil`이 연도별로 3단계 처리:

1. **양력 공휴일** — 8개 고정 MM/DD (신정·삼일절·어린이날·현충일·광복절·개천절·한글날·크리스마스)
2. **음력 공휴일** — `Lunar.fromYmd()`로 날짜 변환. 설날(음력 1/1)·추석(음력 8/15)은 각각 3일 연휴 블록 생성. 부처님오신날(음력 4/8).
3. **대체공휴일** — 단일 공휴일이 일요일과 겹치면 다음 평일. 설날/추석 연휴 블록이 일요일이나 다른 공휴일과 겹치면 연휴 직후 순차적으로 대체공휴일 추가.

모든 공휴일 이벤트는 `id < 0`을 `isHoliday` 판별의 기준으로 사용합니다.

#### 9.7 슬롯 할당 (SlotCalculator)

이벤트 정렬 기준: 기간 (긴 것 우선) → 시작 날짜 → 종일 일정 우선 → 시작 시간 → 제목 순.  
각 이벤트에 해당 기간 동안 다른 이벤트와 겹치지 않는 가장 낮은 행 슬롯 번호 할당.  
`slotMap`은 `firstLoad: false` 시 재사용되어 월 이동 시 행 번호 점프를 방지합니다.

#### 9.8 제스처 슬라이딩 패널

_isPanelOpen: bool  (setState)
_panelHeight: double  (didChangeDependencies에서 캐싱 — build마다 재계산 안 함)

AnimatedPositioned
bottom: _isPanelOpen ? 0 : -_panelHeight
duration: 350ms, curve: easeOutCubic

트리거:
GestureDetector.onVerticalDragEnd  속도 < -300 → 열기
속도 > 300  → 닫기
패널 핸들 드래그                    속도 > 200  → 닫기
드로어 "오늘" 버튼                  → 열기
날짜 선택                           → 열기


#### 9.9 ICS 내보내기 / 불러오기

**내보내기** — `IcsService.exportToIcs()`가 `VCALENDAR` 문자열 생성. 종일 일정 → `DATE` 포맷. 시간 지정 일정 → `DTSTART:YYYYMMDDTHHmmss`. 반복 일정은 `RRULE:FREQ=...;INTERVAL=...;UNTIL=...` 포함. 임시 디렉토리에 파일 저장 후 `share_plus`로 공유.

**불러오기** — 줄 단위 파서가 `SUMMARY`, `DTSTART`, `DTEND` 읽기. `EventStorage.generateId()` (`Random.secure()`)로 새 ID 부여. 기존 일정에 병합 후 저장.

---

### 10. 변경 이력

---

#### v4.1.1 — 최신

| # | 파일 | 심각도 | 내용 |
|---|---|---|---|
| ① | `models.dart` | 🔴 크래시 방지 | `DateTime.parse` → `_safeParse`: 손상 데이터·ICS import 시 FormatException 크래시 방지 |
| ② | `calendar_screen.dart` | 🔴 크래시 방지 | `primaryVelocity!` 강제 언래핑 → `?? 0`: 일부 기기에서 null 반환 시 크래시 방지 |
| ③ | `services.dart` | 🔴 데이터 손실 방지 | `AppSettingsStorage.save()` `await` 누락 수정, catch 로그 추가 |
| ④ | `models.dart` | 🟠 논리 버그 | 매월/매년 반복 말일 overflow 수정 (1월 31일 매월반복 → 3월로 넘어가던 문제) |
| ⑤ | `services.dart` | 🟠 ID 충돌 방지 | `generateId()` `Random()` → `Random.secure()` |
| ⑥ | `holidays.dart` | 🟠 누락 기능 | 대체공휴일 로직 구현: 일요일 겹침 → 다음 평일, 연휴 겹침 → 연휴 직후 순차 추가 |
| ⑦ | `calendar_screen.dart` | 🟡 성능 | `panelHeight` build() 매 프레임 계산 → `didChangeDependencies()` 캐싱 |
| ⑧ | `providers.dart` | 🟡 성능 | `updateSettings()` 조건부 리빌드 (showHolidays·showTextInside 변경 시에만) |

---

#### v4.1.0

| 구분 | 내용 |
|---|---|
| 🟢 NEW | Riverpod 2.x 전면 전환 — `StateNotifierProvider` + `CalendarNotifier` + `CalendarState` |
| 🟢 NEW | 사이드 드로어 — 테마·ICS 내보내기·ICS 불러오기·설정 통합 |
| 🟢 NEW | 제스처 슬라이딩 이벤트 패널 — 위로 스와이프로 열기, 아래로 스와이프로 닫기 |
| 🟢 NEW | `CalendarState.holidayDates: Set<String>` — 셀별 O(1) 공휴일 조회 |
| 🟢 NEW | `CalendarTile.isHoliday` 파라미터 — 공휴일 날짜 빨간색 표시 |
| 🟢 NEW | 알람 필드 완전 저장 — 신규 일정에 `eventAlarmMode·soundOption·vibrationPattern` 기본값 반영 |
| 🟢 NEW | 홈 위젯 연동 (`home_widget: ^0.7.0`) — 오늘 일정 최대 3개 홈 화면 표시 |
| 🟢 NEW | 공휴일 명칭 세분화 — '명절 연휴' → '설날 연휴' / '추석 연휴' |
| 🟢 NEW | AppBar 오늘 날짜 뱃지 표시 |
| 🟢 NEW | `app_config.dart` — 위젯 App Group ID·Provider 이름 상수 관리 |
| 🔧 FIX | 무음모드 시 소리·진동 스위치 비활성화 표시 |

---

#### v3.6.2

| 구분 | 내용 |
|---|---|
| 🔴 FIX | 저장된 `showHolidays=OFF` 앱 실행 시 무시되는 문제 |
| 🔴 FIX | 공휴일 생성(음력 변환 ~750회)이 UI 스레드 블로킹 — Isolate로 이동 |
| 🔴 FIX | 스와이프 모드 `PageView` 무한 스크롤 허용 문제 |
| 🔴 FIX | ICS 내보내기 `DTSTART` 포맷 오류 — Google/Apple Calendar 9시간 오프셋 |
| 🔴 FIX | `generateId()` 마스크 중복 적용으로 엔트로피 절반 손실 |

---

#### v3.6.0

| 구분 | 내용 |
|---|---|
| 🟢 NEW | 공휴일 시스템 OCP 리팩터링 — 전략 패턴 Provider |
| 🟢 NEW | 공휴일 식별: 타이틀 문자열 비교 → `id < 0` |
| 🔴 FIX | 음력 설정 ON에서도 미표시 문제 |

---

#### v3.2.0

| 구분 | 내용 |
|---|---|
| 🟢 NEW | `lib/` → `models/services/logic/theme/ui` 분리 |
| 🟢 NEW | 순환 참조 0건 |

---

#### v1.0.0

| 구분 | 내용 |
|---|---|
| 🟢 NEW | 초기 릴리즈: 일정 CRUD, 알림, 한국 공휴일, 단일파일 → 멀티파일 분리 |

---

*My Calendar v4.1.1 — last updated 2026-02-27*