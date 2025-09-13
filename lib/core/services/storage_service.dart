import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Save authentication token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: ApiConstants.tokenKey, value: token);
  }

  // Get authentication token
  static Future<String?> getToken() async {
    return await _storage.read(key: ApiConstants.tokenKey);
  }

  // Save employee ID
  static Future<void> saveEmployeeId(String employeeId) async {
    print('💾 Saving employee ID: $employeeId');
    await _storage.write(key: ApiConstants.employeeIdKey, value: employeeId);
    print('💾 Employee ID saved successfully');
  }

  // Get employee ID
  static Future<String?> getEmployeeId() async {
    final employeeId = await _storage.read(key: ApiConstants.employeeIdKey);
    print('💾 Retrieved employee ID: $employeeId');
    return employeeId;
  }

  // Save user role
  static Future<void> saveUserRole(String role) async {
    await _storage.write(key: ApiConstants.userRoleKey, value: role);
  }

  // Get user role
  static Future<String?> getUserRole() async {
    return await _storage.read(key: ApiConstants.userRoleKey);
  }

  // Save device ID
  static Future<void> saveDeviceId(String deviceId) async {
    print('💾 Saving device ID: $deviceId');
    await _storage.write(key: ApiConstants.deviceIdKey, value: deviceId);
    print('💾 Device ID saved successfully');
  }

  // Get device ID
  static Future<String?> getDeviceId() async {
    final deviceId = await _storage.read(key: ApiConstants.deviceIdKey);
    print('💾 Retrieved device ID: $deviceId');
    return deviceId;
  }

  // Save device name
  static Future<void> saveDeviceName(String deviceName) async {
    print('💾 Saving device name: $deviceName');
    await _storage.write(key: ApiConstants.deviceNameKey, value: deviceName);
    print('💾 Device name saved successfully');
  }

  // Get device name
  static Future<String?> getDeviceName() async {
    final deviceName = await _storage.read(key: ApiConstants.deviceNameKey);
    print('💾 Retrieved device name: $deviceName');
    return deviceName;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all stored data (logout)
  static Future<void> clearAll() async {
    print('💾 Clearing all stored data...');
    await _storage.deleteAll();
    print('💾 All stored data cleared successfully');
  }

  // Clear specific key
  static Future<void> clearKey(String key) async {
    await _storage.delete(key: key);
  }

  // Clear employee-related data specifically
  static Future<void> clearEmployeeData() async {
    print('💾 Clearing employee-related data...');
    await _storage.delete(key: 'employee_data');
    await _storage.delete(key: 'detailed_employee_profile');
    await _storage.delete(key: 'clock_in_data');
    await _storage.delete(key: 'clock_out_data');
    await _storage.delete(key: 'time_entries_data');
    print('💾 Employee-related data cleared successfully');
  }

  // Save employee data (from login response)
  static Future<void> saveEmployeeData(
    Map<String, dynamic> employeeData,
  ) async {
    print('💾 Saving employee data: $employeeData');
    final jsonString = json.encode(employeeData);
    await _storage.write(key: 'employee_data', value: jsonString);
    print('💾 Employee data saved successfully');
  }

  // Get employee data
  static Future<Map<String, dynamic>?> getEmployeeData() async {
    final jsonString = await _storage.read(key: 'employee_data');
    print('💾 Retrieved employee data JSON: $jsonString');
    if (jsonString != null) {
      final data = json.decode(jsonString);
      print('💾 Parsed employee data: $data');
      return data;
    }
    return null;
  }

  // Save detailed employee profile data (from profile API)
  static Future<void> saveDetailedEmployeeProfile(
    Map<String, dynamic> profileData,
  ) async {
    print('💾 Saving detailed employee profile: $profileData');
    final jsonString = json.encode(profileData);
    await _storage.write(key: 'detailed_employee_profile', value: jsonString);
    print('💾 Detailed employee profile saved successfully');
  }

  // Get detailed employee profile data
  static Future<Map<String, dynamic>?> getDetailedEmployeeProfile() async {
    final jsonString = await _storage.read(key: 'detailed_employee_profile');
    print('💾 Retrieved detailed profile JSON: $jsonString');
    if (jsonString != null) {
      final data = json.decode(jsonString);
      print('💾 Parsed detailed profile data: $data');
      return data;
    }
    return null;
  }

  // Save clock-in data
  static Future<void> saveClockInData(Map<String, dynamic> clockInData) async {
    print('💾 Saving clock-in data: $clockInData');
    final jsonString = json.encode(clockInData);
    await _storage.write(key: 'clock_in_data', value: jsonString);
    print('💾 Clock-in data saved successfully');
  }

  // Get clock-in data
  static Future<Map<String, dynamic>?> getClockInData() async {
    final jsonString = await _storage.read(key: 'clock_in_data');
    print('💾 Retrieved clock-in JSON: $jsonString');
    if (jsonString != null) {
      final data = json.decode(jsonString);
      print('💾 Parsed clock-in data: $data');
      return data;
    }
    return null;
  }

  // Save clock-out data
  static Future<void> saveClockOutData(
    Map<String, dynamic> clockOutData,
  ) async {
    print('💾 Saving clock-out data: $clockOutData');
    final jsonString = json.encode(clockOutData);
    await _storage.write(key: 'clock_out_data', value: jsonString);
    print('💾 Clock-out data saved successfully');
  }

  // Get clock-out data
  static Future<Map<String, dynamic>?> getClockOutData() async {
    final jsonString = await _storage.read(key: 'clock_out_data');
    print('💾 Retrieved clock-out JSON: $jsonString');
    if (jsonString != null) {
      final data = json.decode(jsonString);
      print('💾 Parsed clock-out data: $data');
      return data;
    }
    return null;
  }

  // Save time entries data
  static Future<void> saveTimeEntriesData(
    List<Map<String, dynamic>> timeEntries,
  ) async {
    print('💾 Saving time entries data: ${timeEntries.length} entries');
    final jsonString = json.encode(timeEntries);
    await _storage.write(key: 'time_entries_data', value: jsonString);
    print('💾 Time entries data saved successfully');
  }

  // Get time entries data
  static Future<List<Map<String, dynamic>>?> getTimeEntriesData() async {
    final jsonString = await _storage.read(key: 'time_entries_data');
    print('💾 Retrieved time entries JSON: $jsonString');
    if (jsonString != null) {
      final data = json.decode(jsonString);
      print('💾 Parsed time entries data: ${data.length} entries');
      return List<Map<String, dynamic>>.from(data);
    }
    return null;
  }

  // Save theme mode
  static Future<void> saveThemeMode(String themeMode) async {
    print('💾 Saving theme mode: $themeMode');
    await _storage.write(key: 'app_theme', value: themeMode);
    print('💾 Theme mode saved successfully');
  }

  // Get theme mode
  static Future<String?> getThemeMode() async {
    final themeMode = await _storage.read(key: 'app_theme');
    print('💾 Retrieved theme mode: $themeMode');
    return themeMode;
  }

  // Save profile image URL for a user
  static Future<void> saveProfileImageUrl(
    String userId,
    String imageUrl,
  ) async {
    print('💾 Saving profile image URL for user $userId: $imageUrl');
    await _storage.write(key: 'profile_image_$userId', value: imageUrl);
    print('💾 Profile image URL saved successfully');
  }

  // Get profile image URL for a user
  static Future<String?> getProfileImageUrl(String userId) async {
    final imageUrl = await _storage.read(key: 'profile_image_$userId');
    print('💾 Retrieved profile image URL for user $userId: $imageUrl');
    return imageUrl;
  }

  // Remove profile image URL for a user
  static Future<void> removeProfileImageUrl(String userId) async {
    print('💾 Removing profile image URL for user $userId');
    await _storage.delete(key: 'profile_image_$userId');
    print('💾 Profile image URL removed successfully');
  }
}
