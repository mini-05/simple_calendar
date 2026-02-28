// v4.3.6
// claude_theme_dialog.dart
// lib/ui/widgets/theme_dialog.dart
// ignore_for_file: curly_braces_in_flow_control_structures
// 설정 내 테마 선택 그리드 UI
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

Future<void> showThemeDialog({
  required BuildContext context,
  required CalendarTheme th,
  required AppSettings settings,
  required Future<void> Function(AppTheme) onSelect,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: th.isDark ? const Color(0xFF2A2640) : Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) =>
        _ThemePickerSheet(th: th, settings: settings, onSelect: onSelect),
  );
}

class _ThemePickerSheet extends StatelessWidget {
  final CalendarTheme th;
  final AppSettings settings;
  final Future<void> Function(AppTheme) onSelect;

  const _ThemePickerSheet(
      {required this.th, required this.settings, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('테마 선택',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: th.isDark ? Colors.white : const Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: AppTheme.values.map((t) {
                final data = t.themeData;
                final isSel = th.type == t;
                return GestureDetector(
                  onTap: () async {
                    await onSelect(t);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSel
                          ? data.primaryAccent.withValues(alpha: 0.15)
                          : (th.isDark
                              ? const Color(0xFF3D3760)
                              : const Color(0xFFF5F5F5)),
                      borderRadius: BorderRadius.circular(14),
                      border: isSel
                          ? Border.all(color: data.primaryAccent, width: 2)
                          : null,
                    ),
                    child: Row(children: [
                      _colorDot(data.scaffoldBg),
                      const SizedBox(width: 4),
                      _colorDot(data.primaryAccent),
                      const SizedBox(width: 12),
                      Text('${data.emoji}  ${data.name}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: th.isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E))),
                      const Spacer(),
                      if (isSel)
                        Icon(Icons.check_circle,
                            color: data.primaryAccent, size: 22),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _colorDot(Color color) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
      );
}
