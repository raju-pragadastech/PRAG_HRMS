import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DeviceService {
  static String? _deviceId;
  static String? _deviceName;
  static String? _appVersion;

  /// Get unique device identifier
  static Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Use Android ID as base and add some randomness
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // Use identifierForVendor as base
        deviceId = iosInfo.identifierForVendor ?? 'unknown-ios-device';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceId = windowsInfo.deviceId;
      } else if (Platform.isMacOS) {
        // For macOS, use a combination of platform and timestamp
        deviceId = 'macos-${DateTime.now().millisecondsSinceEpoch}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceId = linuxInfo.machineId ?? 'unknown-linux-device';
      } else {
        // Fallback for other platforms
        deviceId = 'unknown-platform-${DateTime.now().millisecondsSinceEpoch}';
      }

      // Create a hash of the device ID for privacy
      final bytes = utf8.encode(deviceId);
      final digest = sha256.convert(bytes);
      _deviceId = digest.toString().substring(0, 16); // Use first 16 characters

      print('📱 Generated device ID: $_deviceId');
      return _deviceId!;
    } catch (e) {
      print('❌ Error generating device ID: $e');
      // Fallback to timestamp-based ID
      _deviceId = 'device-${DateTime.now().millisecondsSinceEpoch}';
      return _deviceId!;
    }
  }

  /// Get device name for display purposes
  static Future<String> getDeviceName() async {
    if (_deviceName != null) return _deviceName!;

    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceName;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = '${iosInfo.name} (${iosInfo.model})';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceName = '${windowsInfo.computerName} (Windows)';
      } else if (Platform.isMacOS) {
        deviceName = 'Mac Computer (macOS)';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceName = '${linuxInfo.name} (Linux)';
      } else {
        deviceName = 'Unknown Device';
      }

      _deviceName = deviceName;
      print('📱 Device name: $_deviceName');
      return _deviceName!;
    } catch (e) {
      print('❌ Error getting device name: $e');
      _deviceName = 'Unknown Device';
      return _deviceName!;
    }
  }

  /// Get app version
  static Future<String> getAppVersion() async {
    if (_appVersion != null) return _appVersion!;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      print('📱 App version: $_appVersion');
      return _appVersion!;
    } catch (e) {
      print('❌ Error getting app version: $e');
      _appVersion = 'Unknown Version';
      return _appVersion!;
    }
  }

  /// Get device information for API requests
  static Future<Map<String, String>> getDeviceInfo() async {
    final deviceId = await getDeviceId();
    final deviceName = await getDeviceName();
    final appVersion = await getAppVersion();

    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'appVersion': appVersion,
      'platform': Platform.operatingSystem,
    };
  }

  /// Clear cached device information
  static void clearCache() {
    _deviceId = null;
    _deviceName = null;
    _appVersion = null;
  }
}
