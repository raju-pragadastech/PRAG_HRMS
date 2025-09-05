// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  employeeIdOrEmail: json['username'] as String,
  password: json['password'] as String,
  deviceId: json['deviceId'] as String?,
  deviceName: json['deviceName'] as String?,
  appVersion: json['appVersion'] as String?,
  platform: json['platform'] as String?,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'username': instance.employeeIdOrEmail,
      'password': instance.password,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'appVersion': instance.appVersion,
      'platform': instance.platform,
    };
