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

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all stored data (logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Clear specific key
  static Future<void> clearKey(String key) async {
    await _storage.delete(key: key);
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
}
