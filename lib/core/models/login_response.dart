import 'package:json_annotation/json_annotation.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  final bool success;
  final String? message;
  final String? token;
  final String? employeeId;
  final String? role;
  final String? firstName;
  final String? lastName;
  final String? email;

  const LoginResponse({
    required this.success,
    this.message,
    this.token,
    this.employeeId,
    this.role,
    this.firstName,
    this.lastName,
    this.email,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    print('📥 Parsing LoginResponse from JSON: $json');

    try {
      // Check if we have a success field
      bool success = json['success'] ?? false;

      // If no success field, determine success based on other indicators
      if (!success) {
        // Success if we have a token and the message contains "successful"
        final hasToken =
            json['token'] != null && json['token'].toString().isNotEmpty;
        final message = json['message']?.toString().toLowerCase() ?? '';
        final isSuccessfulMessage = message.contains('successful');

        success = hasToken && isSuccessfulMessage;
        print(
          '📥 Determined success: $success (hasToken: $hasToken, isSuccessfulMessage: $isSuccessfulMessage)',
        );
      }

      return LoginResponse(
        success: success,
        message: json['message'] ?? json['msg'] ?? json['error'],
        token: json['token'] ?? json['access_token'] ?? json['authToken'],
        employeeId:
            json['employeeId'] ??
            json['employee_id'] ??
            json['userId'] ??
            json['username'],
        role: json['role'] ?? json['userRole'] ?? json['user_type'],
        firstName: json['firstName'] ?? json['first_name'],
        lastName: json['lastName'] ?? json['last_name'],
        email: json['email'] ?? json['emailAddress'],
      );
    } catch (e) {
      print('❌ LoginResponse parsing error: $e');
      print('📥 Raw JSON: $json');

      // Fallback parsing for different API response formats
      final hasToken =
          json['token'] != null && json['token'].toString().isNotEmpty;
      final message = json['message']?.toString().toLowerCase() ?? '';
      final isSuccessfulMessage = message.contains('successful');

      return LoginResponse(
        success: hasToken && isSuccessfulMessage,
        message: json['message'] ?? json['msg'] ?? json['error'],
        token: json['token'] ?? json['access_token'] ?? json['authToken'],
        employeeId:
            json['employeeId'] ??
            json['employee_id'] ??
            json['userId'] ??
            json['username'],
        role: json['role'] ?? json['userRole'] ?? json['user_type'],
        firstName: json['firstName'] ?? json['first_name'],
        lastName: json['lastName'] ?? json['last_name'],
        email: json['email'] ?? json['emailAddress'],
      );
    }
  }

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}
