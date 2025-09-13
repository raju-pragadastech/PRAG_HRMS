import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Test Firebase Storage connectivity
  static Future<bool> testFirebaseStorage() async {
    try {
      print('🧪 Testing Firebase Storage connectivity...');

      // Try to create a reference
      final ref = _storage.ref().child('test/connectivity-test.txt');
      print('✅ Firebase Storage reference created');

      // Try to upload a small test file
      final testData = 'Firebase Storage test - ${DateTime.now()}';
      final uploadTask = await ref.putString(testData);
      print('✅ Test file uploaded successfully');

      // Try to get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('✅ Download URL retrieved: $downloadUrl');

      // Clean up test file
      try {
        await ref.delete();
        print('✅ Test file cleaned up');
      } catch (e) {
        print('⚠️ Could not clean up test file: $e');
      }

      return true;
    } catch (e) {
      print('❌ Firebase Storage test failed: $e');
      return false;
    }
  }

  /// Upload profile image to Firebase Storage and save URL to Firestore
  static Future<String?> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      print('📸 Starting profile image upload for user: $userId');
      print('📸 Image file path: ${imageFile.path}');
      print('📸 Image file exists: ${await imageFile.exists()}');
      print('📸 Image file size: ${await imageFile.length()} bytes');

      // Check if Firebase Storage is available
      try {
        final storageRef = _storage.ref();
        print('✅ Firebase Storage reference created successfully');
      } catch (e) {
        print('❌ Firebase Storage not available: $e');
        throw Exception('Firebase Storage is not properly configured: $e');
      }

      // Create reference to the file in Firebase Storage
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      print('📸 Storage reference created: profile_images/$userId.jpg');

      // Upload the file with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      print('📸 Starting file upload...');
      final uploadTask = await ref.putFile(imageFile, metadata);
      print('📸 File upload completed');

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('✅ Profile image uploaded successfully: $downloadUrl');

      // Save URL to Firestore
      try {
        await _firestore.collection('users').doc(userId).set({
          'profileImageUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('✅ Profile image URL saved to Firestore');
      } catch (e) {
        print('⚠️ Warning: Could not save to Firestore: $e');
        // Don't throw error here, as the image was uploaded successfully
      }

      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e.toString().contains('object-not-found')) {
        throw Exception(
          'Firebase Storage bucket not found. Please check your Firebase configuration.',
        );
      } else if (e.toString().contains('permission-denied')) {
        throw Exception(
          'Permission denied. Please check your Firebase Storage rules.',
        );
      } else if (e.toString().contains('unauthenticated')) {
        throw Exception(
          'Authentication required. Please ensure Firebase Auth is properly configured.',
        );
      } else {
        throw Exception('Failed to upload profile image: $e');
      }
    }
  }

  /// Get profile image URL from Firestore
  static Future<String?> getProfileImageUrl(String userId) async {
    try {
      print('📸 Fetching profile image URL for user: $userId');

      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final data = doc.data();
        final imageUrl = data?['profileImageUrl'] as String?;
        print('✅ Profile image URL fetched: $imageUrl');
        return imageUrl;
      } else {
        print('❌ No user document found in Firestore');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching profile image URL: $e');
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

  /// Show image source selection dialog
  static Future<File?> showImageSourceDialog() async {
    // This will be handled by the UI layer
    // Return null here as the actual dialog will be shown in the widget
    return null;
  }

  /// Delete profile image from Firebase Storage and Firestore
  static Future<void> deleteProfileImage(String userId) async {
    try {
      print('🗑️ Deleting profile image for user: $userId');

      // Delete from Firebase Storage
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      await ref.delete();
      print('✅ Profile image deleted from Firebase Storage');

      // Remove URL from Firestore
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Profile image URL removed from Firestore');
    } catch (e) {
      print('❌ Error deleting profile image: $e');
      throw Exception('Failed to delete profile image: $e');
    }
  }

  /// Check if user has profile image
  static Future<bool> hasProfileImage(String userId) async {
    try {
      final imageUrl = await getProfileImageUrl(userId);
      return imageUrl != null && imageUrl.isNotEmpty;
    } catch (e) {
      print('❌ Error checking profile image: $e');
      return false;
    }
  }
}
