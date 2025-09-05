import '../models/clock_in_request.dart';
import '../models/clock_out_request.dart';
import '../models/time_entry_response.dart';
import '../models/time_entry_status.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'location_service.dart';

class TimeEntryService {
  // Clock In
  static Future<TimeEntryResponse> clockIn({
    required String employeeId,
    required String workLocation,
    double? latitude,
    double? longitude,
    bool useGpsLocation = true,
  }) async {
    try {
      print('🕐 TimeEntryService: Clocking in employee $employeeId');

      double? finalLatitude = latitude;
      double? finalLongitude = longitude;

      // Get GPS location if requested and not provided
      if (useGpsLocation && (latitude == null || longitude == null)) {
        try {
          print('📍 Getting GPS location for clock-in...');
          final location = await LocationService.getCurrentLocation();
          finalLatitude = location['latitude'];
          finalLongitude = location['longitude'];
          print('📍 GPS location obtained: $finalLatitude, $finalLongitude');
        } catch (e) {
          print('⚠️ GPS location failed, using provided coordinates: $e');
          // Continue with provided coordinates or null values
        }
      }

      final request = ClockInRequest(
        employeeId: employeeId,
        latitude: finalLatitude,
        longitude: finalLongitude,
        workLocation: workLocation,
        userConfirmed: true,
      );

      final response = await ApiService.clockIn(request);

      if (response.isSuccessful) {
        // Store clock-in data
        await StorageService.saveClockInData({
          'employeeId': employeeId,
          'clockInTime': DateTime.now().toIso8601String(),
          'workLocation': workLocation,
          'latitude': finalLatitude,
          'longitude': finalLongitude,
        });
        print('🕐 Clock-in data saved to storage');
      }

      return response;
    } catch (e) {
      print('❌ TimeEntryService clock-in error: $e');
      if (e.toString().contains('credentials_invalid')) {
        throw Exception('credentials_invalid');
      } else {
        throw Exception('Clock-in failed: $e');
      }
    }
  }

  // Clock Out
  static Future<TimeEntryResponse> clockOut({
    required String employeeId,
    required String workLocation,
    double? latitude,
    double? longitude,
    bool useGpsLocation = true,
  }) async {
    try {
      print('🕐 TimeEntryService: Clocking out employee $employeeId');

      double? finalLatitude = latitude;
      double? finalLongitude = longitude;

      // Get GPS location if requested and not provided
      if (useGpsLocation && (latitude == null || longitude == null)) {
        try {
          print('📍 Getting GPS location for clock-out...');
          final location = await LocationService.getCurrentLocation();
          finalLatitude = location['latitude'];
          finalLongitude = location['longitude'];
          print('📍 GPS location obtained: $finalLatitude, $finalLongitude');
        } catch (e) {
          print('⚠️ GPS location failed, using provided coordinates: $e');
          // Continue with provided coordinates or null values
        }
      }

      final request = ClockOutRequest(
        employeeId: employeeId,
        latitude: finalLatitude,
        longitude: finalLongitude,
        workLocation: workLocation,
        userConfirmed: true,
      );

      final response = await ApiService.clockOut(request);

      if (response.isSuccessful) {
        // Store clock-out data
        await StorageService.saveClockOutData({
          'employeeId': employeeId,
          'clockOutTime': DateTime.now().toIso8601String(),
          'workLocation': workLocation,
          'latitude': finalLatitude,
          'longitude': finalLongitude,
          'totalHours': response.totalHours,
        });
        print('🕐 Clock-out data saved to storage');
      }

      return response;
    } catch (e) {
      print('❌ TimeEntryService clock-out error: $e');
      if (e.toString().contains('not_clocked_in')) {
        throw Exception('not_clocked_in');
      } else if (e.toString().contains('credentials_invalid')) {
        throw Exception('credentials_invalid');
      } else {
        throw Exception('Clock-out failed: $e');
      }
    }
  }

  // Get Current Status
  static Future<TimeEntryStatus> getCurrentStatus(String employeeId) async {
    try {
      print('🕐 ========== CURRENT STATUS DEBUG START ==========');
      print('🕐 Employee ID: $employeeId');
      print('🕐 TimeEntryService: Getting status for employee $employeeId');

      final status = await ApiService.getTimeEntryStatus(employeeId);

      print('🕐 Status result: ${status.toJson()}');
      print('🕐 Is clocked in: ${status.isClockedIn}');
      print('🕐 Clock in time: ${status.clockInTime}');
      print('🕐 ========== CURRENT STATUS DEBUG END ==========');

      return status;
    } catch (e) {
      print('❌ TimeEntryService get status error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error details: ${e.toString()}');
      throw Exception('Failed to get status: $e');
    }
  }

  // Get Time Entries for Date Range
  static Future<List<Map<String, dynamic>>> getTimeEntries(
    String employeeId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      print(
        '🕐 TimeEntryService: Getting time entries for employee $employeeId',
      );

      // Convert string dates to DateTime
      final start = startDate != null
          ? DateTime.parse(startDate)
          : DateTime.now().subtract(const Duration(days: 30));
      final end = endDate != null ? DateTime.parse(endDate) : DateTime.now();

      final timeEntries = await ApiService.getEmployeeTimeEntries(
        employeeId,
        startDate: start,
        endDate: end,
      );

      // Return the time entries directly as they are already Map<String, dynamic>
      return timeEntries;
    } catch (e) {
      print('❌ TimeEntryService get time entries error: $e');
      throw Exception('Failed to get time entries: $e');
    }
  }

  // Get Weekly Time Entries
  static Future<List<Map<String, dynamic>>> getWeeklyTimeEntries(
    String employeeId,
  ) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final startDate = startOfWeek.toIso8601String().split('T')[0];
      final endDate = endOfWeek.toIso8601String().split('T')[0];

      print('🕐 ========== WEEKLY TIME ENTRIES DEBUG START ==========');
      print('🕐 Employee ID: $employeeId');
      print('🕐 Start Date: $startDate');
      print('🕐 End Date: $endDate');
      print(
        '🕐 TimeEntryService: Getting weekly entries from $startDate to $endDate',
      );

      final result = await getTimeEntries(
        employeeId,
        startDate: startDate,
        endDate: endDate,
      );

      print('🕐 Weekly entries result: $result');
      print('🕐 Result count: ${result.length}');
      print('🕐 ========== WEEKLY TIME ENTRIES DEBUG END ==========');

      return result;
    } catch (e) {
      print('❌ TimeEntryService get weekly entries error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error details: ${e.toString()}');
      throw Exception('Failed to get weekly entries: $e');
    }
  }
}
