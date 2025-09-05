// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeEntry _$TimeEntryFromJson(Map<String, dynamic> json) => TimeEntry(
  employeeId: json['employeeId'] as String?,
  clockInTime: json['clockInTime'] as String?,
  clockOutTime: json['clockOutTime'] as String?,
  workLocation: json['workLocation'] as String?,
  totalHours: json['totalHours'] as String?,
  status: json['status'] as String?,
  date: json['date'] as String?,
  dayName: json['dayName'] as String?,
  isCompleted: json['isCompleted'] as bool?,
);

Map<String, dynamic> _$TimeEntryToJson(TimeEntry instance) => <String, dynamic>{
  'employeeId': instance.employeeId,
  'clockInTime': instance.clockInTime,
  'clockOutTime': instance.clockOutTime,
  'workLocation': instance.workLocation,
  'totalHours': instance.totalHours,
  'status': instance.status,
  'date': instance.date,
  'dayName': instance.dayName,
  'isCompleted': instance.isCompleted,
};
