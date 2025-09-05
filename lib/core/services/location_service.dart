import 'package:geolocator/geolocator.dart';

class LocationService {
  static const double _defaultLatitude = 0.0;
  static const double _defaultLongitude = 0.0;
  static const double _defaultAccuracy = 0.0;

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 Location service enabled: $serviceEnabled');
      return serviceEnabled;
    } catch (e) {
      print('❌ Error checking location service: $e');
      return false;
    }
  }

  /// Check location permission status
  static Future<LocationPermission> checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Location permission status: $permission');
      return permission;
    } catch (e) {
      print('❌ Error checking location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Request location permission
  static Future<LocationPermission> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      print('📍 Location permission requested: $permission');
      return permission;
    } catch (e) {
      print('❌ Error requesting location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Get current location with high accuracy
  static Future<Map<String, double>> getCurrentLocation() async {
    try {
      print('📍 Getting current location...');

      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. Please enable location services.',
        );
      }

      // Check location permission
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
            'Location permission denied. Please grant location permission to clock in.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied. Please enable location permission in app settings.',
        );
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      print(
        '📍 Location obtained: ${position.latitude}, ${position.longitude}',
      );
      print('📍 Accuracy: ${position.accuracy} meters');

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
      };
    } catch (e) {
      print('❌ Error getting current location: $e');
      throw Exception('Failed to get current location: $e');
    }
  }

  /// Get location with fallback to default values
  static Future<Map<String, double>> getLocationWithFallback() async {
    try {
      return await getCurrentLocation();
    } catch (e) {
      print('⚠️ Using fallback location due to error: $e');
      return {
        'latitude': _defaultLatitude,
        'longitude': _defaultLongitude,
        'accuracy': _defaultAccuracy,
        'altitude': 0.0,
        'speed': 0.0,
        'heading': 0.0,
      };
    }
  }

  /// Calculate distance between two coordinates in meters
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if location is within office radius (default 100 meters)
  static Future<bool> isWithinOfficeRadius({
    required double officeLatitude,
    required double officeLongitude,
    double radiusInMeters = 100.0,
  }) async {
    try {
      final location = await getCurrentLocation();
      final distance = calculateDistance(
        location['latitude']!,
        location['longitude']!,
        officeLatitude,
        officeLongitude,
      );

      print('📍 Distance from office: ${distance.toStringAsFixed(2)} meters');
      print('📍 Office radius: $radiusInMeters meters');
      print('📍 Within radius: ${distance <= radiusInMeters}');

      return distance <= radiusInMeters;
    } catch (e) {
      print('❌ Error checking office radius: $e');
      return false;
    }
  }

  /// Get location address (reverse geocoding)
  static Future<String> getLocationAddress(
    double latitude,
    double longitude,
  ) async {
    try {
      // For now, return coordinates as address
      // TODO: Implement proper reverse geocoding when needed
      String address =
          'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
      print('📍 Address: $address');
      return address;
    } catch (e) {
      print('❌ Error getting address: $e');
      return 'Unknown location';
    }
  }

  /// Check if GPS is available and working
  static Future<bool> isGpsAvailable() async {
    try {
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      // Try to get a quick location fix
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      return true;
    } catch (e) {
      print('❌ GPS not available: $e');
      return false;
    }
  }

  /// Get location status message
  static Future<String> getLocationStatusMessage() async {
    try {
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Location services are disabled. Please enable location services in your device settings.';
      }

      LocationPermission permission = await checkLocationPermission();
      switch (permission) {
        case LocationPermission.denied:
          return 'Location permission denied. Please grant location permission to clock in.';
        case LocationPermission.deniedForever:
          return 'Location permission permanently denied. Please enable location permission in app settings.';
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return 'Location services are available.';
        case LocationPermission.unableToDetermine:
          return 'Unable to determine location permission status.';
      }
    } catch (e) {
      return 'Error checking location status: $e';
    }
  }
}
