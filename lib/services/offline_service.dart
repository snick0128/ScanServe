import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();

  factory OfflineService() {
    return _instance;
  }

  OfflineService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  bool _isOnline = true;
  bool _isInitialized = false;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
      _connectionStatusController.add(_isOnline);

      // Listen for connectivity changes
      _connectivity.onConnectivityChanged.listen((result) {
        final wasOnline = _isOnline;
        _isOnline = result != ConnectivityResult.none;

        // Only emit if status actually changed
        if (wasOnline != _isOnline) {
          _connectionStatusController.add(_isOnline);
        }
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing connectivity: $e');
      _isOnline = false;
      _connectionStatusController.add(false);
    }
  }

  void dispose() {
    _connectionStatusController.close();
  }

  // Show offline snackbar
  void showOfflineSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Text('You\'re offline. Some features may be limited.'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show online snackbar
  void showOnlineSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi, color: Colors.white),
            SizedBox(width: 8),
            Text('You\'re back online!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Check if Firebase is available (for web persistence)
  Future<bool> isFirebaseAvailable() async {
    try {
      await FirebaseFirestore.instance.collection('test').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get offline status message
  String getOfflineStatusMessage() {
    if (_isOnline) {
      return 'Online';
    } else {
      return 'Offline - Limited functionality';
    }
  }

  // Get offline status color
  Color getOfflineStatusColor() {
    return _isOnline ? Colors.green : Colors.orange;
  }
}
