import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;
  bool _isDialogShowing = false;

  bool get isConnected => _isConnected;

  // Initialize connectivity monitoring
  void initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        print('❌ Connectivity error: $error');
      },
    );
  }

  // Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _isConnected = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );

    print(
      '🌐 Connectivity changed: ${_isConnected ? "Connected" : "Disconnected"}',
    );

    // If disconnected and dialog is not showing, show dialog
    if (!_isConnected && !_isDialogShowing) {
      _showNoInternetDialog();
    }
    // If reconnected and dialog was showing, hide it
    else if (_isConnected && _isDialogShowing) {
      _hideNoInternetDialog();
    }
  }

  // Show no internet dialog
  void _showNoInternetDialog() {
    if (_isDialogShowing) return;

    _isDialogShowing = true;

    // Get the current context from the navigator
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async =>
              false, // Prevent back button from closing dialog
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'No Internet Connection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              'Please connect to the internet to continue using the app.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // Check connectivity again
                  checkConnectivity();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Hide no internet dialog
  void _hideNoInternetDialog() {
    if (!_isDialogShowing) return;

    _isDialogShowing = false;

    final context = navigatorKey.currentContext;
    if (context != null && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  // Check current connectivity status
  Future<void> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _onConnectivityChanged(results);
    } catch (e) {
      print('❌ Error checking connectivity: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _isDialogShowing = false;
  }
}

// Global navigator key for accessing context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
