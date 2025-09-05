// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_entry_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeEntryStatus _$TimeEntryStatusFromJson(Map<String, dynamic> json) =>
    TimeEntryStatus(
      isClockedIn: json['currentlyClockedIn'] as bool?,
      clockInTime: json['clockInTime'] as String?,
      clockOutTime: json['clockOutTime'] as String?,
      totalHours: TimeEntryStatus._totalHoursFromJson(json['totalHours']),
      status: json['status'] as String?,
      workLocation: json['workLocation'] as String?,
      employeeId: json['employeeId'] as String?,
    );

Map<String, dynamic> _$TimeEntryStatusToJson(TimeEntryStatus instance) =>
    <String, dynamic>{
      'currentlyClockedIn': instance.isClockedIn,
      'clockInTime': instance.clockInTime,
      'clockOutTime': instance.clockOutTime,
      'totalHours': instance.totalHours,
      'status': instance.status,
      'workLocation': instance.workLocation,
      'employeeId': instance.employeeId,
    };
