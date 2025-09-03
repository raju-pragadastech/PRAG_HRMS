import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/employee.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  // Login user
  static Future<LoginResponse> login(
    String employeeIdOrEmail,
    String password,
  ) async {
    try {
      final request = LoginRequest(
        employeeIdOrEmail: employeeIdOrEmail,
        password: password,
      );

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
      await StorageService.clearAll();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await StorageService.isLoggedIn();
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
  static Future<Employee?> getDetailedEmployeeProfile() async {
    try {
      print('📱 Fetching detailed employee profile...');

      // Try to get detailed profile data from storage first
      final storedDetailedProfile =
          await StorageService.getDetailedEmployeeProfile();
      if (storedDetailedProfile != null) {
        print('📱 Using stored detailed profile data');
        return Employee.fromJson(storedDetailedProfile);
      }

      // Fetch from API if not in storage
      print('📱 No stored detailed profile, making API call');
      final employee = await ApiService.getEmployeeProfileDetails();

      // Store the detailed profile data
      await StorageService.saveDetailedEmployeeProfile(employee.toJson());
      print('📱 Detailed profile data saved to storage');

      return employee;
    } catch (e) {
      print('❌ Error getting detailed employee profile: $e');
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
}
