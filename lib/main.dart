import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_routes.dart';
import 'core/services/storage_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/api_service.dart';

void main() {
  runApp(const HrmsApp());
}

class HrmsApp extends StatefulWidget {
  const HrmsApp({super.key});

  @override
  State<HrmsApp> createState() => _HrmsAppState();
}

class _HrmsAppState extends State<HrmsApp> with WidgetsBindingObserver {
  late ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeService = ThemeService();
    AuthService.setThemeService(_themeService);
    _initializeTheme();
    _initializeApiService();
  }

  void _initializeApiService() {
    // Initialize the API service with proper HTTP client configuration
    ApiService.initializeClient();
  }

  Future<void> _initializeTheme() async {
    await _themeService.initializeTheme();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached) {
      // App is being terminated - clear sensitive data
      print('📱 App being terminated - clearing sensitive data');
      StorageService.clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeService>(
      create: (context) => _themeService,
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'HRMS',
            debugShowCheckedModeBanner: false,
            theme: themeService.getThemeData(context),
            themeMode: themeService.isAuthenticated
                ? themeService.themeMode
                : ThemeMode.light,
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
