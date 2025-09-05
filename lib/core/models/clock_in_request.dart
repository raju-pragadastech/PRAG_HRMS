import 'package:json_annotation/json_annotation.dart';

part 'clock_in_request.g.dart';

@JsonSerializable()
class ClockInRequest {
  final String employeeId;
  final double? latitude;
  final double? longitude;
  final String workLocation;
  final bool userConfirmed;

  const ClockInRequest({
    required this.employeeId,
    this.latitude,
    this.longitude,
    required this.workLocation,
    required this.userConfirmed,
  });

  factory ClockInRequest.fromJson(Map<String, dynamic> json) =>
      _$ClockInRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ClockInRequestToJson(this);
}
