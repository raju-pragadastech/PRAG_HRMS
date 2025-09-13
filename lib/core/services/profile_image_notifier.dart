import 'package:flutter/foundation.dart';

class ProfileImageNotifier extends ChangeNotifier {
  static final ProfileImageNotifier _instance =
      ProfileImageNotifier._internal();
  factory ProfileImageNotifier() => _instance;
  ProfileImageNotifier._internal();

  String? _currentProfileImageUrl;
  String? _currentUserId;

  String? get currentProfileImageUrl => _currentProfileImageUrl;
  String? get currentUserId => _currentUserId;

  /// Update profile image for a specific user
  void updateProfileImage(String userId, String? imageUrl) {
    _currentUserId = userId;
    _currentProfileImageUrl = imageUrl;
    notifyListeners();
    print('📸 Profile image updated: $imageUrl for user: $userId');
  }

  /// Clear profile image
  void clearProfileImage() {
    _currentProfileImageUrl = null;
    _currentUserId = null;
    notifyListeners();
    print('📸 Profile image cleared');
  }

  /// Check if profile image exists for current user
  bool hasProfileImage(String userId) {
    return _currentUserId == userId &&
        _currentProfileImageUrl != null &&
        _currentProfileImageUrl!.isNotEmpty;
  }
}
