import 'package:json_annotation/json_annotation.dart';

part 'time_entry_status.g.dart';

@JsonSerializable()
class TimeEntryStatus {
  @JsonKey(name: 'currentlyClockedIn')
  final bool? isClockedIn;
  final String? clockInTime;
  final String? clockOutTime;
  @JsonKey(fromJson: _totalHoursFromJson)
  final String? totalHours;
  final String? status;
  final String? workLocation;
  final String? employeeId;

  const TimeEntryStatus({
    this.isClockedIn,
    this.clockInTime,
    this.clockOutTime,
    this.totalHours,
    this.status,
    this.workLocation,
    this.employeeId,
  });

  factory TimeEntryStatus.fromJson(Map<String, dynamic> json) =>
      _$TimeEntryStatusFromJson(json);

  Map<String, dynamic> toJson() => _$TimeEntryStatusToJson(this);

  // Helper function to handle totalHours conversion from dynamic to String
  static String? _totalHoursFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    return value.toString();
  }
}
