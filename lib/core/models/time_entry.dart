import 'package:json_annotation/json_annotation.dart';

part 'time_entry.g.dart';

@JsonSerializable()
class TimeEntry {
  final String? employeeId;
  final String? clockInTime;
  final String? clockOutTime;
  final String? workLocation;
  final String? totalHours;
  final String? status;
  final String? date;
  final String? dayName;
  final bool? isCompleted;

  const TimeEntry({
    this.employeeId,
    this.clockInTime,
    this.clockOutTime,
    this.workLocation,
    this.totalHours,
    this.status,
    this.date,
    this.dayName,
    this.isCompleted,
  });

  factory TimeEntry.fromJson(Map<String, dynamic> json) =>
      _$TimeEntryFromJson(json);

  Map<String, dynamic> toJson() => _$TimeEntryToJson(this);

  // Helper method to check if the time entry is completed
  bool get isTimeEntryCompleted {
    return isCompleted ?? (clockOutTime != null && clockOutTime!.isNotEmpty);
  }

  // Helper method to get formatted clock in time
  String get formattedClockInTime {
    if (clockInTime == null || clockInTime!.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(clockInTime!);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return clockInTime!;
    }
  }

  // Helper method to get formatted clock out time
  String get formattedClockOutTime {
    if (clockOutTime == null || clockOutTime!.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(clockOutTime!);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return clockOutTime!;
    }
  }

  // Helper method to get day name from date
  String get dayNameFromDate {
    if (date == null || date!.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(date!);
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return weekdays[dateTime.weekday - 1];
    } catch (e) {
      return dayName ?? 'N/A';
    }
  }
}
