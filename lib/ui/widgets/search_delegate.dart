// v4.3.7
// claude_search_delegate.dart
// lib/ui/widgets/search_delegate.dart
// ignore_for_file: curly_braces_in_flow_control_structures
// calendar_screen.dart에서 분리된 일정 검색 delegate
// - 클래스명: _EventSearchDelegate → EventSearchDelegate (public)
// - 한글 초성 검색 지원 (DateFormatter.getChosung)
// - 탭 시 close(context, event) 반환 → 호출부(calendar_screen)에서 jumpToDate 처리
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/date_formatter.dart';
import '../../theme/app_theme.dart';

class EventSearchDelegate extends SearchDelegate<CalendarEvent?> {
  final List<CalendarEvent> allEvents;
  final CalendarTheme th;

  EventSearchDelegate(this.allEvents, this.th);

  @override
  String get searchFieldLabel => '일정 검색... (초성 가능)';

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
          backgroundColor: th.appBarBg,
          iconTheme: IconThemeData(color: th.appBarText),
          titleTextStyle: TextStyle(color: th.appBarText, fontSize: 18)),
      scaffoldBackgroundColor: th.scaffoldBg,
      inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(color: th.appBarText.withValues(alpha: 0.5)),
          border: InputBorder.none));

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
            icon: Icon(Icons.clear, color: th.appBarText),
            onPressed: () {
              query = '';
            })
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      icon: Icon(Icons.arrow_back, color: th.appBarText),
      onPressed: () {
        close(context, null);
      });

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final clean = query.replaceAll(' ', '').toLowerCase();
    if (clean.isEmpty) {
      return Center(
          child: Text('검색어를 입력하세요.',
              style: TextStyle(
                  color: th.sectionLabelText.withValues(alpha: 0.5),
                  fontSize: 16)));
    }
    final chosung = DateFormatter.getChosung(clean);
    final results = allEvents.where((e) {
      final t = e.title.replaceAll(' ', '').toLowerCase();
      return t.contains(clean) ||
          DateFormatter.getChosung(t).contains(chosung);
    }).toList();
    if (results.isEmpty) {
      return Center(
          child: Text('검색 결과가 없습니다.',
              style: TextStyle(
                  color: th.sectionLabelText.withValues(alpha: 0.5),
                  fontSize: 16)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final e = results[i];
        final color =
            e.colorValue != null ? Color(e.colorValue!) : th.primaryAccent;
        return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            title: Text(e.title,
                style: TextStyle(
                    color: th.eventTitleText, fontWeight: FontWeight.bold)),
            subtitle: Text(e.date, style: TextStyle(color: th.eventSubText)),
            onTap: () {
              close(context, e);
            });
      },
    );
  }
}
