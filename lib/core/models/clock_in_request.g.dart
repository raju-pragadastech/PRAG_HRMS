// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock_in_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClockInRequest _$ClockInRequestFromJson(Map<String, dynamic> json) =>
    ClockInRequest(
      employeeId: json['employeeId'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      workLocation: json['workLocation'] as String,
      userConfirmed: json['userConfirmed'] as bool,
    );

Map<String, dynamic> _$ClockInRequestToJson(ClockInRequest instance) =>
    <String, dynamic>{
      'employeeId': instance.employeeId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'workLocation': instance.workLocation,
      'userConfirmed': instance.userConfirmed,
    };
