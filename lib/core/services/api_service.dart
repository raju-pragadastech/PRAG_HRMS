import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/employee.dart';
import 'storage_service.dart';

class ApiService {
  static final http.Client _client = http.Client();

  // Get headers with authentication
  static Future<Map<String, String>> _getHeaders({
    bool includeAuth = false,
  }) async {
    final headers = {'Content-Type': ApiConstants.contentTypeJson};

    if (includeAuth) {
      final token = await StorageService.getToken();
      if (token != null) {
        headers[ApiConstants.authorizationHeader] =
            '${ApiConstants.bearerPrefix}$token';
      }
    }

    return headers;
  }

  // Handle API response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    print('🔍 Handling response: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final responseData = json.decode(response.body);
        print('✅ Successfully parsed JSON: $responseData');
        return responseData;
      } catch (e) {
        print('❌ JSON parsing error: $e');
        throw HttpException('Invalid JSON response: ${response.body}');
      }
    } else {
      print('❌ API Error: ${response.statusCode} - ${response.body}');

      // Parse error response to determine specific error type
      try {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['message']?.toString().toLowerCase() ?? '';
        final errorType = errorData['error']?.toString().toLowerCase() ?? '';

        print('🔍 Error message: $errorMessage');
        print('🔍 Error type: $errorType');

        // Check for password-related errors
        if (errorMessage.contains('password') ||
            errorMessage.contains('incorrect password') ||
            errorMessage.contains('wrong password') ||
            errorMessage.contains('invalid password') ||
            errorType.contains('password')) {
          throw HttpException('password_invalid');
        }
        // Check for username/employee ID errors
        else if (errorMessage.contains('user') ||
            errorMessage.contains('employee') ||
            errorMessage.contains('username') ||
            errorMessage.contains('not found') ||
            errorMessage.contains('invalid username') ||
            errorMessage.contains('user not found') ||
            errorType.contains('user') ||
            errorType.contains('username')) {
          throw HttpException('credentials_invalid');
        }
        // Default to credentials invalid
        else {
          throw HttpException('credentials_invalid');
        }
      } catch (e) {
        if (e is HttpException) rethrow;
        throw HttpException('credentials_invalid');
      }
    }
  }

  // Employee Login
  static Future<LoginResponse> login(LoginRequest request) async {
    try {
      print('🔐 Attempting login for: ${request.employeeIdOrEmail}');
      final headers = await _getHeaders();
      final body = json.encode(request.toJson());

      print(
        '📤 Sending request to: ${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}',
      );
      print('📤 Request body: $body');

      final response = await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final responseData = _handleResponse(response);
      print('✅ Parsed response: $responseData');

      return LoginResponse.fromJson(responseData);
    } catch (e) {
      print('❌ Login error: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Invalid credentials');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Invalid credentials');
      } else if (e.toString().contains('password_invalid')) {
        throw Exception('password_invalid');
      } else if (e.toString().contains('credentials_invalid')) {
        throw Exception('credentials_invalid');
      } else {
        throw Exception('Invalid credentials');
      }
    }
  }

  // Get Employee Profile
  static Future<Employee> getEmployeeProfile(String employeeId) async {
    try {
      print('🔍 Fetching employee profile for ID: $employeeId');
      final headers = await _getHeaders(includeAuth: true);
      print('🔍 Headers: $headers');

      final url =
          '${ApiConstants.baseUrl}${ApiConstants.employeeProfileEndpoint}/$employeeId';
      print('🔍 API URL: $url');

      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

      final responseData = _handleResponse(response);
      print('🔍 Parsed response data: $responseData');

      final employee = Employee.fromJson(responseData);
      print('🔍 Employee object created: ${employee.toJson()}');

      return employee;
    } catch (e) {
      print('❌ Error fetching employee profile: $e');
      throw Exception('Failed to fetch employee profile: $e');
    }
  }

  // Get Employee Profile Details
  static Future<Employee> getEmployeeProfileDetails() async {
    try {
      print('🔍 Fetching employee profile details...');
      final headers = await _getHeaders(includeAuth: true);
      print('🔍 Headers: $headers');

      final url =
          '${ApiConstants.baseUrl}${ApiConstants.employeeProfileDetailsEndpoint}';
      print('🔍 API URL: $url');

      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

      final responseData = _handleResponse(response);
      print('🔍 Parsed response data: $responseData');

      final employee = Employee.fromJson(responseData);
      print('🔍 Employee profile details created: ${employee.toJson()}');

      return employee;
    } catch (e) {
      print('❌ Error fetching employee profile details: $e');
      throw Exception('Failed to fetch employee profile details: $e');
    }
  }

  // Generic GET request
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);

      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET request failed: $e');
    }
  }

  // Generic POST request
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final body = json.encode(data);

      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
        body: body,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('POST request failed: $e');
    }
  }

  // Generic PUT request
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final body = json.encode(data);

      final response = await _client.put(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
        body: body,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('PUT request failed: $e');
    }
  }

  // Generic DELETE request
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);

      final response = await _client.delete(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('DELETE request failed: $e');
    }
  }

  // Dispose client
  static void dispose() {
    _client.close();
  }
}
