// v4.3.9
// claude_settings_sheet.dart
// lib/ui/widgets/settings_sheet.dart
// ignore_for_file: curly_braces_in_flow_control_structures
// calendar_screen.dart에서 분리된 앱 설정 바텀시트
// - 클래스명: _AppSettingsSheet → AppSettingsSheet (public)
// - 달력 설정(음력, 공휴일, 넘기기 방식) + 알림 설정(소리/진동) + 무음모드
// - 호출부: calendar_screen._showSettingsSheet → showModalBottomSheet(builder: AppSettingsSheet(...))
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../services/services.dart';

class AppSettingsSheet extends StatefulWidget {
  final AppSettings initial;
  final bool isDark;
  final Color accent;
  final ValueChanged<AppSettings> onChanged;

  const AppSettingsSheet({
    super.key,
    required this.initial,
    required this.isDark,
    required this.accent,
    required this.onChanged,
  });

  @override
  State<AppSettingsSheet> createState() => _AppSettingsSheetState();
}

class _AppSettingsSheetState extends State<AppSettingsSheet> {
  late AppSettings _s;

  @override
  void initState() {
    super.initState();
    _s = widget.initial;
  }

  void _update(AppSettings next) {
    setState(() {
      _s = next;
    });
    widget.onChanged(next);
  }

  Color get _text => widget.isDark ? Colors.white : const Color(0xFF1A1A2E);
  Color get _sub => widget.isDark ? Colors.white54 : Colors.black54;
  Color get _tile =>
      widget.isDark ? const Color(0xFF3D3760) : const Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        color: widget.isDark ? const Color(0xFF2A2640) : Colors.white,
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2)))),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const SizedBox(width: 48),
              Text('⚙️ 앱 설정',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: _text)),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('완료',
                      style: TextStyle(
                          color: widget.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)))
            ]),
            const SizedBox(height: 10),
            _sectionTitle('📅 달력 설정'),
            _switchTile(
                icon: Icons.calendar_today_outlined,
                label: '음력 표시 (일요일)',
                subtitle: '매주 일요일 양력 날짜 옆에 음력을 표시합니다',
                value: _s.showLunarCalendar,
                onChanged: (v) {
                  _update(_s.copyWith(showLunarCalendar: v));
                }),
            _switchTile(
                icon: Icons.flag_outlined,
                label: '공휴일 표시',
                subtitle: '한국의 주요 공휴일을 표시합니다',
                value: _s.showHolidays,
                onChanged: (v) {
                  _update(_s.copyWith(showHolidays: v));
                }),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: _tile, borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.swap_vert, color: widget.accent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('달력 넘기기 방식',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: _text)),
                              Text('월 이동 방법을 선택합니다',
                                  style: TextStyle(fontSize: 12, color: _sub))
                            ]))
                      ]),
                      const SizedBox(height: 12),
                      Row(
                          children: [
                        CalendarNavMode.arrow,
                        CalendarNavMode.swipeHorizontal
                      ].map((mode) {
                        final isSel = _s.calendarNavMode == mode;
                        final isLast = mode == CalendarNavMode.swipeHorizontal;
                        return Expanded(
                            child: GestureDetector(
                          onTap: () {
                            _update(_s.copyWith(calendarNavMode: mode));
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: isLast ? 0 : 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                color: isSel
                                    ? widget.accent.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: isSel
                                        ? widget.accent
                                        : (widget.isDark
                                            ? Colors.white24
                                            : Colors.grey.shade300),
                                    width: isSel ? 2 : 1)),
                            child: Column(children: [
                              mode == CalendarNavMode.arrow
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.chevron_left,
                                            color: isSel ? widget.accent : _sub,
                                            size: 22),
                                        Icon(Icons.chevron_right,
                                            color: isSel ? widget.accent : _sub,
                                            size: 22),
                                      ],
                                    )
                                  : Icon(Icons.swap_horiz,
                                      color: isSel ? widget.accent : _sub,
                                      size: 22),
                              const SizedBox(height: 4),
                              Text(mode.label,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isSel ? widget.accent : _sub))
                            ]),
                          ),
                        ));
                      }).toList()),
                    ]),
              ),
            ),
            const SizedBox(height: 16),
            _sectionTitle('📱 홈 위젯 스타일'),
            _widgetThemeSelector(),
            const SizedBox(height: 16),
            _sectionTitle('🔔 알림 기본 설정'),
            _switchTile(
                icon: Icons.notifications_outlined,
                label: '알림 사용',
                subtitle: '모든 일정 알림을 켜거나 끕니다',
                value: _s.masterEnabled,
                onChanged: (v) {
                  _update(_s.copyWith(masterEnabled: v));
                }),
            if (_s.masterEnabled) ...[
              const SizedBox(height: 16),
              _sectionTitle('새 일정 추가 시 알람 소리/진동 기본값'),
              _switchTile(
                  icon: Icons.volume_up_outlined,
                  label: '소리 허용',
                  subtitle: '기본적으로 소리 알람을 사용합니다',
                  value: _s.globalSilentMode ? false : _s.soundEnabled,
                  disabled: _s.globalSilentMode,
                  onChanged: _s.globalSilentMode
                      ? null
                      : (v) {
                          _update(_s.copyWith(soundEnabled: v));
                        }),
              _switchTile(
                  icon: Icons.vibration_outlined,
                  label: '진동 허용',
                  subtitle: '기본적으로 진동 알람을 사용합니다',
                  value: _s.globalSilentMode ? false : _s.vibrationEnabled,
                  disabled: _s.globalSilentMode,
                  onChanged: _s.globalSilentMode
                      ? null
                      : (v) {
                          _update(_s.copyWith(vibrationEnabled: v));
                        }),
              _switchTile(
                  icon: Icons.volume_off_outlined,
                  label: '무음모드',
                  subtitle: '켜면 모든 소리·진동 알림이 무음으로 차단됨',
                  value: _s.globalSilentMode,
                  onChanged: (v) {
                    _update(_s.copyWith(globalSilentMode: v));
                  }),
              if (!_s.globalSilentMode && _s.soundEnabled) ...[
                const SizedBox(height: 16),
                _sectionTitle('기본 소리 설정'),
                ...NotificationSound.values.map((s) => _soundTile(s))
              ],
              if (!_s.globalSilentMode && _s.vibrationEnabled) ...[
                const SizedBox(height: 16),
                _sectionTitle('기본 진동 패턴'),
                ...VibrationPattern.values.map((p) => _vibrationTile(p))
              ],
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_circle_fill_outlined),
                      label: const Text('현재 기본 설정으로 알림 테스트'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: widget.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      onPressed: () {
                        NotificationService.showTestNotification(
                            _s, _s.effectiveMode);
                      })),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // [v4.3.8] 홈 위젯 테마 선택 UI
  Widget _widgetThemeSelector() {
    return Column(
      children: WidgetTheme.values.map((theme) {
        final isSel = _s.dynamicWidgetTheme == theme;
        final cfg = AppThemeExt.widgetConfig(theme);
        return GestureDetector(
          onTap: () {
            _update(_s.copyWith(dynamicWidgetTheme: theme));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: isSel ? widget.accent.withValues(alpha: 0.12) : _tile,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isSel ? widget.accent : Colors.transparent,
                    width: 1.5)),
            child: Row(children: [
              // 미리보기 색상 도트
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cfg.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    switch (theme) {
                      WidgetTheme.flip => 'A',
                      WidgetTheme.circle => 'B',
                      WidgetTheme.classic => 'C',
                      WidgetTheme.astronomical => 'D', // 💡 에러 원인 완벽 수정!
                    },
                    style: TextStyle(
                        color: cfg.textPrimary == Colors.white
                            ? Colors.white
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(theme.label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSel ? widget.accent : _text)),
                    Text(cfg.motionTag,
                        style: TextStyle(fontSize: 11, color: _sub)),
                  ])),
              if (isSel)
                Icon(Icons.check_circle, color: widget.accent, size: 20)
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _soundTile(NotificationSound s) {
    if (s == NotificationSound.custom) {
      final isSel = _s.soundOption == NotificationSound.custom;
      return GestureDetector(
        onTap: () {
          FilePicker.platform.pickFiles(type: FileType.audio).then((r) {
            if (r != null) {
              _update(_s.copyWith(
                  soundOption: NotificationSound.custom,
                  customSoundPath: r.files.single.path));
            }
          });
        },
        child: _selectableTile(
            icon: Icons.library_music_outlined,
            isSel: isSel,
            label: s.label,
            sub: _s.customSoundPath?.split('/').last),
      );
    }
    return GestureDetector(
        onTap: () {
          _update(_s.copyWith(soundOption: s));
        },
        child: _selectableTile(
            icon: Icons.music_note,
            isSel: _s.soundOption == s,
            label: s.label));
  }

  Widget _vibrationTile(VibrationPattern p) => GestureDetector(
      onTap: () {
        _update(_s.copyWith(vibrationPattern: p));
      },
      child: _selectableTile(
          icon: Icons.vibration,
          isSel: _s.vibrationPattern == p,
          label: p.label));

  Widget _selectableTile(
          {required IconData icon,
          required bool isSel,
          required String label,
          String? sub}) =>
      Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: isSel ? widget.accent.withValues(alpha: 0.12) : _tile,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSel ? widget.accent : Colors.transparent,
                  width: 1.5)),
          child: Row(children: [
            Icon(icon, color: isSel ? widget.accent : _sub, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSel ? widget.accent : _text)),
                  if (sub != null)
                    Text(sub,
                        style: TextStyle(fontSize: 11, color: _sub),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)
                ])),
            if (isSel) Icon(Icons.check_circle, color: widget.accent, size: 20)
          ]));

  Widget _sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(t,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _sub,
              letterSpacing: 0.5)));

  Widget _switchTile(
          {required IconData icon,
          required String label,
          required String subtitle,
          required bool value,
          ValueChanged<bool>? onChanged,
          Color? activeColor,
          bool disabled = false}) =>
      Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
                color: _tile, borderRadius: BorderRadius.circular(14)),
            child: SwitchListTile(
                secondary: Icon(icon,
                    color: value ? (activeColor ?? widget.accent) : _sub),
                title: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _text)),
                subtitle:
                    Text(subtitle, style: TextStyle(fontSize: 12, color: _sub)),
                value: value,
                activeTrackColor: activeColor ?? widget.accent,
                activeThumbColor: Colors.white,
                onChanged: onChanged)),
      );
}
