// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CalendarEvent implements DiagnosticableTreeMixin {

 int get id; String get title; String get date; String? get endDate; String? get startTime; String? get endTime; int? get colorValue; bool get isAllDay; bool get isAlarmOn; AlarmMinutes get alarmMinutes; AlarmMode get eventAlarmMode; NotificationSound get soundOption; VibrationPattern get vibrationPattern; String? get customSoundPath; RecurrenceRule? get recurrenceRule; int? get parentId; bool get isRecurrenceInstance;
/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarEventCopyWith<CalendarEvent> get copyWith => _$CalendarEventCopyWithImpl<CalendarEvent>(this as CalendarEvent, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'CalendarEvent'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('date', date))..add(DiagnosticsProperty('endDate', endDate))..add(DiagnosticsProperty('startTime', startTime))..add(DiagnosticsProperty('endTime', endTime))..add(DiagnosticsProperty('colorValue', colorValue))..add(DiagnosticsProperty('isAllDay', isAllDay))..add(DiagnosticsProperty('isAlarmOn', isAlarmOn))..add(DiagnosticsProperty('alarmMinutes', alarmMinutes))..add(DiagnosticsProperty('eventAlarmMode', eventAlarmMode))..add(DiagnosticsProperty('soundOption', soundOption))..add(DiagnosticsProperty('vibrationPattern', vibrationPattern))..add(DiagnosticsProperty('customSoundPath', customSoundPath))..add(DiagnosticsProperty('recurrenceRule', recurrenceRule))..add(DiagnosticsProperty('parentId', parentId))..add(DiagnosticsProperty('isRecurrenceInstance', isRecurrenceInstance));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.date, date) || other.date == date)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&(identical(other.isAllDay, isAllDay) || other.isAllDay == isAllDay)&&(identical(other.isAlarmOn, isAlarmOn) || other.isAlarmOn == isAlarmOn)&&(identical(other.alarmMinutes, alarmMinutes) || other.alarmMinutes == alarmMinutes)&&(identical(other.eventAlarmMode, eventAlarmMode) || other.eventAlarmMode == eventAlarmMode)&&(identical(other.soundOption, soundOption) || other.soundOption == soundOption)&&(identical(other.vibrationPattern, vibrationPattern) || other.vibrationPattern == vibrationPattern)&&(identical(other.customSoundPath, customSoundPath) || other.customSoundPath == customSoundPath)&&(identical(other.recurrenceRule, recurrenceRule) || other.recurrenceRule == recurrenceRule)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.isRecurrenceInstance, isRecurrenceInstance) || other.isRecurrenceInstance == isRecurrenceInstance));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,date,endDate,startTime,endTime,colorValue,isAllDay,isAlarmOn,alarmMinutes,eventAlarmMode,soundOption,vibrationPattern,customSoundPath,recurrenceRule,parentId,isRecurrenceInstance);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'CalendarEvent(id: $id, title: $title, date: $date, endDate: $endDate, startTime: $startTime, endTime: $endTime, colorValue: $colorValue, isAllDay: $isAllDay, isAlarmOn: $isAlarmOn, alarmMinutes: $alarmMinutes, eventAlarmMode: $eventAlarmMode, soundOption: $soundOption, vibrationPattern: $vibrationPattern, customSoundPath: $customSoundPath, recurrenceRule: $recurrenceRule, parentId: $parentId, isRecurrenceInstance: $isRecurrenceInstance)';
}


}

/// @nodoc
abstract mixin class $CalendarEventCopyWith<$Res>  {
  factory $CalendarEventCopyWith(CalendarEvent value, $Res Function(CalendarEvent) _then) = _$CalendarEventCopyWithImpl;
@useResult
$Res call({
 int id, String title, String date, String? endDate, String? startTime, String? endTime, int? colorValue, bool isAllDay, bool isAlarmOn, AlarmMinutes alarmMinutes, AlarmMode eventAlarmMode, NotificationSound soundOption, VibrationPattern vibrationPattern, String? customSoundPath, RecurrenceRule? recurrenceRule, int? parentId, bool isRecurrenceInstance
});




}
/// @nodoc
class _$CalendarEventCopyWithImpl<$Res>
    implements $CalendarEventCopyWith<$Res> {
  _$CalendarEventCopyWithImpl(this._self, this._then);

  final CalendarEvent _self;
  final $Res Function(CalendarEvent) _then;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? date = null,Object? endDate = freezed,Object? startTime = freezed,Object? endTime = freezed,Object? colorValue = freezed,Object? isAllDay = null,Object? isAlarmOn = null,Object? alarmMinutes = null,Object? eventAlarmMode = null,Object? soundOption = null,Object? vibrationPattern = null,Object? customSoundPath = freezed,Object? recurrenceRule = freezed,Object? parentId = freezed,Object? isRecurrenceInstance = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,colorValue: freezed == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int?,isAllDay: null == isAllDay ? _self.isAllDay : isAllDay // ignore: cast_nullable_to_non_nullable
as bool,isAlarmOn: null == isAlarmOn ? _self.isAlarmOn : isAlarmOn // ignore: cast_nullable_to_non_nullable
as bool,alarmMinutes: null == alarmMinutes ? _self.alarmMinutes : alarmMinutes // ignore: cast_nullable_to_non_nullable
as AlarmMinutes,eventAlarmMode: null == eventAlarmMode ? _self.eventAlarmMode : eventAlarmMode // ignore: cast_nullable_to_non_nullable
as AlarmMode,soundOption: null == soundOption ? _self.soundOption : soundOption // ignore: cast_nullable_to_non_nullable
as NotificationSound,vibrationPattern: null == vibrationPattern ? _self.vibrationPattern : vibrationPattern // ignore: cast_nullable_to_non_nullable
as VibrationPattern,customSoundPath: freezed == customSoundPath ? _self.customSoundPath : customSoundPath // ignore: cast_nullable_to_non_nullable
as String?,recurrenceRule: freezed == recurrenceRule ? _self.recurrenceRule : recurrenceRule // ignore: cast_nullable_to_non_nullable
as RecurrenceRule?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,isRecurrenceInstance: null == isRecurrenceInstance ? _self.isRecurrenceInstance : isRecurrenceInstance // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarEvent].
extension CalendarEventPatterns on CalendarEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarEvent value)  $default,){
final _that = this;
switch (_that) {
case _CalendarEvent():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarEvent value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String date,  String? endDate,  String? startTime,  String? endTime,  int? colorValue,  bool isAllDay,  bool isAlarmOn,  AlarmMinutes alarmMinutes,  AlarmMode eventAlarmMode,  NotificationSound soundOption,  VibrationPattern vibrationPattern,  String? customSoundPath,  RecurrenceRule? recurrenceRule,  int? parentId,  bool isRecurrenceInstance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that.id,_that.title,_that.date,_that.endDate,_that.startTime,_that.endTime,_that.colorValue,_that.isAllDay,_that.isAlarmOn,_that.alarmMinutes,_that.eventAlarmMode,_that.soundOption,_that.vibrationPattern,_that.customSoundPath,_that.recurrenceRule,_that.parentId,_that.isRecurrenceInstance);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String date,  String? endDate,  String? startTime,  String? endTime,  int? colorValue,  bool isAllDay,  bool isAlarmOn,  AlarmMinutes alarmMinutes,  AlarmMode eventAlarmMode,  NotificationSound soundOption,  VibrationPattern vibrationPattern,  String? customSoundPath,  RecurrenceRule? recurrenceRule,  int? parentId,  bool isRecurrenceInstance)  $default,) {final _that = this;
switch (_that) {
case _CalendarEvent():
return $default(_that.id,_that.title,_that.date,_that.endDate,_that.startTime,_that.endTime,_that.colorValue,_that.isAllDay,_that.isAlarmOn,_that.alarmMinutes,_that.eventAlarmMode,_that.soundOption,_that.vibrationPattern,_that.customSoundPath,_that.recurrenceRule,_that.parentId,_that.isRecurrenceInstance);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String date,  String? endDate,  String? startTime,  String? endTime,  int? colorValue,  bool isAllDay,  bool isAlarmOn,  AlarmMinutes alarmMinutes,  AlarmMode eventAlarmMode,  NotificationSound soundOption,  VibrationPattern vibrationPattern,  String? customSoundPath,  RecurrenceRule? recurrenceRule,  int? parentId,  bool isRecurrenceInstance)?  $default,) {final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that.id,_that.title,_that.date,_that.endDate,_that.startTime,_that.endTime,_that.colorValue,_that.isAllDay,_that.isAlarmOn,_that.alarmMinutes,_that.eventAlarmMode,_that.soundOption,_that.vibrationPattern,_that.customSoundPath,_that.recurrenceRule,_that.parentId,_that.isRecurrenceInstance);case _:
  return null;

}
}

}

/// @nodoc


class _CalendarEvent extends CalendarEvent with DiagnosticableTreeMixin {
  const _CalendarEvent({required this.id, required this.title, required this.date, this.endDate, this.startTime, this.endTime, this.colorValue, this.isAllDay = false, this.isAlarmOn = true, this.alarmMinutes = AlarmMinutes.none, this.eventAlarmMode = AlarmMode.soundAndVibration, this.soundOption = NotificationSound.system, this.vibrationPattern = VibrationPattern.heartbeat, this.customSoundPath, this.recurrenceRule, this.parentId, this.isRecurrenceInstance = false}): super._();
  

@override final  int id;
@override final  String title;
@override final  String date;
@override final  String? endDate;
@override final  String? startTime;
@override final  String? endTime;
@override final  int? colorValue;
@override@JsonKey() final  bool isAllDay;
@override@JsonKey() final  bool isAlarmOn;
@override@JsonKey() final  AlarmMinutes alarmMinutes;
@override@JsonKey() final  AlarmMode eventAlarmMode;
@override@JsonKey() final  NotificationSound soundOption;
@override@JsonKey() final  VibrationPattern vibrationPattern;
@override final  String? customSoundPath;
@override final  RecurrenceRule? recurrenceRule;
@override final  int? parentId;
@override@JsonKey() final  bool isRecurrenceInstance;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarEventCopyWith<_CalendarEvent> get copyWith => __$CalendarEventCopyWithImpl<_CalendarEvent>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'CalendarEvent'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('date', date))..add(DiagnosticsProperty('endDate', endDate))..add(DiagnosticsProperty('startTime', startTime))..add(DiagnosticsProperty('endTime', endTime))..add(DiagnosticsProperty('colorValue', colorValue))..add(DiagnosticsProperty('isAllDay', isAllDay))..add(DiagnosticsProperty('isAlarmOn', isAlarmOn))..add(DiagnosticsProperty('alarmMinutes', alarmMinutes))..add(DiagnosticsProperty('eventAlarmMode', eventAlarmMode))..add(DiagnosticsProperty('soundOption', soundOption))..add(DiagnosticsProperty('vibrationPattern', vibrationPattern))..add(DiagnosticsProperty('customSoundPath', customSoundPath))..add(DiagnosticsProperty('recurrenceRule', recurrenceRule))..add(DiagnosticsProperty('parentId', parentId))..add(DiagnosticsProperty('isRecurrenceInstance', isRecurrenceInstance));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.date, date) || other.date == date)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&(identical(other.isAllDay, isAllDay) || other.isAllDay == isAllDay)&&(identical(other.isAlarmOn, isAlarmOn) || other.isAlarmOn == isAlarmOn)&&(identical(other.alarmMinutes, alarmMinutes) || other.alarmMinutes == alarmMinutes)&&(identical(other.eventAlarmMode, eventAlarmMode) || other.eventAlarmMode == eventAlarmMode)&&(identical(other.soundOption, soundOption) || other.soundOption == soundOption)&&(identical(other.vibrationPattern, vibrationPattern) || other.vibrationPattern == vibrationPattern)&&(identical(other.customSoundPath, customSoundPath) || other.customSoundPath == customSoundPath)&&(identical(other.recurrenceRule, recurrenceRule) || other.recurrenceRule == recurrenceRule)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.isRecurrenceInstance, isRecurrenceInstance) || other.isRecurrenceInstance == isRecurrenceInstance));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,date,endDate,startTime,endTime,colorValue,isAllDay,isAlarmOn,alarmMinutes,eventAlarmMode,soundOption,vibrationPattern,customSoundPath,recurrenceRule,parentId,isRecurrenceInstance);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'CalendarEvent(id: $id, title: $title, date: $date, endDate: $endDate, startTime: $startTime, endTime: $endTime, colorValue: $colorValue, isAllDay: $isAllDay, isAlarmOn: $isAlarmOn, alarmMinutes: $alarmMinutes, eventAlarmMode: $eventAlarmMode, soundOption: $soundOption, vibrationPattern: $vibrationPattern, customSoundPath: $customSoundPath, recurrenceRule: $recurrenceRule, parentId: $parentId, isRecurrenceInstance: $isRecurrenceInstance)';
}


}

/// @nodoc
abstract mixin class _$CalendarEventCopyWith<$Res> implements $CalendarEventCopyWith<$Res> {
  factory _$CalendarEventCopyWith(_CalendarEvent value, $Res Function(_CalendarEvent) _then) = __$CalendarEventCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String date, String? endDate, String? startTime, String? endTime, int? colorValue, bool isAllDay, bool isAlarmOn, AlarmMinutes alarmMinutes, AlarmMode eventAlarmMode, NotificationSound soundOption, VibrationPattern vibrationPattern, String? customSoundPath, RecurrenceRule? recurrenceRule, int? parentId, bool isRecurrenceInstance
});




}
/// @nodoc
class __$CalendarEventCopyWithImpl<$Res>
    implements _$CalendarEventCopyWith<$Res> {
  __$CalendarEventCopyWithImpl(this._self, this._then);

  final _CalendarEvent _self;
  final $Res Function(_CalendarEvent) _then;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? date = null,Object? endDate = freezed,Object? startTime = freezed,Object? endTime = freezed,Object? colorValue = freezed,Object? isAllDay = null,Object? isAlarmOn = null,Object? alarmMinutes = null,Object? eventAlarmMode = null,Object? soundOption = null,Object? vibrationPattern = null,Object? customSoundPath = freezed,Object? recurrenceRule = freezed,Object? parentId = freezed,Object? isRecurrenceInstance = null,}) {
  return _then(_CalendarEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,colorValue: freezed == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int?,isAllDay: null == isAllDay ? _self.isAllDay : isAllDay // ignore: cast_nullable_to_non_nullable
as bool,isAlarmOn: null == isAlarmOn ? _self.isAlarmOn : isAlarmOn // ignore: cast_nullable_to_non_nullable
as bool,alarmMinutes: null == alarmMinutes ? _self.alarmMinutes : alarmMinutes // ignore: cast_nullable_to_non_nullable
as AlarmMinutes,eventAlarmMode: null == eventAlarmMode ? _self.eventAlarmMode : eventAlarmMode // ignore: cast_nullable_to_non_nullable
as AlarmMode,soundOption: null == soundOption ? _self.soundOption : soundOption // ignore: cast_nullable_to_non_nullable
as NotificationSound,vibrationPattern: null == vibrationPattern ? _self.vibrationPattern : vibrationPattern // ignore: cast_nullable_to_non_nullable
as VibrationPattern,customSoundPath: freezed == customSoundPath ? _self.customSoundPath : customSoundPath // ignore: cast_nullable_to_non_nullable
as String?,recurrenceRule: freezed == recurrenceRule ? _self.recurrenceRule : recurrenceRule // ignore: cast_nullable_to_non_nullable
as RecurrenceRule?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,isRecurrenceInstance: null == isRecurrenceInstance ? _self.isRecurrenceInstance : isRecurrenceInstance // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
