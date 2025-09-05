// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_entry_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeEntryResponse _$TimeEntryResponseFromJson(Map<String, dynamic> json) =>
    TimeEntryResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      clockInTime: json['clockInTime'] as String?,
      clockOutTime: json['clockOutTime'] as String?,
      totalHours: TimeEntryResponse._totalHoursFromJson(json['totalHours']),
      status: json['status'] as String?,
      workLocation: json['workLocation'] as String?,
    );

Map<String, dynamic> _$TimeEntryResponseToJson(TimeEntryResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'clockInTime': instance.clockInTime,
      'clockOutTime': instance.clockOutTime,
      'totalHours': instance.totalHours,
      'status': instance.status,
      'workLocation': instance.workLocation,
    };
