// v3.5.0
// =============================================================
// [v3.5.0 변경 사항 요약]
// 1. 구조적 혁신: 단일 파일 구조를 models, services, theme, ui로 분리하여 유지보수성 극대화.
// 2. 다형성(Polymorphism) 도입: 테마별 그리기 로직을 클래스화하여 if/switch 분기 제거 및 연산 효율 향상.
// 3. 렌더링 최적화: Viewport(슬라이딩 윈도우) 로직을 적용하여 현재 달 기준 앞뒤 12개월치만 인덱싱.
// 4. 검색 기능 고도화: 한국어 특화 초성 검색 및 띄어쓰기 무시 알고리즘 적용.
// 5. 백업/복구 확장: 범용 ICS 규격 지원으로 구글/애플 캘린더와 데이터 호환 가능.
// 6. UI/UX 개선: 위/아래 수직 스와이프 지원, 일요일 시작 버그 수정, 테마 연동 '오늘' 버튼 색상.
// 7. 안정성 강화: defaultEventColor 등 전역 상수를 모델 계층으로 이동하여 순환 참조 및 타입 오류 해결.
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
