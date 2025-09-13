import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_routes.dart';
import 'core/services/theme_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/api_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/profile_image_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }

  // Preload theme before first frame to avoid light→dark flash
  final themeService = ThemeService();
  await themeService.initializeTheme();

  runApp(HrmsApp(themeService: themeService));
}

class HrmsApp extends StatefulWidget {
  final ThemeService themeService;

  const HrmsApp({super.key, required this.themeService});

  @override
  State<HrmsApp> createState() => _HrmsAppState();
}

class _HrmsAppState extends State<HrmsApp> with WidgetsBindingObserver {
  late ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeService = widget.themeService;
    AuthService.setThemeService(_themeService);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Theme is already initialized before runApp
    _initializeApiService();
    _initializeConnectivityService();
  }

  void _initializeApiService() {
    // Initialize the API service with proper HTTP client configuration
    ApiService.initializeClient();
  }

  void _initializeConnectivityService() {
    // Initialize connectivity monitoring
    ConnectivityService().initialize();
  }

  // Theme already initialized

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ConnectivityService().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // App is going to background - save current state but don't clear data
      print('📱 App paused - going to background');
    } else if (state == AppLifecycleState.resumed) {
      // App is coming back to foreground - restore state if needed
      print('📱 App resumed - coming back to foreground');
    } else if (state == AppLifecycleState.detached) {
      // App is being terminated - only clear sensitive data if user explicitly logged out
      // Don't clear authentication data as user should stay logged in
      print('📱 App being terminated - preserving authentication state');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeService>(
          create: (context) => _themeService,
        ),
        ChangeNotifierProvider<ProfileImageNotifier>(
          create: (context) => ProfileImageNotifier(),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'HRMS',
            debugShowCheckedModeBanner: false,
            theme: themeService.getThemeData(context),
            themeMode: themeService.themeMode,
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
