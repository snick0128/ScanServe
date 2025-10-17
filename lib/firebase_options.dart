import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // Add other platforms if needed
    throw UnsupportedError(
      'DefaultFirebaseOptions has no configuration for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBl5zYKHQJiiC1MgC0UN50IQGi2z0ffyzg',
    appId: '1:292831508469:web:d0fe33fda842ee686012bc',
    messagingSenderId: '292831508469',
    projectId: 'scanserve-e460a',
    authDomain: 'scanserve-e460a.firebaseapp.com',
    storageBucket: 'scanserve-e460a.firebasestorage.app',
    measurementId: 'G-NLTE8WEPR0',
  );
}
