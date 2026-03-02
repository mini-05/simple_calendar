// v4.4.0
// gemini_services.dart
// lib/services/services.dart
// [v4.4.0] 조건부 임포트를 통한 웹(Web) 크래시 방지 적용

export 'storage_service.dart';
export 'notification_service.dart';

// 🔥 마법의 스위치: IO(모바일) 환경에서만 진짜 파일을 부르고, 웹에선 껍데기(Stub)를 부릅니다.
export 'ics_service_stub.dart' if (dart.library.io) 'ics_service_io.dart';

export 'date_formatter.dart';
export 'holidays.dart';
export 'slot_calculator.dart';
export 'home_widget_service.dart';
