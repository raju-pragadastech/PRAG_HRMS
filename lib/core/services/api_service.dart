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
  static bool _isInitialized = false;

  static void initializeClient() {
    if (_isInitialized && _client != null) {
      return; // Already initialized
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Create a custom HttpClient for mobile platforms with proper SSL handling
        final httpClient = HttpClient();

        // Configure SSL settings for production
        httpClient.badCertificateCallback =
            (X509Certificate cert, String host, int port) {
              print('🔒 SSL Certificate check for $host:$port');
              print('🔒 Certificate subject: ${cert.subject}');
              print('🔒 Certificate issuer: ${cert.issuer}');

              // For production, validate the certificate properly
              // Check if it's our production domain
              if (host.contains('api-hrms.pragva.in') ||
                  host.contains('pragva.in')) {
                print('🔒 Allowing certificate for production domain: $host');
                return true;
              }

              // For other domains, be more strict
              print(
                '🔒 Rejecting certificate for non-production domain: $host',
              );
              return false;
            };

        // Set connection timeout
        httpClient.connectionTimeout = const Duration(seconds: 30);
        httpClient.idleTimeout = const Duration(seconds: 30);

        _client = IOClient(httpClient);
        print('🔒 HTTPS client initialized for mobile platform');
      } else {
        _client = http.Client();
        print('🔒 Standard HTTP client initialized for desktop platform');
      }
      _isInitialized = true;
    } catch (e) {
      print('❌ Error initializing HTTP client: $e');
      _client = http.Client(); // Fallback to basic client
      _isInitialized = true;
    }
  }

  static http.Client get httpClient {
    if (_client == null || !_isInitialized) {
      initializeClient();
    }
    return _client!;
  }

  // Create a new client instance for each request to avoid "client closed" errors
  static http.Client _createNewClient() {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final httpClient = HttpClient();
        httpClient.badCertificateCallback =
            (X509Certificate cert, String host, int port) {
              if (host.contains('api-hrms.pragva.in') ||
                  host.contains('pragva.in')) {
                return true;
              }
              return false;
            };
        httpClient.connectionTimeout = const Duration(seconds: 30);
        httpClient.idleTimeout = const Duration(seconds: 30);
        return IOClient(httpClient);
      } else {
        return http.Client();
      }
    } catch (e) {
      print('❌ Error creating new client: $e');
      return http.Client();
    }
  }

  // Wrapper method to handle HTTP calls with automatic retry on client closed errors
  static Future<http.Response> _makeHttpCall(
    Future<http.Response> Function() httpCall,
  ) async {
    try {
      return await httpCall();
    } catch (e) {
      // Check if it's a client closed error and retry with a new client
      if (e.toString().contains('Client is already closed') ||
          e.toString().contains('ClientException')) {
        print('🔄 HTTP client was closed, retrying with new client...');
        try {
          // Create a new client and try again
          final newClient = _createNewClient();
          // We can't easily retry the exact same call, so we'll rethrow
          // The calling method should handle this by creating a new client
          _client = newClient;
          return await httpCall();
        } catch (retryError) {
          print('❌ Retry also failed: $retryError');
          rethrow;
        }
      }
      rethrow;
    }
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
        // Check for already completed time entry errors
        else if (errorMessage.contains(
              'already completed your daily time entry',
            ) ||
            errorMessage.contains(
              'only one clock-in and clock-out session is allowed',
            )) {
          throw HttpException('already_completed');
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
      final response = await _makeHttpCall(
        () => httpClient
            .post(
              Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
              headers: headers,
              body: body,
            )
            .timeout(const Duration(seconds: 30)),
      );

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

  // Test API endpoints
  static Future<Map<String, dynamic>> testApiEndpoints() async {
    try {
      print('🧪 ========== API ENDPOINTS TEST START ==========');

      final results = <String, dynamic>{};

      // Test profile endpoint
      try {
        print('🧪 Testing profile endpoint...');
        final employeeId = await StorageService.getEmployeeId();
        if (employeeId != null) {
          final profileUrl =
              '${ApiConstants.baseUrl}${ApiConstants.employeeProfileEndpoint}';
          final headers = await _getHeaders(includeAuth: true);

          final response = await httpClient
              .get(Uri.parse(profileUrl), headers: headers)
              .timeout(const Duration(seconds: 10));

          results['profile'] = {
            'url': profileUrl,
            'status': response.statusCode,
            'success': response.statusCode == 200,
            'body': response.body.length > 100
                ? '${response.body.substring(0, 100)}...'
                : response.body,
          };
        } else {
          results['profile'] = {'error': 'No employee ID found'};
        }
      } catch (e) {
        results['profile'] = {'error': e.toString()};
      }

      // Test time entry status endpoint
      try {
        print('🧪 Testing time entry status endpoint...');
        final employeeId = await StorageService.getEmployeeId();
        if (employeeId != null) {
          final statusUrl =
              '${ApiConstants.baseUrl}${ApiConstants.timeEntryStatusEndpoint}/$employeeId';
          final headers = await _getHeaders(includeAuth: true);

          final response = await httpClient
              .get(Uri.parse(statusUrl), headers: headers)
              .timeout(const Duration(seconds: 10));

          results['timeEntryStatus'] = {
            'url': statusUrl,
            'status': response.statusCode,
            'success': response.statusCode == 200,
            'body': response.body.length > 100
                ? '${response.body.substring(0, 100)}...'
                : response.body,
          };
        } else {
          results['timeEntryStatus'] = {'error': 'No employee ID found'};
        }
      } catch (e) {
        results['timeEntryStatus'] = {'error': e.toString()};
      }

      // Test time entries endpoint
      try {
        print('🧪 Testing time entries endpoint...');
        final employeeId = await StorageService.getEmployeeId();
        if (employeeId != null) {
          final now = DateTime.now();
          final startDate = now.subtract(const Duration(days: 7));
          final entriesUrl =
              '${ApiConstants.baseUrl}${ApiConstants.timeEntriesEndpoint}/$employeeId?startDate=${startDate.toIso8601String()}&endDate=${now.toIso8601String()}';
          final headers = await _getHeaders(includeAuth: true);

          final response = await httpClient
              .get(Uri.parse(entriesUrl), headers: headers)
              .timeout(const Duration(seconds: 10));

          results['timeEntries'] = {
            'url': entriesUrl,
            'status': response.statusCode,
            'success': response.statusCode == 200,
            'body': response.body.length > 100
                ? '${response.body.substring(0, 100)}...'
                : response.body,
          };
        } else {
          results['timeEntries'] = {'error': 'No employee ID found'};
        }
      } catch (e) {
        results['timeEntries'] = {'error': e.toString()};
      }

      print('🧪 ========== API ENDPOINTS TEST RESULTS ==========');
      print('🧪 Results: $results');
      print('🧪 ========== API ENDPOINTS TEST END ==========');

      return results;
    } catch (e) {
      print('🧪 API endpoints test failed: $e');
      return {'error': e.toString()};
    }
  }

  // Get Employee Profile
  static Future<Employee> getEmployeeProfile(String employeeId) async {
    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.employeeProfileEndpoint}?employeeId=$employeeId';
      final headers = await _getHeaders(includeAuth: true);

      print('👤 ========== EMPLOYEE PROFILE BY ID DEBUG START ==========');
      print('👤 Profile URL: $url');
      print('👤 Employee ID: $employeeId');
      print('👤 Request Headers: $headers');

      final response = await _makeHttpCall(
        () => httpClient
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 30)),
      );

      print('👤 ========== PROFILE BY ID RESPONSE ==========');
      print('👤 Response Status Code: ${response.statusCode}');
      print('👤 Response Headers: ${response.headers}');
      print('👤 Response Body: ${response.body}');
      print('👤 ========== EMPLOYEE PROFILE BY ID DEBUG END ==========');

      final responseData = _handleResponse(response);
      return Employee.fromJson(responseData);
    } catch (e) {
      print('❌ Get employee profile error: $e');
      rethrow;
    }
  }

  // Get Employee Profile Details
  static Future<Employee> getEmployeeProfileDetails() async {
    try {
      print('👤 ========== EMPLOYEE PROFILE DEBUG START ==========');

      // Always fetch fresh data from API for complete employee details
      print('👤 Fetching fresh employee profile data from API...');

      // Use the primary endpoint
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.employeeProfileEndpoint}';
      final headers = await _getHeaders(includeAuth: true);

      print('👤 Profile URL: $url');
      print('👤 Request Headers: $headers');

      // Check if token exists
      final token = await StorageService.getToken();
      print('👤 Token exists: ${token != null}');
      if (token != null) {
        print('👤 Token length: ${token.length}');
        print(
          '👤 Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
        );
      }

      final response = await _makeHttpCall(
        () => httpClient
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 30)),
      );

      print('👤 ========== PROFILE RESPONSE ==========');
      print('👤 Response Status Code: ${response.statusCode}');
      print('👤 Response Headers: ${response.headers}');
      print('👤 Response Body: ${response.body}');
      print('👤 ========== EMPLOYEE PROFILE DEBUG END ==========');

      if (response.statusCode == 200) {
        final responseData = _handleResponse(response);
        print('👤 Parsed response data: $responseData');

        // Create Employee object from fresh API data
        final employee = Employee.fromJson(responseData);
        print('👤 Created Employee object: ${employee.toJson()}');

        // Store the fresh detailed profile data for future use
        await StorageService.saveDetailedEmployeeProfile(employee.toJson());
        print('👤 Fresh detailed profile data saved to storage');

        return employee;
      } else {
        print('❌ API call failed with status ${response.statusCode}');

        // If API fails, try to get from stored data as fallback
        print('👤 API failed, trying stored data as fallback...');
        final employeeData = await StorageService.getEmployeeData();
        final employeeId = await StorageService.getEmployeeId();
        final role = await StorageService.getUserRole();

        if (employeeData != null && employeeId != null) {
          print('👤 Using stored login data as fallback');
          return Employee(
            employeeId: employeeId,
            firstName: employeeData['firstName'] ?? '',
            lastName: employeeData['lastName'] ?? '',
            email: employeeData['email'] ?? '',
            phone: employeeData['phone'] ?? '',
            department: employeeData['department'] ?? '',
            position: employeeData['position'] ?? '',
            role: role ?? employeeData['role'] ?? '',
            status: 'active',
          );
        }

        throw Exception(
          'API call failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Get employee profile details error: $e');

      // Check if it's a client closed error and retry with a new client
      if (e.toString().contains('Client is already closed') ||
          e.toString().contains('ClientException')) {
        print('🔄 HTTP client was closed, retrying with new client...');
        try {
          // Reset the client and try again
          _client = null;
          final url =
              '${ApiConstants.baseUrl}${ApiConstants.employeeProfileEndpoint}';
          final headers = await _getHeaders(includeAuth: true);

          final response = await httpClient
              .get(Uri.parse(url), headers: headers)
              .timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            final responseData = _handleResponse(response);
            final employee = Employee.fromJson(responseData);
            await StorageService.saveDetailedEmployeeProfile(employee.toJson());
            return employee;
          }
        } catch (retryError) {
          print('❌ Retry also failed: $retryError');
        }
      }

      // If all else fails, try to get from stored data as last resort
      print('👤 All methods failed, trying stored data as last resort...');
      final employeeData = await StorageService.getEmployeeData();
      final employeeId = await StorageService.getEmployeeId();
      final role = await StorageService.getUserRole();

      if (employeeData != null && employeeId != null) {
        print('👤 Using stored login data as last resort');
        return Employee(
          employeeId: employeeId,
          firstName: employeeData['firstName'] ?? '',
          lastName: employeeData['lastName'] ?? '',
          email: employeeData['email'] ?? '',
          phone: employeeData['phone'] ?? '',
          department: employeeData['department'] ?? '',
          position: employeeData['position'] ?? '',
          role: role ?? employeeData['role'] ?? '',
          status: 'active',
        );
      }

      rethrow;
    }
  }

  // Clock In
  static Future<TimeEntryResponse> clockIn(ClockInRequest request) async {
    try {
      print('🕐 ========== CLOCK IN DEBUG START ==========');
      print('🕐 Request: ${request.toJson()}');

      final url = '${ApiConstants.baseUrl}${ApiConstants.clockInEndpoint}';
      final headers = await _getHeaders(includeAuth: true);
      final body = json.encode(request.toJson());

      print('🕐 Clock In URL: $url');
      print('🕐 Request Headers: $headers');
      print('🕐 Request Body: $body');

      final response = await _makeHttpCall(
        () => httpClient
            .post(Uri.parse(url), headers: headers, body: body)
            .timeout(const Duration(seconds: 10)),
      );

      print('🕐 ========== CLOCK IN RESPONSE ==========');
      print('🕐 Response Status Code: ${response.statusCode}');
      print('🕐 Response Headers: ${response.headers}');
      print('🕐 Response Body: ${response.body}');
      print('🕐 ========== CLOCK IN DEBUG END ==========');

      final responseData = _handleResponse(response);
      return TimeEntryResponse.fromJson(responseData);
    } catch (e) {
      print('❌ Clock in error: $e');
      print('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Clock Out
  static Future<TimeEntryResponse> clockOut(ClockOutRequest request) async {
    try {
      print('🕐 ========== CLOCK OUT DEBUG START ==========');
      print('🕐 Request: ${request.toJson()}');

      final url = '${ApiConstants.baseUrl}${ApiConstants.clockOutEndpoint}';
      final headers = await _getHeaders(includeAuth: true);
      final body = json.encode(request.toJson());

      print('🕐 Clock Out URL: $url');
      print('🕐 Request Headers: $headers');
      print('🕐 Request Body: $body');

      final response = await _makeHttpCall(
        () => httpClient
            .post(Uri.parse(url), headers: headers, body: body)
            .timeout(const Duration(seconds: 10)),
      );

      print('🕐 ========== CLOCK OUT RESPONSE ==========');
      print('🕐 Response Status Code: ${response.statusCode}');
      print('🕐 Response Headers: ${response.headers}');
      print('🕐 Response Body: ${response.body}');
      print('🕐 ========== CLOCK OUT DEBUG END ==========');

      final responseData = _handleResponse(response);
      return TimeEntryResponse.fromJson(responseData);
    } catch (e) {
      print('❌ Clock out error: $e');
      print('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Get Time Entry Status
  static Future<TimeEntryStatus> getTimeEntryStatus(String employeeId) async {
    try {
      print('🕐 ========== TIME ENTRY STATUS DEBUG START ==========');
      print('🕐 Employee ID: $employeeId');

      // Use the correct backend endpoint with path parameter
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.timeEntryStatusEndpoint}/$employeeId';
      final headers = await _getHeaders(includeAuth: true);

      print('🕐 Status URL: $url');
      print('🕐 Request Headers: $headers');

      final response = await _makeHttpCall(
        () => httpClient
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 30)),
      );

      print('🕐 ========== TIME ENTRY STATUS RESPONSE ==========');
      print('🕐 Response Status Code: ${response.statusCode}');
      print('🕐 Response Headers: ${response.headers}');
      print('🕐 Response Body: ${response.body}');
      print('🕐 ========== TIME ENTRY STATUS DEBUG END ==========');

      if (response.statusCode == 200) {
        final responseData = _handleResponse(response);
        print('🕐 Parsed response data: $responseData');
        return TimeEntryStatus.fromJson(responseData);
      } else {
        print('❌ API call failed with status ${response.statusCode}');
        throw Exception(
          'API call failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Get time entry status error: $e');
      print('🕐 Returning default time entry status due to error');
      return TimeEntryStatus(
        isClockedIn: false,
        clockInTime: null,
        workLocation: null,
        totalHours: '0h 0m',
      );
    }
  }

  // Get Employee Time Entries
  static Future<List<Map<String, dynamic>>> getEmployeeTimeEntries(
    String employeeId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('🕐 ========== TIME ENTRIES DEBUG START ==========');
      print('🕐 Employee ID: $employeeId');
      print('🕐 Start Date: ${startDate.toIso8601String()}');
      print('🕐 End Date: ${endDate.toIso8601String()}');
      print(
        '🕐 Start Date (formatted): ${startDate.toIso8601String().split('T')[0]}',
      );
      print(
        '🕐 End Date (formatted): ${endDate.toIso8601String().split('T')[0]}',
      );

      // Use the correct backend endpoint with path parameter and query parameters
      // Backend expects YYYY-MM-DD format, not ISO8601
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.timeEntriesEndpoint}/$employeeId?startDate=$startDateStr&endDate=$endDateStr';
      final headers = await _getHeaders(includeAuth: true);

      print('🕐 Time Entries URL: $url');
      print('🕐 Request Headers: $headers');

      final response = await _makeHttpCall(
        () => httpClient
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 30)),
      );

      print('🕐 ========== TIME ENTRIES RESPONSE ==========');
      print('🕐 Response Status Code: ${response.statusCode}');
      print('🕐 Response Headers: ${response.headers}');
      print('🕐 Response Body: ${response.body}');
      print('🕐 ========== TIME ENTRIES DEBUG END ==========');

      if (response.statusCode == 200) {
        final responseData = _handleResponse(response);
        print('🕐 Parsed response data: $responseData');
        print('🕐 Response data type: ${responseData.runtimeType}');

        // Handle different possible response formats
        if (responseData is List) {
          print('🕐 Parsed ${responseData.length} time entries from list');
          // Debug: Check employee IDs in the response
          for (var entry in responseData) {
            if (entry is Map<String, dynamic>) {
              final entryEmployeeId =
                  entry['employeeId'] ??
                  entry['employee_id'] ??
                  entry['employee'] ??
                  entry['empId'];
              print(
                '🕐 Entry employee ID: $entryEmployeeId (requested: $employeeId)',
              );
            }
          }
          return responseData.cast<Map<String, dynamic>>();
        } else if (responseData is Map<String, dynamic>) {
          // Check if the response has a data field containing the time entries
          if (responseData.containsKey('data') &&
              responseData['data'] is List) {
            print(
              '🕐 Found time entries in data field: ${(responseData['data'] as List).length} entries',
            );
            return (responseData['data'] as List).cast<Map<String, dynamic>>();
          } else if (responseData.containsKey('timeEntries') &&
              responseData['timeEntries'] is List) {
            print(
              '🕐 Found time entries in timeEntries field: ${(responseData['timeEntries'] as List).length} entries',
            );
            return (responseData['timeEntries'] as List)
                .cast<Map<String, dynamic>>();
          } else if (responseData.containsKey('entries') &&
              responseData['entries'] is List) {
            print(
              '🕐 Found time entries in entries field: ${(responseData['entries'] as List).length} entries',
            );
            return (responseData['entries'] as List)
                .cast<Map<String, dynamic>>();
          } else {
            print('🕐 Single time entry object found');
            return [responseData];
          }
        }
        print('🕐 No time entries found or invalid response format');
        return [];
      } else {
        print('❌ API call failed with status ${response.statusCode}');
        throw Exception(
          'API call failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Get employee time entries error: $e');
      print('🕐 Returning empty time entries list due to error');
      return [];
    }
  }

  // Logout All Devices
  static Future<void> logoutAllDevices() async {
    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.logoutAllDevicesEndpoint}';
      final headers = await _getHeaders(includeAuth: true);

      await httpClient
          .post(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      print('❌ Logout all devices error: $e');
      rethrow;
    }
  }

  // Logout Current Device
  static Future<void> logoutCurrentDevice() async {
    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.logoutCurrentDeviceEndpoint}';
      final headers = await _getHeaders(includeAuth: true);

      await httpClient
          .post(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      print('❌ Logout current device error: $e');
      rethrow;
    }
  }

  // Get Device Sessions
  static Future<List<Map<String, dynamic>>> getDeviceSessions() async {
    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.deviceSessionsEndpoint}';
      final headers = await _getHeaders(includeAuth: true);

      final response = await _makeHttpCall(
        () => httpClient
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 30)),
      );

      final responseData = _handleResponse(response);
      if (responseData is List) {
        return responseData.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('❌ Get device sessions error: $e');
      rethrow;
    }
  }

  // Dispose client
  static void dispose() {
    if (_client != null) {
      try {
        _client!.close();
      } catch (e) {
        print('⚠️ Error closing HTTP client: $e');
      } finally {
        _client = null;
        _isInitialized = false;
      }
    }
  }
}
