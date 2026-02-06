import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static Future<void> initialize() async {
    try {
      print('🔥 INITIALIZING FIREBASE...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ FIREBASE INITIALIZED SUCCESSFULLY');

      // Enable offline persistence for Firestore
      if (kIsWeb) {
        // For web, enable persistence with settings
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        print('🔥 FIRESTORE WEB SETTINGS CONFIGURED');
      } else {
        // For mobile, enable persistence (default behavior)
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
        );
        print('🔥 FIRESTORE MOBILE SETTINGS CONFIGURED');
      }
      print('✅ FIREBASE INITIALIZATION COMPLETE');
    } catch (e) {
      print('❌ FIREBASE INITIALIZATION ERROR: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  static Future<void> clearCache() async {
    try {
      // NOTE: clearPersistence() will fail if there are active listeners.
      // Callers should ensure providers/controllers are disposed before calling this.
      await FirebaseFirestore.instance.clearPersistence();
      print('🗑️ Firestore cache cleared successfully.');
    } catch (e) {
      print('⚠️ Failed to clear Firestore cache (possibly due to active listeners): $e');
      // Don't rethrow to prevent app crash on web
    }
  }

  static bool get isPersistenceEnabled {
    return FirebaseFirestore.instance.settings.persistenceEnabled ?? false;
  }
}
