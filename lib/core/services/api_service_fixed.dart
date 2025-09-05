import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../constants/api_constants.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/employee.dart';
import '../models/clock_in_request.dart';
import '../models/clock_out_request.dart';
import '../models/time_entry_response.dart';
import '../models/time_entry_status.dart';
import 'storage_service.dart';
import 'device_service.dart';

class ApiService {
  static http.Client? _client;

  static void initializeClient() {
    if (Platform.isAndroid || Platform.isIOS) {
      // Create a custom HttpClient for mobile platforms with proper SSL handling
      final httpClient = HttpClient();
      httpClient
          .badCertificateCallback = (X509Certificate cert, String host, int port) {
        // For production, we should validate certificates properly
        // But for now, we'll allow the connection to proceed
        print('🔒 SSL Certificate check for $host:$port');
        return true; // Allow all certificates for now - change this for production
      };

      _client = IOClient(httpClient);
    } else {
      _client = http.Client();
    }
  }

  static http.Client get httpClient {
    if (_client == null) {
      _client = http.Client();
    }
    return _client!;
  }

  // Get headers with authentication
  static Future<Map<String, String>> _getHeaders({
    bool includeAuth = false,
    bool includeDeviceMeta = false,
  }) async {
    final headers = {'Content-Type': ApiConstants.contentTypeJson};

    if (includeAuth) {
      final token = await StorageService.getToken();
      if (token != null) {
        headers[ApiConstants.authorizationHeader] =
            '${ApiConstants.bearerPrefix}$token';
      }
    }

    if (includeDeviceMeta) {
      try {
        final deviceInfo = await DeviceService.getDeviceInfo();
        final deviceId = deviceInfo['deviceId'];
        final deviceName = deviceInfo['deviceName'];
        final appVersion = deviceInfo['appVersion'];
        final platform = deviceInfo['platform'];

        if (deviceId != null && deviceId.isNotEmpty) {
          headers['X-Device-Id'] = deviceId;
        }
        if (deviceName != null && deviceName.isNotEmpty) {
          headers['X-Device-Name'] = deviceName;
        }
        if (appVersion != null && appVersion.isNotEmpty) {
          headers['X-App-Version'] = appVersion;
        }
        if (platform != null && platform.isNotEmpty) {
          headers['X-Platform'] = platform;
        }
      } catch (e) {
        // Best-effort; do not block request on meta failure
        print('⚠️ Failed to attach device meta headers: $e');
      }
    }

    return headers;
  }

  // Handle API response
  static dynamic _handleResponse(http.Response response) {
    print('🔍 Handling response: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final responseData = json.decode(response.body);
        print('✅ Successfully parsed JSON: $responseData');
        print('✅ JSON type: ${responseData.runtimeType}');
        if (responseData is List) {
          print('✅ JSON is a List with ${responseData.length} items');
          if (responseData.isNotEmpty) {
            print('✅ First item type: ${responseData.first.runtimeType}');
            if (responseData.first is Map) {
              print(
                '✅ First item keys: ${(responseData.first as Map).keys.toList()}',
              );
            }
          }
        }
        return responseData;
      } catch (e) {
        print('❌ JSON parsing error: $e');
        if (e.toString().contains('type \'String\' is not a subtype')) {
          throw HttpException('json_parsing_error');
        }
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
        // Check for clock-in/clock-out errors
        else if (errorMessage.contains('already clocked in') ||
            errorMessage.contains('currently clocked in')) {
          throw HttpException('already_clocked_in');
        }
        // Check for not clocked in errors
        else if (errorMessage.contains('not currently clocked in') ||
            errorMessage.contains('clock in first') ||
            errorMessage.contains('clock out') ||
            errorMessage.contains('time entry')) {
          throw HttpException('not_clocked_in');
        }
        // Check for device limit errors
        else if (errorMessage.contains('device limit') ||
            errorMessage.contains('multiple devices') ||
            errorMessage.contains('too many devices') ||
            errorMessage.contains('device not supported') ||
            errorMessage.contains('maximum devices') ||
            errorMessage.contains('device limit exceeded') ||
            errorMessage.contains('device count') ||
            errorMessage.contains('max devices') ||
            errorMessage.contains('device quota') ||
            errorMessage.contains('concurrent sessions') ||
            errorMessage.contains('session limit') ||
            errorMessage.contains('device registration') ||
            errorMessage.contains('not supported') ||
            errorMessage.contains('multiple device')) {
          throw HttpException('device_limit_exceeded');
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
      print('🔐 ========== LOGIN DEBUG START ==========');
      print('🔐 Attempting login for: ${request.employeeIdOrEmail}');
      print('🔐 Base URL: ${ApiConstants.baseUrl}');
      print('🔐 Login Endpoint: ${ApiConstants.loginEndpoint}');
      print(
        '🔐 Full URL: ${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}',
      );

      // Include device/app metadata headers for backend diagnostics
      final headers = await _getHeaders(includeDeviceMeta: true);
      print('🔐 Request Headers: $headers');

      final body = json.encode(request.toJson());
      print('🔐 Request Body: $body');
      print('🔐 Request Body (pretty): ${json.encode(request.toJson())}');

      // Test connectivity first
      print('🔐 Testing connectivity to server...');
      try {
        final connectivityTest = await httpClient
            .get(Uri.parse('${ApiConstants.baseUrl}/health'))
            .timeout(const Duration(seconds: 10));
        print('🔐 Connectivity test result: ${connectivityTest.statusCode}');
      } catch (e) {
        print('⚠️ Connectivity test failed (this might be normal): $e');
      }

      print('🔐 Sending login request...');
      final response = await httpClient
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      print('🔐 ========== SERVER RESPONSE ==========');
      print('🔐 Response Status Code: ${response.statusCode}');
      print('🔐 Response Headers: ${response.headers}');
      print('🔐 Response Body: ${response.body}');
      print('🔐 Response Body Length: ${response.body.length}');

      final responseData = _handleResponse(response);
      print('🔐 Parsed Response Data: $responseData');
      print('🔐 ========== LOGIN DEBUG END ==========');

      return LoginResponse.fromJson(responseData);
    } catch (e) {
      print('❌ Login error: $e');
      print('❌ Error type: ${e.runtimeType}');

      // Handle specific network errors
      if (e.toString().contains('TimeoutException')) {
        throw Exception(
          'Network timeout. Please check your internet connection.',
        );
      } else if (e.toString().contains('SocketException')) {
        throw Exception(
          'Network error. Please check your internet connection and try again.',
        );
      } else if (e.toString().contains('Failed host lookup')) {
        throw Exception(
          'Cannot connect to server. Please check your internet connection.',
        );
      } else if (e.toString().contains('HandshakeException')) {
        throw Exception(
          'SSL handshake failed. Please check your internet connection.',
        );
      } else if (e.toString().contains('CertificateException')) {
        throw Exception(
          'Certificate validation failed. Please check your internet connection.',
        );
      } else if (e.toString().contains('password_invalid')) {
        throw Exception('password_invalid');
      } else if (e.toString().contains('credentials_invalid')) {
        throw Exception('credentials_invalid');
      } else if (e.toString().contains('device_limit_exceeded')) {
        throw Exception('device_limit_exceeded');
      } else if (e.toString().contains('HttpException')) {
        // Re-throw HttpException as is to preserve the original error type
        rethrow;
      } else {
        // For production builds, provide more specific error messages
        if (e.toString().contains('Connection refused') ||
            e.toString().contains('Connection reset')) {
          throw Exception(
            'Unable to connect to server. Please check your internet connection and try again.',
          );
        } else {
          throw Exception(
            'Login failed. Please check your internet connection and try again.',
          );
        }
      }
    }
  }

  // Test server connectivity
  static Future<Map<String, dynamic>> testConnectivity() async {
    try {
      print('🌐 Testing connectivity to: ${ApiConstants.baseUrl}');

      final response = await httpClient
          .get(Uri.parse('${ApiConstants.baseUrl}/health'))
          .timeout(const Duration(seconds: 10));

      print('🌐 Connectivity test - Status: ${response.statusCode}');
      print('🌐 Connectivity test - Headers: ${response.headers}');
      print('🌐 Connectivity test - Body: ${response.body}');

      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'statusCode': response.statusCode,
        'headers': response.headers,
        'body': response.body,
      };
    } catch (e) {
      print('🌐 Connectivity test failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Dispose client
  static void dispose() {
    httpClient.close();
  }
}
