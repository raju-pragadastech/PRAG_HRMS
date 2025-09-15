class ApiConstants {
  // Base URL for production
  static const String baseUrl = 'https://api-hrms.pragva.in/api';

  // API Endpoints
  static const String loginEndpoint = '/employee/auth/login';
  static const String logoutAllDevicesEndpoint =
      '/employee/auth/logout-all-devices';
  static const String deviceSessionsEndpoint = '/employee/auth/device-sessions';
  static const String logoutCurrentDeviceEndpoint =
      '/employee/auth/logout-current-device';

  //employee profile credentials
  static const String employeeProfileEndpoint = '/employee/profile';
  static const String employeeProfileDetailsEndpoint =
      '/employee/profile/details';

  // Time Entry Endpoints - Updated to match actual backend structure
  static const String clockInEndpoint = '/time-entry/clock-in';
  static const String clockOutEndpoint = '/time-entry/clock-out';
  static const String clockInConfirmEndpoint = '/time-entry/clock-in-confirm';
  static const String clockOutConfirmEndpoint = '/time-entry/clock-out-confirm';

  // Time Entry Status and Data Endpoints
  static const String timeEntryStatusEndpoint = '/time-entry/status';
  static const String timeEntriesEndpoint = '/time-entry/employee';
  static const String isClockedInEndpoint = '/time-entry/is-clocked-in';
  static const String currentlyClockedInEndpoint =
      '/time-entry/currently-clocked-in';
  static const String debugStatusEndpoint = '/time-entry/debug-status';
  static const String userActionRequirementsEndpoint =
      '/time-entry/user-action-requirements';
  static const String dailyTimeEntriesEndpoint = '/time-entry/daily';
  static const String dailyAnalyticsEndpoint = '/time-entry/analytics/daily';

  // Leave Management Endpoints
  static const String leaveRequestsEndpoint = '/leave-requests';
  static const String leaveRequestsEmployeeEndpoint =
      '/leave-requests/employee';

  // Expenses Endpoints
  static const String expensesEndpoint = '/expenses';
  static const String expensesEmployeeEndpoint = '/expenses/employee';

  // Password Management Endpoints
  static const String changePasswordEndpoint = '/employee/change-password';
  static const String forgotPasswordEndpoint = '/employee/forgot-password';
  static const String resetPasswordEndpoint = '/employee/reset-password';

  // Headers
  static const String contentTypeJson = 'application/json';
  static const String contentTypeMultipart = 'multipart/form-data';
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String employeeIdKey = 'employee_id';
  static const String userRoleKey = 'user_role';
  static const String deviceIdKey = 'device_id';
  static const String deviceNameKey = 'device_name';
}
