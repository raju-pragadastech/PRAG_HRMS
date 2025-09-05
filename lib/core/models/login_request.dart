import 'package:json_annotation/json_annotation.dart';

part 'login_request.g.dart';

@JsonSerializable()
class LoginRequest {
  @JsonKey(name: 'username')
  final String employeeIdOrEmail;
  final String password;
  final String? deviceId;
  final String? deviceName;
  final String? appVersion;
  final String? platform;

  const LoginRequest({
    required this.employeeIdOrEmail,
    required this.password,
    this.deviceId,
    this.deviceName,
    this.appVersion,
    this.platform,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}
