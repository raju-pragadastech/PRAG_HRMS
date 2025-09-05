import 'dart:async';

/// Global manager for attendance data to ensure proper data isolation between users
class AttendanceDataManager {
  static final AttendanceDataManager _instance = AttendanceDataManager._internal();
  factory AttendanceDataManager() => _instance;
  AttendanceDataManager._internal();

  // Stream controller to notify when data should be cleared
  final StreamController<void> _clearDataController = StreamController<void>.broadcast();
  
  // Stream to listen for data clearing events
  Stream<void> get clearDataStream => _clearDataController.stream;

  // Current user ID to track user changes
  String? _currentUserId;

  /// Set the current user ID and clear data if user has changed
  void setCurrentUser(String? userId) {
    if (_currentUserId != userId) {
      print('🔄 User changed from $_currentUserId to $userId - clearing attendance data');
      _currentUserId = userId;
      clearAllData();
    }
  }

  /// Clear all attendance data and notify listeners
  void clearAllData() {
    print('🧹 AttendanceDataManager: Clearing all attendance data');
    _clearDataController.add(null);
  }

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Dispose the stream controller
  void dispose() {
    _clearDataController.close();
  }
}
