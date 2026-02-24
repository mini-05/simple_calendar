// ignore_for_file: curly_braces_in_flow_control_structures
// v3.6.0
import 'package:flutter/material.dart';
import '../models/models.dart';

abstract class CalendarTheme {
  AppTheme get type;
  String get name;
  String get emoji;
  Color get scaffoldBg;
  Color get appBarBg;
  Color get appBarText;
  Color get calendarBg;
  Color get primaryAccent;
  Color get secondaryAccent;
  Color get cardBg;
  Color get cardBorder;
  Color get eventTitleText;
  Color get eventSubText;
  Color get iconBg;
  Color get iconColor;
  Color get sectionLabelText;
  Color? get bottomPanelBg => null;
  bool get isDark => false;
  bool get showTextInside => false;

  /// true이면 달력을 패딩+둥근 카드 박스 안에 감쌉니다 (투두스카이, 다크네온)
  bool get hasRoundedCard => false;

  /// 바텀시트 배경색. null이면 기본(흰색/다크)으로 처리
  Color? get bottomSheetBg => null;
  Alignment get cellTextAlignment => Alignment.center;

  Widget buildTitleColumn(
      {required CalendarEvent event,
      required String dateInfo,
      required bool isGlobalSilent,
      required VoidCallback onToggleAlarm,
      Color? titleColor,
      double titleSize = 15,
      double dateSize = 12}) {
    final effectiveAlarmOn = event.isAlarmOn && !isGlobalSilent;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text(event.title,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: titleSize,
                    color: titleColor ?? eventTitleText))),
        if (event.alarmMinutes != AlarmMinutes.none)
          GestureDetector(
              onTap: onToggleAlarm,
              child: Padding(
                  padding: const EdgeInsets.only(
                      left: 8, right: 4, top: 2, bottom: 2),
                  child: Icon(
                      effectiveAlarmOn
                          ? Icons.notifications_active
                          : Icons.notifications_paused,
                      size: 16,
                      color: effectiveAlarmOn
                          ? primaryAccent
                          : Colors.grey.withValues(alpha: 0.5))))
      ]),
      if (dateInfo.isNotEmpty)
        Text(dateInfo, style: TextStyle(fontSize: dateSize, color: Colors.grey))
    ]);
  }

  Widget buildEventListItem(
      {required BuildContext context,
      required CalendarEvent event,
      required String dateInfo,
      required bool isGlobalSilent,
      required VoidCallback onToggleAlarm,
      required String Function(String) formatHHmm});
  Widget buildScaffoldLayout(
      {required BuildContext context,
      required bool isLoading,
      required PreferredSizeWidget appBar,
      required Widget calendarSection,
      required Widget sectionLabel,
      required Widget eventList,
      required Widget floatingActionButton,
      required DateTime displayDay,
      required String Function(DateTime) formatDateKorean});
}

class SamsungTheme extends CalendarTheme {
  @override
  AppTheme get type => AppTheme.samsung;
  @override
  String get name => '삼성 캘린더';
  @override
  String get emoji => '📱';
  @override
  Color get scaffoldBg => const Color(0xFFF2F2F2);
  @override
  Color get appBarBg => const Color(0xFFF2F2F2);
  @override
  Color get appBarText => const Color(0xFF222222);
  @override
  Color get calendarBg => Colors.white;
  @override
  Color get primaryAccent => const Color(0xFF2196F3);
  @override
  Color get secondaryAccent => const Color(0xFFBBDEF0);
  @override
  Color get cardBg => Colors.white;
  @override
  Color get cardBorder => Colors.transparent;
  @override
  Color get eventTitleText => const Color(0xFF222222);
  @override
  Color get eventSubText => const Color(0xFF666666);
  @override
  Color get iconBg => const Color(0xFFE3F2FD);
  @override
  Color get iconColor => const Color(0xFF2196F3);
  @override
  Color get sectionLabelText => const Color(0xFF444444);
  @override
  bool get showTextInside => true;
  @override
  Alignment get cellTextAlignment => Alignment.topLeft;

  @override
  Widget buildEventListItem(
      {required BuildContext context,
      required CalendarEvent event,
      required String dateInfo,
      required bool isGlobalSilent,
      required VoidCallback onToggleAlarm,
      required String Function(String) formatHHmm}) {
    final color =
        event.colorValue != null ? Color(event.colorValue!) : primaryAccent;
    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)
            ]),
        child: Row(children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
              child: buildTitleColumn(
                  event: event,
                  dateInfo: dateInfo,
                  isGlobalSilent: isGlobalSilent,
                  onToggleAlarm: onToggleAlarm))
        ]));
  }

  @override
  Widget buildScaffoldLayout(
      {required BuildContext context,
      required bool isLoading,
      required PreferredSizeWidget appBar,
      required Widget calendarSection,
      required Widget sectionLabel,
      required Widget eventList,
      required Widget floatingActionButton,
      required DateTime displayDay,
      required String Function(DateTime) formatDateKorean}) {
    return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: primaryAccent))
            : Column(children: [
                calendarSection,
                sectionLabel,
                Expanded(child: eventList)
              ]));
  }
}

class AppleTheme extends CalendarTheme {
  @override
  AppTheme get type => AppTheme.apple;
  @override
  String get name => '애플 캘린더';
  @override
  String get emoji => '🍎';
  @override
  Color get scaffoldBg => const Color(0xFFF8F9FF);
  @override
  Color get appBarBg => Colors.white;
  @override
  Color get appBarText => const Color(0xFF1A1A2E);
  @override
  Color get calendarBg => Colors.white;
  @override
  Color get primaryAccent => const Color(0xFFFA233B);
  @override
  Color get secondaryAccent => const Color(0xFFFFD1D6);
  @override
  Color get cardBg => Colors.white;
  @override
  Color get cardBorder => Colors.transparent;
  @override
  Color get eventTitleText => const Color(0xFF1A1A2E);
  @override
  Color get eventSubText => const Color(0xFF888888);
  @override
  Color get iconBg => const Color(0xFFFFF0F1);
  @override
  Color get iconColor => const Color(0xFFFA233B);
  @override
  Color get sectionLabelText => const Color(0xFF1A1A2E);

  @override
  Widget buildEventListItem(
      {required BuildContext context,
      required CalendarEvent event,
      required String dateInfo,
      required bool isGlobalSilent,
      required VoidCallback onToggleAlarm,
      required String Function(String) formatHHmm}) {
    final color =
        event.colorValue != null ? Color(event.colorValue!) : primaryAccent;
    return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)))),
        child: Row(children: [
          Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
              child: buildTitleColumn(
                  event: event,
                  dateInfo: dateInfo,
                  isGlobalSilent: isGlobalSilent,
                  onToggleAlarm: onToggleAlarm,
                  titleSize: 16))
        ]));
  }

  @override
  Widget buildScaffoldLayout(
      {required BuildContext context,
      required bool isLoading,
      required PreferredSizeWidget appBar,
      required Widget calendarSection,
      required Widget sectionLabel,
      required Widget eventList,
      required Widget floatingActionButton,
      required DateTime displayDay,
      required String Function(DateTime) formatDateKorean}) {
    return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: primaryAccent))
            : Column(children: [
                calendarSection,
                sectionLabel,
                Expanded(child: eventList)
              ]));
  }
}

class NaverTheme extends CalendarTheme {
  @override
  AppTheme get type => AppTheme.naver;
  @override
  String get name => '네이버 캘린더';
  @override
  String get emoji => '🇳';
  @override
  Color get scaffoldBg => Colors.white;
  @override
  Color get appBarBg => Colors.white;
  @override
  Color get appBarText => Colors.black;
  @override
  Color get calendarBg => Colors.white;
  @override
  Color get primaryAccent => const Color(0xFF03C75A);
  @override
  Color get secondaryAccent => const Color(0xFFD4F5E1);
  @override
  Color get cardBg => const Color(0xFFF9F9F9);
  @override
  Color get cardBorder => Colors.transparent;
  @override
  Color get eventTitleText => Colors.black87;
  @override
  Color get eventSubText => Colors.black54;
  @override
  Color get iconBg => const Color(0xFFE6F9ED);
  @override
  Color get iconColor => const Color(0xFF03C75A);
  @override
  Color get sectionLabelText => Colors.black;
  @override
  bool get showTextInside => true;

  @override
  Widget buildEventListItem(
      {required BuildContext context,
      required CalendarEvent event,
      required String dateInfo,
      required bool isGlobalSilent,
      required VoidCallback onToggleAlarm,
      required String Function(String) formatHHmm}) {
    final color =
        event.colorValue != null ? Color(event.colorValue!) : primaryAccent;
    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)
            ]),
        child: Row(children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 12),
          Expanded(
              child: buildTitleColumn(
                  event: event,
                  dateInfo: dateInfo,
                  isGlobalSilent: isGlobalSilent,
                  onToggleAlarm: onToggleAlarm))
        ]));
  }

  @override
  Widget buildScaffoldLayout(
      {required BuildContext context,
      required bool isLoading,
      required PreferredSizeWidget appBar,
      required Widget calendarSection,
      required Widget sectionLabel,
      required Widget eventList,
      required Widget floatingActionButton,
      required DateTime displayDay,
      required String Function(DateTime) formatDateKorean}) {
    return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: primaryAccent))
            : Column(children: [
                calendarSection,
                sectionLabel,
                Expanded(child: eventList)
              ]));
  }
}

class TodoSkyTheme extends CalendarTheme {
  @override
  AppTheme get type => AppTheme.todoSky;
  @override
  String get name => '투두 스카이';
  @override
  String get emoji => '✅';
  @override
  Color get scaffoldBg => Colors.white;
  @override
  Color get appBarBg => Colors.white;
  @override
  Color get appBarText => const Color(0xFF2D3142);
  @override
  Color get calendarBg => Colors.white;
  @override
  Color get primaryAccent => const Color(0xFFEF6C6C);
  @override
  Color get secondaryAccent => const Color(0xFFF5E6E6);
  @override
  Color get cardBg => const Color(0xFF3A3F5C);
  @override
  Color get cardBorder => const Color(0xFF4A5073);
  @override
  Color get eventTitleText => Colors.white;
  @override
  Color get eventSubText => const Color(0xFFADB5D0);
  @override
  Color get iconBg => const Color(0xFF4A5073);
  @override
  Color get iconColor => const Color(0xFFEF6C6C);
  @override
  Color get sectionLabelText => Colors.white;
  @override
  Color get bottomPanelBg => const Color(0xFF2D3142);
  @override
  bool get hasRoundedCard => true;
  @override
  Color get bottomSheetBg => const Color(0xFF3A3F5C);

  @override
  Widget buildScaffoldLayout(
      {required BuildContext context,
      required bool isLoading,
      required PreferredSizeWidget appBar,
      required Widget calendarSection,
      required Widget sectionLabel,
      required Widget eventList,
      required Widget floatingActionButton,
      required DateTime displayDay,
      required String Function(DateTime) formatDateKorean}) {
    final isToday = displayDay.year == DateTime.now().year &&
        displayDay.month == DateTime.now().month &&
        displayDay.day == DateTime.now().day;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryAccent))
          : Column(children: [
              calendarSection,
              Expanded(
                  child: Container(
                decoration: BoxDecoration(
                    color: bottomPanelBg,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                          child: Text(
                              isToday ? 'Today' : formatDateKorean(displayDay),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white))),
                      Expanded(child: eventList)
                    ]),
              ))
            ]),
    );
  }

  @override
  Widget buildEventListItem(
      {required BuildContext context,
      required CalendarEvent event,
      required String dateInfo,
      required bool isGlobalSilent,
      required VoidCallback onToggleAlarm,
      required String Function(String) formatHHmm}) {
    final color =
        event.colorValue != null ? Color(event.colorValue!) : primaryAccent;
    final effectiveAlarmOn = event.isAlarmOn && !isGlobalSilent;
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ]),
        child: Row(children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(Icons.event, color: color, size: 18)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Expanded(
                      child: Text(event.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white))),
                  if (event.alarmMinutes != AlarmMinutes.none)
                    GestureDetector(
                        onTap: onToggleAlarm,
                        child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                                effectiveAlarmOn
                                    ? Icons.notifications_active
                                    : Icons.notifications_paused,
                                size: 14,
                                color: effectiveAlarmOn
                                    ? primaryAccent
                                    : Colors.grey.withValues(alpha: 0.5))))
                ]),
                if (dateInfo.isNotEmpty) const SizedBox(height: 2),
                if (dateInfo.isNotEmpty)
                  Text(dateInfo,
                      style: TextStyle(fontSize: 12, color: eventSubText))
              ])),
          if (event.startTime != null)
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(formatHHmm(event.startTime!),
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)))
        ]));
  }
}

class DefaultCardTheme extends CalendarTheme {
  final AppTheme _type;
  final String _name, _emoji;
  final Color _scaffoldBg,
      _appBarBg,
      _appBarText,
      _calendarBg,
      _primaryAccent,
      _secondaryAccent,
      _cardBg,
      _cardBorder,
      _eventTitleText,
      _eventSubText,
      _iconBg,
      _iconColor,
      _sectionLabelText;
  final bool _isDark;
  final bool _hasRoundedCard;
  DefaultCardTheme(
      this._type,
      this._name,
      this._emoji,
      this._scaffoldBg,
      this._appBarBg,
      this._appBarText,
      this._calendarBg,
      this._primaryAccent,
      this._secondaryAccent,
      this._cardBg,
      this._cardBorder,
      this._eventTitleText,
      this._eventSubText,
      this._iconBg,
      this._iconColor,
      this._sectionLabelText,
      {bool isDark = false,
      bool hasRoundedCard = false})
      : _isDark = isDark,
        _hasRoundedCard = hasRoundedCard;
  @override
  AppTheme get type => _type;
  @override
  String get name => _name;
  @override
  String get emoji => _emoji;
  @override
  Color get scaffoldBg => _scaffoldBg;
  @override
  Color get appBarBg => _appBarBg;
  @override
  Color get appBarText => _appBarText;
  @override
  Color get calendarBg => _calendarBg;
  @override
  Color get primaryAccent => _primaryAccent;
  @override
  Color get secondaryAccent => _secondaryAccent;
  @override
  Color get cardBg => _cardBg;
  @override
  Color get cardBorder => _cardBorder;
  @override
  Color get eventTitleText => _eventTitleText;
  @override
  Color get eventSubText => _eventSubText;
  @override
  Color get iconBg => _iconBg;
  @override
  Color get iconColor => _iconColor;
  @override
  Color get sectionLabelText => _sectionLabelText;
  @override
  bool get isDark => _isDark;
  @override
  bool get hasRoundedCard => _hasRoundedCard;

  @override
  Widget buildEventListItem(
      {required BuildContext context,
      required CalendarEvent event,
      required String dateInfo,
      required bool isGlobalSilent,
      required VoidCallback onToggleAlarm,
      required String Function(String) formatHHmm}) {
    final color =
        event.colorValue != null ? Color(event.colorValue!) : primaryAccent;
    return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder)),
        child: Row(children: [
          Icon(Icons.check_circle_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
              child: buildTitleColumn(
                  event: event,
                  dateInfo: dateInfo,
                  isGlobalSilent: isGlobalSilent,
                  onToggleAlarm: onToggleAlarm,
                  dateSize: 11))
        ]));
  }

  @override
  Widget buildScaffoldLayout(
      {required BuildContext context,
      required bool isLoading,
      required PreferredSizeWidget appBar,
      required Widget calendarSection,
      required Widget sectionLabel,
      required Widget eventList,
      required Widget floatingActionButton,
      required DateTime displayDay,
      required String Function(DateTime) formatDateKorean}) {
    return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: primaryAccent))
            : Column(children: [
                calendarSection,
                sectionLabel,
                Expanded(child: eventList)
              ]));
  }
}

extension AppThemeExt on AppTheme {
  CalendarTheme get themeData {
    switch (this) {
      case AppTheme.samsung:
        return SamsungTheme();
      case AppTheme.apple:
        return AppleTheme();
      case AppTheme.naver:
        return NaverTheme();
      case AppTheme.todoSky:
        return TodoSkyTheme();
      case AppTheme.darkNeon:
        return DefaultCardTheme(
            AppTheme.darkNeon,
            '다크 네온',
            '🌙',
            const Color(0xFF1E1B2E),
            const Color(0xFF1E1B2E),
            Colors.white,
            const Color(0xFF2A2640),
            const Color(0xFF9C6FE4),
            const Color(0xFF00D4FF),
            const Color(0xFF2A2640),
            const Color(0xFF3D3760),
            Colors.white,
            const Color(0xFF9E9BB8),
            const Color(0xFF3D3760),
            const Color(0xFF9C6FE4),
            Colors.white,
            isDark: true,
            hasRoundedCard: true);
      case AppTheme.classicBlue:
        return DefaultCardTheme(
            AppTheme.classicBlue,
            '클래식 블루',
            '☁️',
            const Color(0xFFF8F9FF),
            Colors.white,
            const Color(0xFF1A1A2E),
            Colors.white,
            const Color(0xFF4A90D9),
            const Color(0xFFDDEEFF),
            Colors.white,
            const Color(0xFFEEEEEE),
            const Color(0xFF1A1A2E),
            const Color(0xFF888888),
            const Color(0xFFEEF4FF),
            const Color(0xFF4A90D9),
            const Color(0xFF1A1A2E));
    }
  }
}
