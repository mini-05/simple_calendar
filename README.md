# My Calendar App v2.7.0

Welcome to the **My Calendar App**! This application is designed to provide the ultimate schedule management experience while keeping your personal data completely safe with military-grade encryption.

## 📖 How to Use the App (User Guide)

### 1. Adding and Managing Events

* **Smart Event Addition:** Click the floating `+` button at the bottom right to add an event.
* **Auto Time Correction:** If you accidentally set the end time earlier than the start time, the app will smartly auto-correct the end time to be 1 hour after the start time.
* **Dynamic Calendar View:** Don't worry about having too many events in one day! The calendar cell will dynamically adjust text sizes or switch to a `+N` view to ensure your calendar always looks clean and beautiful.

### 2. Personalized Alarm Settings (Per Event)

* **Custom Sounds & Vibrations:** You can now set a different alarm sound and vibration pattern for *each individual event*.
* **Use Your Own Music:** Want to wake up to your favorite song? Select the `🎵 Custom Local Music` option to pick an mp3 file directly from your phone.
* **Sensory Vibrations:** Choose from elegant haptic patterns like "Heartbeat", "Crescendo", or "Long Pulse".

### 3. Quick Alarm Toggle

* **One-Touch ON/OFF:** In your daily event list, you will see a bell icon (🔔) next to events with alarms. Simply tap this icon to instantly turn the alarm off. It will visually change to a sleeping bell (🔕/Zz) so you know it's muted.

### 4. Global Silent Mode

* **Meeting/Study Mode:** Need to silence all alarms immediately? Toggle the **"Global Silent"** switch located at the top right of your event list.
* **Visual Sync:** When Global Silent is ON, all individual event alarms will automatically show the sleeping bell icon (🔕) to indicate they are suppressed. Turn it OFF, and they will revert to their original state.

### 5. Custom Themes

* Click the menu icon (≡) on the top right of the app bar to change the app's theme. Choose from Apple, Samsung, Naver, Dark Neon, and more. Your theme choice is securely saved and restored when you restart the app.

---

## 🛠️ Change Log (v2.7.0)

### 🧑‍💻 User Perspective

* **Global Silent Switch:** Added a master toggle to easily mute/unmute all event alarms at once.
* **Instant Alarm Toggle:** Tapping the bell icon next to an event now instantly turns the alarm ON/OFF with a visual change to a 'Zz' (paused) icon.
* **Per-Event Customization:** Users can now set entirely different sounds (including local music files) and vibration patterns for every single event.
* **Dynamic Rendering:** Improved the calendar cell UI to smartly adjust text size based on the number of events, preventing visual overflow.
* **Settings UI:** Added a 'Done' button in the settings menu for easier navigation.

### 👨‍💻 Developer Perspective

* **Dynamic Notification Channels (`_ensureChannel`):** Implemented an advanced dynamic channel generator to support infinite combinations of custom sounds and vibration patterns per event without channel clashing.
* **Windows Debug Bypass:** Added `Platform.isAndroid || Platform.isIOS` checks to bypass `flutter_local_notifications` initialization on Windows, preventing crashes during UI testing.
* **UI Linter Fixes:** Cleaned up dead code (e.g., removing unused `_buildEffectiveModeBadge`) and unnecessary imports for a 0-warning, 0-error clean build.
* **Military-Grade Security Maintained:** * Kept AES-256 GCM hardware encryption (`flutter_secure_storage`).
* Maintained `FLAG_SECURE` to block screenshots and background preview leaks.
* Maintained exact alarm permission error fallbacks and rate limits (max 500 events).



# My Calendar App v2.7.0

**My Calendar App**에 오신 것을 환영합니다! 이 앱은 군사급 암호화 기술로 사용자의 개인 데이터를 완벽하게 보호하면서도, 최고의 일정 관리 경험을 제공하도록 설계되었습니다.

## 📖 사용자 가이드 (이용 방법)

### 1. 스마트한 일정 추가 및 관리

* **일정 추가:** 우측 하단의 `+` 버튼을 눌러 새로운 일정을 등록하세요.
* **시간 자동 보정:** 실수로 종료 시간을 시작 시간보다 과거로 설정하더라도 걱정하지 마세요. 앱이 똑똑하게 종료 시간을 시작 시간 1시간 뒤로 자동 조정해 줍니다.
* **다이내믹 달력 뷰:** 하루에 일정이 너무 많아도 달력이 지저분해지지 않습니다. 앱이 스스로 일정 개수를 파악하여 글자 크기를 줄이거나 남은 일정을 `+N` 형태로 깔끔하게 요약해서 보여줍니다.

### 2. 일정별 맞춤 알림 설정

* **개별 소리 및 진동:** 이제 앱 전체 설정뿐만 아니라, **각각의 일정마다** 서로 다른 알림 소리와 진동을 설정할 수 있습니다.
* **내 휴대폰 음악 사용:** 중요한 약속에는 내가 좋아하는 노래를 알람으로 설정해 보세요! `🎵 내 휴대폰 음악 사용`을 선택해 폰에 있는 mp3 파일을 직접 고를 수 있습니다.
* **감성적인 진동:** 단순한 떨림이 아닌 '심장 박동', '크레센도' 등 고급스러운 햅틱 피드백을 지원합니다.

### 3. 원터치 알림 끄기 (빠른 제어)

* 일정 목록을 보면 알림이 설정된 일정 옆에 **종 모양(🔔) 아이콘**이 있습니다. 이 아이콘을 가볍게 터치하면 설정 창에 들어갈 필요 없이 즉시 알람이 꺼지고, 아이콘이 **수면 모드(🔕/Zz)**로 바뀝니다. 다시 누르면 켜집니다.

### 4. 전체 무음 모드 (회의/수업 시간 필수)

* 일정 목록 우측 상단에 있는 **'전체 무음' 스위치**를 켜보세요.
* 개별 일정이 소리나 진동으로 설정되어 있더라도, 이 스위치를 켜면 **모든 알림이 강제로 무음 처리**됩니다.
* 스위치를 켜면 목록의 모든 종 모양 아이콘이 수면 모드(🔕)로 변하여 시각적으로도 안심할 수 있습니다. 스위치를 끄면 원래 설정대로 완벽하게 복구됩니다.

### 5. 다양한 테마

* 상단 앱바 우측의 메뉴 아이콘(≡)을 눌러 애플, 삼성, 네이버, 다크 네온 등 다양한 테마로 캘린더를 꾸며보세요. 한 번 설정한 테마는 앱을 껐다 켜도 안전하게 유지됩니다.

---

## 🛠️ 수정 및 업데이트 사항 (v2.7.0)

### 🧑‍💻 이용자 관점 (User)

* **전체 무음 스위치 추가:** 탭 한 번으로 모든 일정의 알람 소리와 진동을 차단하는 마스터 스위치를 추가했습니다.
* **직관적인 알림 토글:** 일정 목록의 알림 아이콘(🔔)을 직접 터치하여 알람을 켜고 끌 수 있으며, 꺼졌을 때 수면(Zz) 아이콘으로 변경되어 상태를 쉽게 알 수 있습니다.
* **일정별 고유 알림 지정:** 각각의 일정마다 내 폰에 있는 다른 음악 파일이나 다른 진동 패턴을 독립적으로 설정할 수 있게 되었습니다.
* **반응형 다이내믹 렌더링:** 달력 셀 안에 일정이 많아질 경우, 글자 크기를 동적으로 줄이거나 `+N`으로 묶어 표현하여 화면이 깨지는 현상을 완벽히 방지했습니다.
* **설정 화면 사용성 개선:** 설정 창 우측 상단에 '완료' 버튼을 추가하여 쉽게 창을 닫을 수 있게 되었습니다.

### 👨‍💻 개발자 관점 (Developer)

* **동적 알림 채널 시스템(`_ensureChannel`):** 각 일정마다 커스텀 음원과 진동 패턴이 다를 경우, 안드로이드 Notification Channel이 꼬이지 않도록 해시(Hash)값을 이용해 채널을 무한대로 동적 생성하고 관리하는 로직을 구축했습니다.
* **PC 빌드 방어 로직 (Platform Guard):** Windows 데스크톱 환경에서 UI 디자인 디버깅 시 `flutter_local_notifications` 미구현 에러로 인해 앱이 크래시(강제 종료)되는 현상을 막기 위해 OS 분기 처리(`_isMobile`)를 완벽히 적용했습니다.
* **Linter Warning Zero 최적화:** 사용되지 않는 데드 코드(Dead Code)와 불필요한 import 패키지를 모두 제거하여 무결점 클린 코드를 달성했습니다.
* **군사급 보안 아키텍처 유지:** * `flutter_secure_storage`를 통한 하드웨어 레벨의 AES-256 데이터 암호화 로직 유지.
* 안드로이드 네이티브 단의 `FLAG_SECURE`를 이용한 스크린샷 및 화면 녹화, 백그라운드 유출 방어 기믹 유지.
* 메모리 오버플로우 방지를 위한 이벤트 Rate Limit(최대 500개 제한) 유지.



---