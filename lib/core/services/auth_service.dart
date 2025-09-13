import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/employee.dart';
import '../models/change_password_request.dart';
import '../models/forgot_password_request.dart';
import '../models/reset_password_request.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'device_service.dart';
import 'theme_service.dart';
import 'attendance_data_manager.dart';

class AuthService {
  static ThemeService? _themeService;

  // Set theme service reference
  static void setThemeService(ThemeService themeService) {
    _themeService = themeService;
  }

  // Login user
  static Future<LoginResponse> login(
    String employeeIdOrEmail,
    String password,
  ) async {
    try {
      // Clear any existing employee data to ensure fresh start
      await StorageService.clearEmployeeData();
      print('🧹 Cleared existing employee data for fresh login');

      // Get device information
      final deviceInfo = await DeviceService.getDeviceInfo();
      print('📱 ========== DEVICE INFO DEBUG ==========');
      print('📱 Device ID: ${deviceInfo['deviceId']}');
      print('📱 Device Name: ${deviceInfo['deviceName']}');
      print('📱 App Version: ${deviceInfo['appVersion']}');
      print('📱 Platform: ${deviceInfo['platform']}');
      print('📱 Full Device Info: $deviceInfo');
      print('📱 ========================================');

      final request = LoginRequest(
        employeeIdOrEmail: employeeIdOrEmail,
        password: password,
        deviceId: deviceInfo['deviceId'],
        deviceName: deviceInfo['deviceName'],
        appVersion: deviceInfo['appVersion'],
        platform: deviceInfo['platform'],
      );

      print('📱 ========== LOGIN REQUEST DEBUG ==========');
      print('📱 Employee ID/Email: $employeeIdOrEmail');
      print('📱 Password Length: ${password.length}');
      print('📱 Request JSON: ${request.toJson()}');
      print('📱 ==========================================');

      final response = await ApiService.login(request);
      print(
        '📱 Login response received: success=${response.success}, token=${response.token != null}, employeeId=${response.employeeId}',
      );
      print(
        '📱 Employee data: firstName=${response.firstName}, lastName=${response.lastName}, email=${response.email}',
      );

      if (response.success &&
          response.token != null &&
          response.employeeId != null) {
        print('📱 Saving authentication data...');

        // Save token and employee data to secure storage
        await StorageService.saveToken(response.token!);
        await StorageService.saveEmployeeId(response.employeeId!);
        print('📱 Token and Employee ID saved');

        // Save device information
        await StorageService.saveDeviceId(deviceInfo['deviceId']!);
        await StorageService.saveDeviceName(deviceInfo['deviceName']!);
        print('📱 Device information saved');

        if (response.role != null) {
          await StorageService.saveUserRole(response.role!);
          print('📱 User role saved: ${response.role}');
        }

        // Save employee data from login response
        final employeeData = {
          'employeeId': response.employeeId,
          'firstName': response.firstName,
          'lastName': response.lastName,
          'email': response.email,
          'role': response.role,
        };
        print('📱 About to save employee data: $employeeData');
        print('📱 First Name: "${response.firstName}"');
        print('📱 Last Name: "${response.lastName}"');
        await StorageService.saveEmployeeData(employeeData);
        print('📱 Employee data saved to storage: $employeeData');

        // Verify the data was saved
        final savedEmployeeId = await StorageService.getEmployeeId();
        final savedEmployeeData = await StorageService.getEmployeeData();
        print('📱 Verification - Saved Employee ID: $savedEmployeeId');
        print('📱 Verification - Saved Employee Data: $savedEmployeeData');

        // Set current user in attendance data manager
        AttendanceDataManager().setCurrentUser(response.employeeId);

        // Notify theme service that user is now authenticated
        _themeService?.setAuthenticated(true);
      } else {
        print(
          '❌ Login response validation failed: success=${response.success}, token=${response.token != null}, employeeId=${response.employeeId}',
        );
      }

      return response;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Logout user
  static Future<void> logout() async {
    try {
      print('🚪 Logging out user...');

      // Clear attendance data first
      AttendanceDataManager().clearAllData();

      // Clear all stored data including employee profile data
      await StorageService.clearAll();

      // Notify theme service that user is no longer authenticated
      _themeService?.setAuthenticated(false);

      print('🚪 User logged out successfully - all data cleared');
    } catch (e) {
      print('❌ Logout error: $e');
      throw Exception('Logout failed: $e');
    }
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await StorageService.isLoggedIn();
  }

  // Logout from all devices
  static Future<void> logoutAllDevices() async {
    try {
      print('🚪 Logging out from all devices...');

      // Clear attendance data first
      AttendanceDataManager().clearAllData();

      // Call API to logout from all devices
      await ApiService.logoutAllDevices();

      // Clear local data
      await StorageService.clearAll();

      print('🚪 Successfully logged out from all devices');
    } catch (e) {
      print('❌ Logout all devices error: $e');
      // Even if API call fails, clear local data
      AttendanceDataManager().clearAllData();
      await StorageService.clearAll();
      throw Exception('Failed to logout from all devices: $e');
    }
  }

  // Logout from current device only
  static Future<void> logoutCurrentDevice() async {
    try {
      print('🚪 Logging out from current device...');

      // Clear attendance data first
      AttendanceDataManager().clearAllData();

      // Call API to logout from current device
      await ApiService.logoutCurrentDevice();

      // Clear local data
      await StorageService.clearAll();

      print('🚪 Successfully logged out from current device');
    } catch (e) {
      print('❌ Logout current device error: $e');
      // Even if API call fails, clear local data
      AttendanceDataManager().clearAllData();
      await StorageService.clearAll();
      throw Exception('Failed to logout from current device: $e');
    }
  }

  // Get device sessions
  static Future<List<Map<String, dynamic>>> getDeviceSessions() async {
    try {
      print('📱 Getting device sessions...');
      return await ApiService.getDeviceSessions();
    } catch (e) {
      print('❌ Get device sessions error: $e');
      throw Exception('Failed to get device sessions: $e');
    }
  }

  // Check if current device is logged in
  static Future<bool> isCurrentDeviceLoggedIn() async {
    try {
      final token = await StorageService.getToken();
      final deviceId = await StorageService.getDeviceId();
      final currentDeviceId = await DeviceService.getDeviceId();

      return token != null &&
          token.isNotEmpty &&
          deviceId != null &&
          deviceId == currentDeviceId;
    } catch (e) {
      print('❌ Error checking device login status: $e');
      return false;
    }
  }

  // Get current user profile
  static Future<Employee?> getCurrentUserProfile() async {
    try {
      final employeeId = await StorageService.getEmployeeId();
      if (employeeId == null) return null;

      // Try to get employee data from storage first (from login response)
      final storedEmployeeData = await StorageService.getEmployeeData();
      if (storedEmployeeData != null) {
        print('📱 Using stored employee data from login response');
        return Employee.fromJson(storedEmployeeData);
      }

      // Fallback to API call if no stored data
      print('📱 No stored employee data, making API call');
      return await ApiService.getEmployeeProfile(employeeId);
    } catch (e) {
      print('❌ Error getting employee profile: $e');
      // If token is invalid/expired, clear storage and return null
      await StorageService.clearAll();
      return null;
    }
  }

  // Get detailed employee profile (for profile screen)
  static Future<Employee?> getDetailedEmployeeProfile({
    bool forceRefresh = false,
  }) async {
    try {
      print('📱 Fetching detailed employee profile...');

      // Always fetch fresh data from API for profile screen
      // This ensures we get the correct employee data after login
      print('📱 Making fresh API call for detailed profile');
      final employee = await ApiService.getEmployeeProfileDetails();

      // Store the fresh detailed profile data
      await StorageService.saveDetailedEmployeeProfile(employee.toJson());
      print('📱 Fresh detailed profile data saved to storage');

      return employee;
    } catch (e) {
      print('❌ Error getting detailed employee profile: $e');

      // If API fails, try to get from storage as fallback
      final storedDetailedProfile =
          await StorageService.getDetailedEmployeeProfile();
      if (storedDetailedProfile != null) {
        print('📱 API failed, using stored detailed profile data as fallback');
        return Employee.fromJson(storedDetailedProfile);
      }

      return null;
    }
  }

  // Get stored token
  static Future<String?> getToken() async {
    return await StorageService.getToken();
  }

  // Get stored employee ID
  static Future<String?> getEmployeeId() async {
    return await StorageService.getEmployeeId();
  }

  // Get stored user role
  static Future<String?> getUserRole() async {
    return await StorageService.getUserRole();
  }

  // Refresh token (if needed in future)
  static Future<bool> refreshToken() async {
    // Implementation for token refresh if backend supports it
    // For now, return true if token exists
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      print('🔐 Changing password...');

      final request = ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      final response = await ApiService.changePassword(request);
      print('✅ Password changed successfully');
      return response;
    } catch (e) {
      print('❌ Error changing password: $e');
      rethrow;
    }
  }

  // Forgot password
  static Future<Map<String, dynamic>> forgotPassword(
    String employeeIdOrEmail,
  ) async {
    try {
      print('🔐 Sending forgot password request...');

      final request = ForgotPasswordRequest(
        employeeIdOrEmail: employeeIdOrEmail,
      );

      final response = await ApiService.forgotPassword(request);
      print('✅ Forgot password request sent successfully');
      return response;
    } catch (e) {
      print('❌ Error sending forgot password request: $e');
      rethrow;
    }
  }

  // Reset password
  static Future<Map<String, dynamic>> resetPassword(
    String token,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      print('🔐 Resetting password...');

      final request = ResetPasswordRequest(
        token: token,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      final response = await ApiService.resetPassword(request);
      print('✅ Password reset successfully');
      return response;
    } catch (e) {
      print('❌ Error resetting password: $e');
      rethrow;
    }
  }
}
