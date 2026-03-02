// v4.3.7
// claude_app_drawer.dart
// lib/ui/widgets/app_drawer.dart
// ignore_for_file: curly_braces_in_flow_control_structures
// calendar_screen.dart에서 분리된 사이드 드로어
// - ConsumerStatefulWidget: ref로 CalendarState/Notifier 직접 접근 (파라미터 전달 최소화)
// - 내부에서 AppSettingsSheet, showThemeDialog 직접 호출
// - mounted 체크 필요 → ConsumerStatefulWidget 채택
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import 'settings_sheet.dart';
import 'theme_dialog.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    final st = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);
    final th = st.settings.currentTheme.themeData;

    final textStyle = TextStyle(
        color: th.isDark ? Colors.white : Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w500);
    final iconColor = th.isDark ? Colors.white70 : Colors.black54;

    return Drawer(
      backgroundColor: th.isDark ? const Color(0xFF1E1B2E) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: th.isDark ? Colors.white12 : Colors.black12))),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: th.primaryAccent,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.calendar_month,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text('My Calendar',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: th.isDark ? Colors.white : Colors.black)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(Icons.palette_outlined, color: iconColor),
                    title: Text('테마', style: textStyle),
                    onTap: () {
                      Navigator.pop(context);
                      showThemeDialog(
                          context: context,
                          th: th,
                          settings: st.settings,
                          onSelect: (t) async {
                            await notifier.updateSettings(
                                st.settings.copyWith(currentTheme: t));
                          });
                    },
                  ),
                  Divider(
                      color: th.isDark ? Colors.white12 : Colors.black12,
                      height: 1),
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Icon(Icons.sync_alt_outlined, color: iconColor),
                      title: Text('백업 / 복원', style: textStyle),
                      iconColor: th.primaryAccent,
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 54),
                          title: Text('ICS 내보내기',
                              style: textStyle.copyWith(
                                  fontSize: 14,
                                  color: th.isDark
                                      ? Colors.white70
                                      : Colors.black54)),
                          onTap: () {
                            Navigator.pop(context);
                            notifier.exportIcs();
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 54),
                          title: Text('ICS 불러오기',
                              style: textStyle.copyWith(
                                  fontSize: 14,
                                  color: th.isDark
                                      ? Colors.white70
                                      : Colors.black54)),
                          onTap: () async {
                            Navigator.pop(context);
                            final ok = await notifier.importIcs();
                            // 💡 [v4.3.9] context.mounted 로 경고 해결
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok
                                  ? 'ICS 데이터가 성공적으로 병합되었습니다!'
                                  : '복구 실패: 취소했거나 올바른 ics 파일이 아닙니다.'),
                              backgroundColor:
                                  ok ? th.primaryAccent : Colors.red,
                            ));
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(
                      color: th.isDark ? Colors.white12 : Colors.black12,
                      height: 1),
                  ListTile(
                    leading: Icon(Icons.settings_outlined, color: iconColor),
                    title: Text('설정', style: textStyle),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor:
                            th.isDark ? const Color(0xFF2A2640) : Colors.white,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24))),
                        builder: (_) => AppSettingsSheet(
                            initial: st.settings,
                            isDark: th.isDark,
                            accent: th.primaryAccent,
                            onChanged: (updated) {
                              notifier.updateSettings(updated);
                            }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
