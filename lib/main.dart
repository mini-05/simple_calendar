// v3.6.2
// =============================================================
// [v3.6.2 변경 사항 요약]
// 1. 구조적 혁신: models, services, theme, logic, ui 폴더로 완전 분리.
// 2. OCP 완벽 준수: 테마 렌더링 및 공휴일 시스템(전략 패턴)에 다형성 전면 적용.
// 3. 기획 의도 최적화: 일요일 한정 음력 표기('음5.20'), 설날/추석 연속 블록 렌더링 최적화.
// 4. 기능 고도화: 수직/수평 스와이프 모드, 초성 검색, ICS 규격 백업/복구 지원.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/services.dart';
import 'ui/calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MyCalendarApp());
}

class MyCalendarApp extends StatelessWidget {
  const MyCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Calendar',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      locale: const Locale('ko', 'KR'),
      home: const CalendarScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
