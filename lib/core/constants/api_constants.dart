class ApiConstants {
  // Base URL for production
  static const String baseUrl = 'https://api-hrms.pragva.in/api';

  // API Endpoints
  static const String loginEndpoint = '/employee/auth/login';
  static const String employeeProfileEndpoint = '/employee';
  static const String employeeProfileDetailsEndpoint = '/employee/profile';

  // Headers
  static const String contentTypeJson = 'application/json';
  static const String contentTypeMultipart = 'multipart/form-data';
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String employeeIdKey = 'employee_id';
  static const String userRoleKey = 'user_role';
}
