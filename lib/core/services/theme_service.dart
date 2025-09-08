import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'storage_service.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Default to light theme
  bool _isAuthenticated = false;

  ThemeMode get themeMode => _themeMode;

  // Get initial theme mode synchronously (for splash screen)
  ThemeMode get initialThemeMode {
    // This will be updated when initializeTheme() is called
    return _themeMode;
  }

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
      // Check if user is authenticated first
      final isAuthenticated = await StorageService.isLoggedIn();
      _isAuthenticated = isAuthenticated;

      if (isAuthenticated) {
        // Load saved theme if user is authenticated
        final savedTheme = await StorageService.getThemeMode();
        if (savedTheme != null) {
          _themeMode = _getThemeModeFromString(savedTheme);
          print('🎨 Loaded saved theme: $savedTheme');
        } else {
          _themeMode = ThemeMode.light; // Default to light if no saved theme
          print('🎨 No saved theme, using light mode');
        }
      } else {
        // Default to light theme for unauthenticated users
        _themeMode = ThemeMode.light;
        print('🎨 User not authenticated, using light mode');
      }
      notifyListeners();
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
    // Don't reset theme when logging out - keep user's theme preference
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
      elevatedButtonTheme: const ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(Color(0xFFBB86FC)),
          foregroundColor: MaterialStatePropertyAll(Color(0xFF000000)),
          elevation: MaterialStatePropertyAll(1),
          shadowColor: MaterialStatePropertyAll(Color(0xFF000000)),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          padding: MaterialStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStatePropertyAll(Color(0xFFBB86FC)),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStatePropertyAll(
            Color.fromARGB(255, 109, 15, 224),
          ),
          side: MaterialStatePropertyAll(
            BorderSide(color: Color.fromARGB(255, 109, 15, 224)),
          ),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
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

  // Pure Black Dark theme configuration
  ThemeData _getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        // Pure black theme colors
        primary: Color(0xFFFFFFFF), // White accent
        onPrimary: Color(0xFF000000), // Black text on white
        secondary: Color(0xFFFFFFFF), // White accent
        onSecondary: Color(0xFF000000), // Black text on white
        surface: Color(0xFF000000), // Pure black surface
        onSurface: Color(0xFFFFFFFF), // White text on surface
        background: Color(0xFF000000), // Pure black background
        onBackground: Color(0xFFFFFFFF), // White text on background
        error: Color(0xFFFF0000), // Red error
        onError: Color(0xFFFFFFFF), // White text on error
        surfaceContainerHighest: Color(0xFF000000), // Pure black elevated
        outline: Color(0xFF333333), // Dark borders
        outlineVariant: Color(0xFF000000), // Pure black borders
        shadow: Color(0xFF000000), // Black shadows
        scrim: Color(0xFF000000), // Black scrim
        inverseSurface: Color(0xFFFFFFFF), // White inverse surface
        onInverseSurface: Color(0xFF000000), // Black text on inverse surface
        inversePrimary: Color(0xFF000000), // Black inverse primary
        surfaceTint: Color(0xFFFFFFFF), // White surface tint
        tertiary: Color(0xFFFFFFFF), // White tertiary
        onTertiary: Color(0xFF000000), // Black text on tertiary
        surfaceVariant: Color(0xFF000000), // Pure black surface variant
        onSurfaceVariant: Color(0xFFFFFFFF), // White text on surface variant
        primaryContainer: Color(0xFF000000), // Pure black primary container
        onPrimaryContainer: Color(
          0xFFFFFFFF,
        ), // White text on primary container
        secondaryContainer: Color(0xFF000000), // Pure black secondary container
        onSecondaryContainer: Color(
          0xFFFFFFFF,
        ), // White text on secondary container
        tertiaryContainer: Color(0xFF000000), // Pure black tertiary container
        onTertiaryContainer: Color(
          0xFFFFFFFF,
        ), // White text on tertiary container
        errorContainer: Color(0xFF000000), // Pure black error container
        onErrorContainer: Color(0xFFFFFFFF), // White text on error container
      ),
      // Force pure black theme
      scaffoldBackgroundColor: const Color(0xFF000000),
      cardColor: const Color(0xFF000000),
      canvasColor: const Color(0xFF000000),
      primaryColor: const Color(0xFFFFFFFF),
      primaryColorDark: const Color(0xFFFFFFFF),
      primaryColorLight: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFF333333),
      // Force all icons to be white
      iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
      primaryIconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000000), // Pure black app bar
        foregroundColor: Color(0xFFFFFFFF), // White text and icons
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
        iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF000000), // Pure black card
        elevation: 0, // No elevation
        shadowColor: Color(0xFF000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: EdgeInsets.all(8),
      ),
      elevatedButtonTheme: const ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(Color(0xFFBB86FC)),
          foregroundColor: MaterialStatePropertyAll(Color(0xFF000000)),
          elevation: MaterialStatePropertyAll(1),
          shadowColor: MaterialStatePropertyAll(Color(0xFF000000)),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          padding: MaterialStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStatePropertyAll(
            Color.fromARGB(255, 142, 57, 247),
          ),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStatePropertyAll(
            Color.fromARGB(255, 123, 50, 212),
          ),
          side: MaterialStatePropertyAll(
            BorderSide(color: Color.fromARGB(255, 139, 79, 212)),
          ),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1E1E1E), // Android dark surface
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(4),
          ), // Android standard radius
          borderSide: BorderSide(color: Color(0xFF424242), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: Color(0xFF424242), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 131, 78, 196),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: Color(0xFFCF6679), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: Color(0xFFCF6679), width: 2),
        ),
        labelStyle: TextStyle(
          color: Color(0xFFCAC4D0), // Android label color
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        hintStyle: TextStyle(
          color: Color(0xFFCAC4D0), // Android hint color
          fontSize: 14,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12, // Android standard padding
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242), // Android dark divider
        thickness: 0.5,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFFFFFFFF), // White text
        iconColor: Color(0xFFFFFFFF), // White icons
        tileColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF000000), // Pure black
        selectedItemColor: Color(0xFFFFFFFF), // White selected
        unselectedItemColor: Color(0xFFFFFFFF), // White unselected
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF000000), // Pure black
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(
          0xFF1E1E1E,
        ), // Light black for better visibility
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titleTextStyle: const TextStyle(
          color: Colors.white, // Pure white text
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white, // Pure white text
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF000000), // Pure black
        contentTextStyle: const TextStyle(
          color: Colors.white, // Pure white text
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      // Pure white text theme for dark backgrounds
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Colors.white, // Pure white
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: TextStyle(
          color: Colors.white, // Pure white
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          color: Colors.white, // Pure white
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          color: Colors.white, // Pure white
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          color: Colors.white, // Pure white
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        headlineSmall: TextStyle(
          color: Colors.white, // Pure white
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: TextStyle(
          color: Colors.white, // Pure white
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: Colors.white, // Pure white
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: Colors.white, // Pure white
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: Colors.white, // Pure white
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: Colors.white, // Pure white
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: Colors.white, // Pure white for all text
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: Colors.white, // Pure white
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: Colors.white, // Pure white
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: Colors.white, // Pure white
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      // Android switch theme for dark mode
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF6366F1); // Blue accent
          }
          return const Color(0xFF666666); // Android muted when unselected
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(
              0xFF6366F1,
            ).withOpacity(0.3); // Blue with opacity
          }
          return const Color(0xFF333333); // Android dark track
        }),
      ),
      // Android slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF6366F1),
        inactiveTrackColor: const Color(0xFF333333),
        thumbColor: const Color(0xFF6366F1),
        overlayColor: const Color(0xFF6366F1).withOpacity(0.2),
        trackHeight: 3.0, // Android standard track height
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
    );
  }
}
