import 'package:json_annotation/json_annotation.dart';

part 'clock_out_request.g.dart';

@JsonSerializable()
class ClockOutRequest {
  final String employeeId;
  final double? latitude;
  final double? longitude;
  final String workLocation;
  final bool userConfirmed;

  const ClockOutRequest({
    required this.employeeId,
    this.latitude,
    this.longitude,
    required this.workLocation,
    required this.userConfirmed,
  });

  factory ClockOutRequest.fromJson(Map<String, dynamic> json) =>
      _$ClockOutRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ClockOutRequestToJson(this);
}
