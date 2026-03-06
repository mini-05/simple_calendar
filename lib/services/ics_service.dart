// v4.4.2
// ics_service.dart
// lib/services/ics_service.dart
// [v4.4.2] share_plus ^12.x API 교체: Share.shareXFiles → SharePlus.instance.share

import 'dart:io' show File;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import 'storage_service.dart';

class IcsService {
  static String _escapeIcsText(String text) => text
      .replaceAll('\\', '\\\\')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '');

  static Future<void> exportToIcs(List<CalendarEvent> events) async {
    if (kIsWeb) {
      appLog('[ICS] 웹 환경에서는 아직 ICS 내보내기를 지원하지 않습니다.');
      return;
    }

    try {
      final buf = StringBuffer();
      buf.writeln('BEGIN:VCALENDAR');
      buf.writeln('VERSION:2.0');
      buf.writeln('PRODID:-//My Calendar App//v4.4.2//EN');

      String formatDt(DateTime d) =>
          '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

      for (final e in events.where(
        (e) => !e.isHoliday && !e.isRecurrenceInstance,
      )) {
        buf.writeln('BEGIN:VEVENT');
        buf.writeln('UID:${e.id}@mycalendar.app');
        buf.writeln('SUMMARY:${_escapeIcsText(e.title)}');
        if (e.isAllDay) {
          buf.writeln('DTSTART;VALUE=DATE:${formatDt(e.startDt)}');
          buf.writeln(
            'DTEND;VALUE=DATE:${formatDt(e.endDt.add(const Duration(days: 1)))}',
          );
        } else {
          final sT = (e.startTime ?? '00:00').replaceAll(':', '');
          final eT = (e.endTime ?? '00:00').replaceAll(':', '');
          buf.writeln('DTSTART:${formatDt(e.startDt)}T${sT}00');
          buf.writeln('DTEND:${formatDt(e.endDt)}T${eT}00');
        }
        if (e.recurrenceRule != null) {
          final r = e.recurrenceRule!;
          final freq = r.frequency.name.toUpperCase();
          var rrule = 'RRULE:FREQ=$freq;INTERVAL=${r.interval}';
          if (r.until != null) rrule += ';UNTIL=${formatDt(r.until!)}';
          buf.writeln(rrule);
        }
        buf.writeln('END:VEVENT');
      }
      buf.writeln('END:VCALENDAR');

      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final fileName = 'My_Calendar(backup)_$timestamp.ics';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buf.toString());

      // [v4.4.2] share_plus ^12.x API 교체
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: '내 캘린더 ics 백업 파일입니다.'),
      );
    } catch (e) {
      appLog('ICS 내보내기 실패: $e');
    }
  }

  static Future<bool> importFromIcs() async {
    if (kIsWeb) {
      appLog('[ICS] 웹 환경에서는 아직 ICS 불러오기를 지원하지 않습니다.');
      return false;
    }

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) return false;

      final content = await File(result.files.single.path!).readAsString();
      final imported = <CalendarEvent>[];
      final lines = const LineSplitter().convert(content);
      bool inEvent = false;
      String? summary, dtStart, dtEnd;

      for (final line in lines) {
        if (line.startsWith('BEGIN:VEVENT')) {
          inEvent = true;
          summary = dtStart = dtEnd = null;
        } else if (line.startsWith('END:VEVENT')) {
          if (inEvent && summary != null && dtStart != null) {
            final sD = _parseDate(dtStart);
            final eD = dtEnd != null ? _parseDate(dtEnd) : sD;
            final sT = _parseTime(dtStart);
            final eT = dtEnd != null ? _parseTime(dtEnd) : sT;
            if (sD != null) {
              imported.add(
                CalendarEvent(
                  id: EventStorage.generateId(),
                  title: summary,
                  date: _fmtDateStr(sD),
                  endDate: eD != null ? _fmtDateStr(eD) : null,
                  isAllDay: sT == null,
                  startTime: sT,
                  endTime: eT,
                ),
              );
            }
          }
          inEvent = false;
        } else if (inEvent) {
          if (line.startsWith('SUMMARY:')) {
            summary = line.substring(8);
          } else if (line.startsWith('DTSTART')) {
            dtStart = line.substring(line.indexOf(':') + 1);
          } else if (line.startsWith('DTEND')) {
            dtEnd = line.substring(line.indexOf(':') + 1);
          }
        }
      }

      if (imported.isNotEmpty) {
        final existing = await EventStorage.loadAll();
        existing.addAll(imported);
        await EventStorage.saveAll(existing);
        return true;
      }
      return false;
    } catch (e) {
      appLog('[ICS] import 실패: $e');
      return false;
    }
  }

  static String _fmtDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parseDate(String v) {
    v = v.replaceAll('\r', '').replaceAll('Z', '');
    if (v.length >= 8) {
      return DateTime.tryParse(
        '${v.substring(0, 4)}-${v.substring(4, 6)}-${v.substring(6, 8)}',
      );
    }
    return null;
  }

  static String? _parseTime(String v) {
    if (v.contains('T') && v.length >= 15) {
      final t = v.indexOf('T');
      return '${v.substring(t + 1, t + 3)}:${v.substring(t + 3, t + 5)}';
    }
    return null;
  }
}
