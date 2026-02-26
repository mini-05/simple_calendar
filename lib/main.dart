// main.dart
// 앱의 진입점 (Entry Point)
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/services.dart';
import 'ui/calendar_screen.dart';

/* // =====================================================================
// [Gemini 백업: Windows/Web 데스크톱 DB 초기화 로직]
// 만약 Claude 코드 사용 중 DB를 SQLite로 교체하게 된다면 위 import와 
// 아래 코드를 runApp() 실행 전에 주석 해제하여 사용하세요.
// =====================================================================
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

// (main 함수 내부)
// if (kIsWeb) {
//   databaseFactory = databaseFactoryFfiWeb;
// } else if (Platform.isWindows || Platform.isLinux) {
//   sqfliteFfiInit();
//   databaseFactory = databaseFactoryFfi;
// }
*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 알림 서비스 초기화 (시간대 설정 포함)
  await NotificationService.init();
  runApp(
    // Riverpod 전역 상태 컨테이너
    const ProviderScope(
      child: MyCalendarApp(),
    ),
  );
}

class MyCalendarApp extends StatelessWidget {
  const MyCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Calendar',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      // 한국어 로케일 (날짜 형식, 달력 헤더 등)
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
