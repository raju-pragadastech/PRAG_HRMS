import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/employee/screens/employee_profile_screen.dart';
import '../../features/attendance/screens/attendance_screen.dart';
import '../../features/leave/screens/leave_screen.dart';
import '../../features/leave/screens/enhanced_leave_screen.dart';
import '../../features/services/screens/services_screen.dart';
import '../../features/announcements/screens/announcements_screen.dart';
import '../../features/support/screens/support_screen.dart';
import '../../features/debug/debug_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String employeeProfile = '/employee-profile';
  static const String attendance = '/attendance';
  static const String leave = '/leave';
  static const String enhancedLeave = '/enhanced-leave';
  static const String services = '/services';
  static const String announcements = '/announcements';
  static const String support = '/support';
  static const String debug = '/debug';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    home: (context) => const HomeScreen(),
    dashboard: (context) => const DashboardScreen(),
    employeeProfile: (context) => const EmployeeProfileScreen(),
    attendance: (context) => const AttendanceScreen(),
    leave: (context) => const LeaveScreen(),
    enhancedLeave: (context) => const EnhancedLeaveScreen(isHR: true),
    services: (context) => const ServicesScreen(),
    announcements: (context) => const AnnouncementsScreen(),
    support: (context) => const SupportScreen(),
    debug: (context) => const DebugScreen(),
  };
}
