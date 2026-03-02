// v4.4.0
// gemini_ics_service_stub.dart
// lib/services/ics_service_stub.dart
// [조건부 임포트] 웹(Web) 환경이거나 컴파일 시점에 바라보는 껍데기 파일

import '../models/models.dart';
import 'storage_service.dart';

class IcsService {
  static Future<void> exportToIcs(List<CalendarEvent> events) async {
    appLog('[ICS] 웹 환경에서는 로컬 ics 내보내기를 지원하지 않습니다.');
  }

  static Future<bool> importFromIcs() async {
    appLog('[ICS] 웹 환경에서는 로컬 ics 불러오기를 지원하지 않습니다.');
    return false;
  }
}
