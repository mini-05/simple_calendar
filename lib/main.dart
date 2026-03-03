// v4.4.1
// claude_main.dart
// lib/main.dart
// 앱의 진입점 (Entry Point)
// [v4.4.1] SplashScreen 연결
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/providers.dart';
import 'services/services.dart';
import 'ui/splash_screen.dart'; // [v4.4.1] SplashScreen 연결 (CalendarScreen은 splash에서 라우팅)
import 'theme/app_theme.dart';

/* // =================================================================
// [Gemini 백업: Windows/Web 데스크톱 DB 초기화 로직]
// 만약 Claude 코드 사용 중 DB를 SQLite로 교체하게 된다면 위 import와
// 아래 코드를 runApp() 실행 전에 주석 해제하여 사용하세요.
// =================================================================
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  await NotificationService.initMinimal();

  runApp(const ProviderScope(child: MyCalendarApp()));
}

class MyCalendarApp extends ConsumerWidget {
  const MyCalendarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final th = settings.currentTheme.themeData;

    return MaterialApp(
      title: 'My Calendar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: th.scaffoldBg,
        primaryColor: th.primaryAccent,
        brightness: th.isDark ? Brightness.dark : Brightness.light,
      ),
      home: const SplashScreen(), // [v4.4.1] 스플래시 → CalendarScreen 자동 전환
    );
  }
}
