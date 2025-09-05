import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'storage_service.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Default to light theme
  bool _isAuthenticated = false;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  bool get isLightMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.light;
    }
    return _themeMode == ThemeMode.light;
  }

  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  // Initialize theme from storage
  Future<void> initializeTheme() async {
    try {
      // Always start with light theme before login
      _themeMode = ThemeMode.light;
      _isAuthenticated = false;
      notifyListeners();

      // Check if user is authenticated
      final isAuthenticated = await StorageService.isLoggedIn();
      if (isAuthenticated) {
        _isAuthenticated = true;
        // Load saved theme only if user is authenticated
        final savedTheme = await StorageService.getThemeMode();
        if (savedTheme != null) {
          _themeMode = _getThemeModeFromString(savedTheme);
        }
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error initializing theme: $e');
      // Fallback to light theme
      _themeMode = ThemeMode.light;
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  // Set theme mode (only works when authenticated)
  Future<void> setThemeMode(ThemeMode mode) async {
    if (!_isAuthenticated) {
      print('⚠️ Theme changes are only allowed after login');
      return;
    }

    _themeMode = mode;
    notifyListeners();

    try {
      await StorageService.saveThemeMode(themeModeString);
      print('🎨 Theme mode saved: $themeModeString');
    } catch (e) {
      print('❌ Error saving theme mode: $e');
    }
  }

  // Set theme by string
  Future<void> setThemeByString(String theme) async {
    final mode = _getThemeModeFromString(theme);
    await setThemeMode(mode);
  }

  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  // Set authentication status
  void setAuthenticated(bool isAuthenticated) {
    _isAuthenticated = isAuthenticated;
    if (!isAuthenticated) {
      // Reset to light theme when logged out
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  // Get authentication status
  bool get isAuthenticated => _isAuthenticated;

  // Force light theme (for pre-login screens)
  void forceLightTheme() {
    _themeMode = ThemeMode.light;
    notifyListeners();
  }

  // Get theme mode from string
  ThemeMode _getThemeModeFromString(String theme) {
    switch (theme.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  // Get theme data based on current mode
  ThemeData getThemeData(BuildContext context) {
    final brightness = isDarkMode ? Brightness.dark : Brightness.light;

    if (brightness == Brightness.dark) {
      return _getDarkTheme();
    } else {
      return _getLightTheme();
    }
  }

  // Light theme configuration
  ThemeData _getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1), // Indigo-500
            brightness: Brightness.light,
          ).copyWith(
            // Enhanced light theme colors
            primary: const Color(0xFF6366F1), // Indigo-500
            onPrimary: Colors.white,
            secondary: const Color(0xFF8B5CF6), // Violet-500
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: const Color(0xFF1A202C), // Dark text on light surface
            background: const Color(0xFFF7FAFC), // Very light background
            onBackground: const Color(0xFF1A202C), // Dark text
            surfaceContainerHighest: const Color(
              0xFFF1F5F9,
            ), // Elevated surfaces
            outline: const Color(0xFFE2E8F0), // Subtle borders
            outlineVariant: const Color(0xFFF1F5F9), // Very subtle borders
            error: const Color(0xFFEF4444), // Red-500
            onError: Colors.white,
            shadow: Colors.black.withOpacity(0.1),
          ),
      scaffoldBackgroundColor: const Color(0xFFF7FAFC),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFFE2E8F0).withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF6366F1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF6366F1),
          side: const BorderSide(color: Color(0xFF6366F1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF4A5568)),
        hintStyle: const TextStyle(color: Color(0xFF718096)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFF1A202C),
        iconColor: Color(0xFF4A5568),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF6366F1),
        unselectedItemColor: Color(0xFF718096),
        type: BottomNavigationBarType.fixed,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF1A202C),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: Color(0xFF4A5568),
          fontSize: 16,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A202C),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Dark theme configuration
  ThemeData _getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1), // Indigo-500
            brightness: Brightness.dark,
          ).copyWith(
            // Enhanced dark theme colors
            primary: const Color(0xFF6366F1), // Indigo-500
            onPrimary: Colors.white,
            secondary: const Color(0xFF8B5CF6), // Violet-500
            onSecondary: Colors.white,
            surface: const Color(0xFF1E1E2E), // Dark surface
            onSurface: const Color(0xFFE2E8F0), // Light text on dark surface
            background: const Color(0xFF0F0F23), // Very dark background
            onBackground: const Color(0xFFE2E8F0), // Light text
            surfaceContainerHighest: const Color(
              0xFF2D2D3A,
            ), // Elevated surfaces
            outline: const Color(0xFF4A5568), // Subtle borders
            outlineVariant: const Color(0xFF2D3748), // Very subtle borders
            error: const Color(0xFFEF4444), // Red-500
            onError: Colors.white,
            shadow: Colors.black.withOpacity(0.3),
          ),
      scaffoldBackgroundColor: const Color(0xFF0F0F23),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E2E),
        foregroundColor: const Color(0xFFE2E8F0),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E2E),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF2D3748).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF6366F1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF6366F1),
          side: const BorderSide(color: Color(0xFF6366F1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D2D3A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A5568)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A5568)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFFA0AEC0)),
        hintStyle: const TextStyle(color: Color(0xFF718096)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2D3748),
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFFE2E8F0),
        iconColor: Color(0xFFA0AEC0),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E2E),
        selectedItemColor: Color(0xFF6366F1),
        unselectedItemColor: Color(0xFF718096),
        type: BottomNavigationBarType.fixed,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF1E1E2E),
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E2E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: Color(0xFFA0AEC0),
          fontSize: 16,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2D2D3A),
        contentTextStyle: const TextStyle(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
