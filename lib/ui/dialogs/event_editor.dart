// v4.4.0
// gemini_event_editor.dart
// lib/ui/dialogs/event_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../services/services.dart'; // 💡 date_formatter 개별 임포트 삭제됨!

Future<void> showEventEditor({
  required BuildContext context,
  required CalendarTheme th,
  required AppSettings settings,
  required int currentEventCount,
  CalendarEvent? existingEvent,
  DateTime? selectedDay,
  required Future<void> Function(CalendarEvent) onSave,
}) async {
  final isEdit = existingEvent != null;

  // ── 상태 노티파이어 초기값 ────────────────────────────────────
  final titleCtrl =
      TextEditingController(text: isEdit ? existingEvent.title : '');
  final startDateN = ValueNotifier<DateTime>(
      isEdit ? existingEvent.startDt : (selectedDay ?? DateTime.now()));
  final endDateN =
      ValueNotifier<DateTime>(isEdit ? existingEvent.endDt : startDateN.value);
  final isAllDayN =
      ValueNotifier<bool>(isEdit ? existingEvent.isAllDay : false);

  DateTime t0 = DateTime.now(),
      t1 = DateTime.now().add(const Duration(hours: 1));
  if (isEdit &&
      existingEvent.startTime != null &&
      existingEvent.endTime != null) {
    final sp = existingEvent.startTime!.split(':'),
        ep = existingEvent.endTime!.split(':');
    t0 = DateTime(2000, 1, 1, int.parse(sp[0]), int.parse(sp[1]));
    t1 = DateTime(2000, 1, 1, int.parse(ep[0]), int.parse(ep[1]));
  }
  final startTimeN = ValueNotifier<DateTime>(t0);
  final endTimeN = ValueNotifier<DateTime>(t1);
  final colorN =
      ValueNotifier<int>(existingEvent?.colorValue ?? defaultEventColor);
  final alarmN = ValueNotifier<AlarmMinutes>(
      isEdit ? existingEvent.alarmMinutes : AlarmMinutes.none);
  final hasRecN = ValueNotifier<bool>(
      isEdit ? existingEvent.recurrenceRule != null : false);
  final recFreqN = ValueNotifier<RecurrenceFrequency>(
      isEdit && existingEvent.recurrenceRule != null
          ? existingEvent.recurrenceRule!.frequency
          : RecurrenceFrequency.weekly);
  final recUntilN = ValueNotifier<DateTime?>(
      isEdit && existingEvent.recurrenceRule != null
          ? existingEvent.recurrenceRule!.until
          : null);

  void correct() {
    final s = DateTime(startDateN.value.year, startDateN.value.month,
        startDateN.value.day, startTimeN.value.hour, startTimeN.value.minute);
    final e = DateTime(endDateN.value.year, endDateN.value.month,
        endDateN.value.day, endTimeN.value.hour, endTimeN.value.minute);
    if (e.isBefore(s)) {
      if (isAllDayN.value) {
        endDateN.value = startDateN.value;
      } else {
        final ne = s.add(const Duration(hours: 1));
        endDateN.value = ne;
        endTimeN.value = DateTime(2000, 1, 1, ne.hour, ne.minute);
      }
    }
  }

  await showDialog(
    context: context,
    builder: (dlgCtx) => AlertDialog(
      backgroundColor: th.isDark ? const Color(0xFF2A2640) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(isEdit ? '✏️ 일정 수정' : '✨ 새 일정 추가',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: th.isDark ? Colors.white : Colors.black)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── 제목 ──
          _TitleField(ctrl: titleCtrl, th: th),
          const SizedBox(height: 16),
          // ── 날짜·시간 ──
          _DateTimeSection(
            th: th,
            isAllDayN: isAllDayN,
            startDateN: startDateN,
            startTimeN: startTimeN,
            endDateN: endDateN,
            endTimeN: endTimeN,
            parentCtx: dlgCtx,
            onChanged: correct,
          ),
          const SizedBox(height: 12),
          // ── 반복 ──
          _RecurrenceSection(
              th: th,
              hasRecN: hasRecN,
              freqN: recFreqN,
              untilN: recUntilN,
              parentCtx: dlgCtx),
          const SizedBox(height: 12),
          // ── 알림 ──
          _AlarmSection(th: th, alarmN: alarmN),
          const SizedBox(height: 18),
          // ── 색상 ──
          _ColorPicker(th: th, colorN: colorN),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (dlgCtx.mounted) Navigator.pop(dlgCtx);
          },
          child: Text('취소',
              style:
                  TextStyle(color: th.isDark ? Colors.white54 : Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: th.primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          onPressed: () async {
            if (titleCtrl.text.trim().isEmpty) {
              _alert(dlgCtx, '일정을 입력해 주세요.');
              return;
            }
            if (!isEdit && currentEventCount >= 500) {
              _alert(dlgCtx, '일정은 최대 500개까지 등록할 수 있습니다.');
              return;
            }
            final sD = startDateN.value, eD = endDateN.value;
            final isAllDay = isAllDayN.value;
            if (!isAllDay) {
              final sf = DateTime(sD.year, sD.month, sD.day,
                  startTimeN.value.hour, startTimeN.value.minute);
              final ef = DateTime(eD.year, eD.month, eD.day,
                  endTimeN.value.hour, endTimeN.value.minute);
              if (ef.isBefore(sf)) {
                _alert(dlgCtx, '시작/종료 일시를 확인해 주세요.');
                return;
              }
            }

            String? sT, eT;
            if (!isAllDay) {
              sT = _hhmm(startTimeN.value);
              eT = _hhmm(endTimeN.value);
            }
            RecurrenceRule? rrule;
            if (hasRecN.value) {
              rrule = RecurrenceRule(
                  frequency: recFreqN.value, until: recUntilN.value);
            }

            final event = CalendarEvent(
              id: isEdit ? existingEvent.id : EventStorage.generateId(),
              title: titleCtrl.text.trim(),
              date: DateFormatter.dateKey(sD),
              endDate: DateFormatter.dateKey(eD),
              colorValue: colorN.value,
              isAllDay: isAllDay,
              startTime: sT, endTime: eT,
              alarmMinutes: alarmN.value,
              isAlarmOn: isEdit ? existingEvent.isAlarmOn : true,
              // 💡 알람 세부 모드 및 사운드, 진동 설정 저장
              eventAlarmMode: isEdit
                  ? existingEvent.eventAlarmMode
                  : settings.effectiveMode,
              soundOption:
                  isEdit ? existingEvent.soundOption : settings.soundOption,
              vibrationPattern: isEdit
                  ? existingEvent.vibrationPattern
                  : settings.vibrationPattern,
              customSoundPath: isEdit
                  ? existingEvent.customSoundPath
                  : settings.customSoundPath,
              recurrenceRule: rrule,
            );
            await onSave(event);
            if (dlgCtx.mounted) Navigator.pop(dlgCtx);
          },
          child: const Text('저장'),
        ),
      ],
    ),
  );

  for (final d in [
    titleCtrl,
    startDateN,
    endDateN,
    isAllDayN,
    startTimeN,
    endTimeN,
    colorN,
    alarmN,
    hasRecN,
    recFreqN,
    recUntilN
  ]) {
    d.dispose();
  }
}

// ── 헬퍼 ─────────────────────────────────────────────────────────

String _hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

void _alert(BuildContext ctx, String msg) => showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Text('⚠️ 알림', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () {
                if (c.mounted) Navigator.pop(c);
              },
              child: const Text('확인'))
        ],
      ),
    );

class _TitleField extends StatelessWidget {
  final TextEditingController ctrl;
  final CalendarTheme th;
  const _TitleField({required this.ctrl, required this.th});

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        autofocus: true,
        maxLength: 100,
        style: TextStyle(color: th.isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: '일정을 입력하세요',
          hintStyle: TextStyle(color: th.isDark ? Colors.white38 : Colors.grey),
          filled: true,
          fillColor: th.isDark ? const Color(0xFF3D3760) : Colors.grey[100],
          counterStyle: TextStyle(
              color: th.isDark ? Colors.white38 : Colors.grey, fontSize: 11),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      );
}

class _DateTimeSection extends StatelessWidget {
  final CalendarTheme th;
  final ValueNotifier<bool> isAllDayN;
  final ValueNotifier<DateTime> startDateN, startTimeN, endDateN, endTimeN;
  final BuildContext parentCtx;
  final VoidCallback onChanged;

  const _DateTimeSection({
    required this.th,
    required this.isAllDayN,
    required this.startDateN,
    required this.startTimeN,
    required this.endDateN,
    required this.endTimeN,
    required this.parentCtx,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: th.isDark ? const Color(0xFF3D3760) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12)),
        child: ValueListenableBuilder<bool>(
          valueListenable: isAllDayN,
          builder: (_, isAllDay, __) => Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('하루 종일',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: th.isDark ? Colors.white : Colors.black87)),
                    CupertinoSwitch(
                        activeTrackColor: th.primaryAccent,
                        value: isAllDay,
                        onChanged: (v) => isAllDayN.value = v),
                  ]),
            ),
            _div(),
            _pickerRow('시작 날짜', startDateN, true),
            if (!isAllDay) _pickerRow('시작 시간', startTimeN, false),
            _div(),
            _pickerRow('종료 날짜', endDateN, true),
            if (!isAllDay) _pickerRow('종료 시간', endTimeN, false),
          ]),
        ),
      );

  Divider _div() =>
      Divider(height: 1, color: th.isDark ? Colors.white12 : Colors.grey[300]);

  Widget _pickerRow(String label, ValueNotifier<DateTime> n, bool isDate) =>
      ValueListenableBuilder<DateTime>(
        valueListenable: n,
        builder: (_, val, __) {
          final display = isDate
              ? DateFormatter.formatDateKorean(val)
              : DateFormatter.formatHHmm(
                  '${val.hour.toString().padLeft(2, '0')}:${val.minute.toString().padLeft(2, '0')}');
          return InkWell(
            onTap: () async {
              DateTime temp = val;
              await showModalBottomSheet<void>(
                context: parentCtx,
                builder: (bsCtx) => Container(
                  color: th.isDark ? const Color(0xFF2A2640) : Colors.white,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isDate ? '날짜 선택' : '시간 선택',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: th.isDark
                                        ? Colors.white
                                        : Colors.black87)),
                            TextButton(
                              onPressed: () {
                                n.value = temp;
                                onChanged();
                                Navigator.pop(bsCtx);
                              },
                              child: Text('완료',
                                  style: TextStyle(
                                      color: th.primaryAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                          ]),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 220,
                      child: CupertinoTheme(
                        data: CupertinoThemeData(
                            textTheme: CupertinoTextThemeData(
                                dateTimePickerTextStyle: TextStyle(
                                    color:
                                        th.isDark ? Colors.white : Colors.black,
                                    fontSize: 22))),
                        child: CupertinoDatePicker(
                          mode: isDate
                              ? CupertinoDatePickerMode.date
                              : CupertinoDatePickerMode.time,
                          initialDateTime: val,
                          onDateTimeChanged: (v) => temp = v,
                        ),
                      ),
                    ),
                  ]),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: th.isDark ? Colors.white70 : Colors.black87,
                            fontSize: 15)),
                    Text(display,
                        style: TextStyle(
                            color: th.primaryAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ]),
            ),
          );
        },
      );
}

class _RecurrenceSection extends StatelessWidget {
  final CalendarTheme th;
  final ValueNotifier<bool> hasRecN;
  final ValueNotifier<RecurrenceFrequency> freqN;
  final ValueNotifier<DateTime?> untilN;
  final BuildContext parentCtx;

  const _RecurrenceSection({
    required this.th,
    required this.hasRecN,
    required this.freqN,
    required this.untilN,
    required this.parentCtx,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: th.isDark ? const Color(0xFF3D3760) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          ValueListenableBuilder<bool>(
            valueListenable: hasRecN,
            builder: (_, hasRec, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(children: [
                Icon(Icons.repeat,
                    color: hasRec
                        ? th.primaryAccent
                        : (th.isDark ? Colors.white38 : Colors.grey),
                    size: 20),
                const SizedBox(width: 10),
                Text('반복 일정',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: th.isDark ? Colors.white : Colors.black87)),
                const Spacer(),
                CupertinoSwitch(
                    activeTrackColor: th.primaryAccent,
                    value: hasRec,
                    onChanged: (v) => hasRecN.value = v),
              ]),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: hasRecN,
            builder: (_, hasRec, __) {
              if (!hasRec) return const SizedBox.shrink();
              return Column(children: [
                Divider(
                    height: 1,
                    color: th.isDark ? Colors.white12 : Colors.grey[300]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('반복 주기',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: th.isDark
                                    ? Colors.white54
                                    : Colors.black54)),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<RecurrenceFrequency>(
                          valueListenable: freqN,
                          builder: (_, freq, __) => Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: RecurrenceFrequency.values.map((f) {
                              final isSel = freq == f;
                              return GestureDetector(
                                onTap: () => freqN.value = f,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                      color: isSel
                                          ? th.primaryAccent
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: isSel
                                              ? th.primaryAccent
                                              : (th.isDark
                                                  ? Colors.white24
                                                  : Colors.grey.shade400))),
                                  child: Text(f.label,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSel
                                              ? Colors.white
                                              : (th.isDark
                                                  ? Colors.white70
                                                  : Colors.black87))),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Text('종료일',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: th.isDark
                                      ? Colors.white54
                                      : Colors.black54)),
                          const Spacer(),
                          ValueListenableBuilder<DateTime?>(
                            valueListenable: untilN,
                            builder: (_, until, __) => GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                    context: parentCtx,
                                    initialDate: until ??
                                        DateTime.now()
                                            .add(const Duration(days: 365)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2035));
                                if (picked != null) untilN.value = picked;
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: until != null
                                        ? th.primaryAccent
                                            .withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: th.primaryAccent)),
                                child: Text(
                                    until != null
                                        ? '${until.year}.${until.month.toString().padLeft(2, '0')}.${until.day.toString().padLeft(2, '0')}'
                                        : '무한 반복',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: th.primaryAccent,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                        ]),
                      ]),
                ),
              ]);
            },
          ),
        ]),
      );
}

class _AlarmSection extends StatelessWidget {
  final CalendarTheme th;
  final ValueNotifier<AlarmMinutes> alarmN;
  const _AlarmSection({required this.th, required this.alarmN});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: th.isDark ? const Color(0xFF3D3760) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Icon(Icons.notifications_outlined,
                  color: th.primaryAccent, size: 18),
              const SizedBox(width: 8),
              Text('알림 시간',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: th.isDark ? Colors.white : Colors.black87))
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ValueListenableBuilder<AlarmMinutes>(
              valueListenable: alarmN,
              builder: (_, alarm, __) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AlarmMinutes.values.map((opt) {
                  final isSel = alarm == opt;
                  return GestureDetector(
                    onTap: () => alarmN.value = opt,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: isSel
                              ? th.primaryAccent
                              : (th.isDark
                                  ? const Color(0xFF2A2640)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSel
                                  ? th.primaryAccent
                                  : (th.isDark
                                      ? Colors.white24
                                      : Colors.grey.shade300))),
                      child: Text(opt.label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSel
                                  ? Colors.white
                                  : (th.isDark
                                      ? Colors.white70
                                      : Colors.black87))),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ]),
      );
}

class _ColorPicker extends StatelessWidget {
  final CalendarTheme th;
  final ValueNotifier<int> colorN;
  static const _options = [
    defaultEventColor,
    0xFFE57373,
    0xFF81C784,
    0xFFFFB74D,
    0xFFBA68C8
  ];
  const _ColorPicker({required this.th, required this.colorN});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: colorN,
        builder: (_, sel, __) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _options.map((v) {
            final isSel = sel == v;
            return GestureDetector(
              onTap: () => colorN.value = v,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: Color(v),
                    shape: BoxShape.circle,
                    border: isSel
                        ? Border.all(
                            color: th.isDark ? Colors.white : Colors.black54,
                            width: 3)
                        : null),
                child: isSel
                    ? const Icon(Icons.check, size: 22, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      );
}
