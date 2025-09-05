import 'package:json_annotation/json_annotation.dart';

part 'time_entry_response.g.dart';

@JsonSerializable()
class TimeEntryResponse {
  final bool? success;
  final String? message;
  final String? clockInTime;
  final String? clockOutTime;
  @JsonKey(fromJson: _totalHoursFromJson)
  final String? totalHours;
  final String? status;
  final String? workLocation;

  const TimeEntryResponse({
    this.success,
    this.message,
    this.clockInTime,
    this.clockOutTime,
    this.totalHours,
    this.status,
    this.workLocation,
  });

  factory TimeEntryResponse.fromJson(Map<String, dynamic> json) =>
      _$TimeEntryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TimeEntryResponseToJson(this);

  // Helper function to handle totalHours conversion from dynamic to String
  static String? _totalHoursFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    return value.toString();
  }

  // Helper method to determine if the operation was successful
  bool get isSuccessful {
    // If success field is explicitly true, return true
    if (success == true) return true;

    // If success field is explicitly false, return false
    if (success == false) return false;

    // If success is null, try to determine from other fields
    // Consider it successful if we have a message and no error indicators
    if (message != null &&
        !message!.toLowerCase().contains('error') &&
        !message!.toLowerCase().contains('failed')) {
      return true;
    }

    // Default to false if we can't determine success
    return false;
  }
}
