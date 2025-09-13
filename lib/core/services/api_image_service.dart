import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../constants/api_constants.dart';

class ApiImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Upload profile image to your API backend
  static Future<String?> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      print('📸 Starting profile image upload via API for user: $userId');
      print('📸 Image file path: ${imageFile.path}');
      print('📸 Image file exists: ${await imageFile.exists()}');
      print('📸 Image file size: ${await imageFile.length()} bytes');

      // Get auth token
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // Create multipart request for file upload
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api-hrms.pragva.in/api/files/profile-pictures/'),
      );

      // Add headers
      request.headers.addAll({'Authorization': 'Bearer $token'});

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'profilePicture',
          imageFile.path,
          filename: 'profile_$userId.jpg',
        ),
      );

      // Add employee ID
      request.fields['employeeId'] = userId;

      print('📸 Uploading image to API...');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📸 API Response Status: ${response.statusCode}');
      print('📸 API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Generate the expected URL format
        final imageUrl =
            'https://api-hrms.pragva.in/api/files/profile-pictures/profile_$userId.jpg';

        print('✅ Profile image uploaded successfully via API: $imageUrl');

        // Save image URL to local storage for caching
        await StorageService.saveProfileImageUrl(userId, imageUrl);

        return imageUrl;
      } else {
        throw Exception('API Error: ${response.body}');
      }
    } catch (e) {
      print('❌ Error uploading profile image via API: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Get profile image URL from API
  static Future<String?> getProfileImageUrl(String userId) async {
    try {
      print('📸 Fetching profile image URL from API for user: $userId');

      // First check local storage cache
      final cachedUrl = await StorageService.getProfileImageUrl(userId);
      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        print('✅ Using cached profile image URL: $cachedUrl');
        return cachedUrl;
      }

      // For your API structure, we'll construct the expected URL
      // and check if the image exists by making a HEAD request
      final expectedUrl =
          'https://api-hrms.pragva.in/api/files/profile-pictures/profile_$userId.jpg';

      try {
        final response = await http.head(Uri.parse(expectedUrl));
        if (response.statusCode == 200) {
          print('✅ Profile image found at: $expectedUrl');
          // Cache the URL locally
          await StorageService.saveProfileImageUrl(userId, expectedUrl);
          return expectedUrl;
        } else {
          print(
            '📸 No profile image found for user (status: ${response.statusCode})',
          );
          return null;
        }
      } catch (e) {
        print('📸 Profile image not found: $e');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching profile image URL from API: $e');
      return null;
    }
  }

  /// Pick image from camera or gallery
  static Future<File?> pickImage({required ImageSource source}) async {
    try {
      // Check permissions
      if (source == ImageSource.camera) {
        final cameraPermission = await Permission.camera.request();
        if (!cameraPermission.isGranted) {
          throw Exception('Camera permission denied');
        }
      } else {
        final storagePermission = await Permission.photos.request();
        if (!storagePermission.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('❌ Error picking image: $e');
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Delete profile image via API
  static Future<void> deleteProfileImage(String userId) async {
    try {
      print('🗑️ Deleting profile image via API for user: $userId');

      // Get auth token
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // For your API structure, we'll try to delete the file
      final imageUrl =
          'https://api-hrms.pragva.in/api/files/profile-pictures/profile_$userId.jpg';

      final response = await http.delete(
        Uri.parse(imageUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('📸 Delete API Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Profile image deleted successfully via API');

        // Remove from local cache
        await StorageService.removeProfileImageUrl(userId);
      } else {
        print('⚠️ Delete response: ${response.body}');
        // Even if delete fails on server, remove from local cache
        await StorageService.removeProfileImageUrl(userId);
      }
    } catch (e) {
      print('❌ Error deleting profile image via API: $e');
      // Even if delete fails, remove from local cache
      await StorageService.removeProfileImageUrl(userId);
    }
  }

  /// Test API connectivity
  static Future<bool> testApiConnectivity() async {
    try {
      print('🧪 Testing API connectivity...');

      final token = await StorageService.getToken();
      if (token == null) {
        print('❌ No auth token found');
        return false;
      }

      // Test with the employee profile endpoint (which we know exists)
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.employeeProfileEndpoint}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📸 API connectivity test response: ${response.statusCode}');
      // Consider 200, 401, 403 as "API is reachable" (even if auth fails)
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      print('❌ API connectivity test failed: $e');
      return false;
    }
  }
}
