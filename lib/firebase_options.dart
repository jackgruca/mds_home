// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCLO_VAZ9l6PK541-tFkYRquISv5x1I-Dw",
    authDomain: "nfl-draft-simulator-9265f.firebaseapp.com",
    projectId: "nfl-draft-simulator-9265f",
    storageBucket: "nfl-draft-simulator-9265f.firebasestorage.app",
    messagingSenderId: "900728713837",
    appId: "1:900728713837:web:3e0c47b05b144c758f8564",
    measurementId: "G-8QGNSTTZGH",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyCLO_VAZ9l6PK541-tFkYRquISv5x1I-Dw",
    authDomain: "nfl-draft-simulator-9265f.firebaseapp.com",
    projectId: "nfl-draft-simulator-9265f",
    storageBucket: "nfl-draft-simulator-9265f.firebasestorage.app",
    messagingSenderId: "900728713837",
    appId: "1:900728713837:web:3e0c47b05b144c758f8564",
    measurementId: "G-8QGNSTTZGH",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyCLO_VAZ9l6PK541-tFkYRquISv5x1I-Dw",
    authDomain: "nfl-draft-simulator-9265f.firebaseapp.com",
    projectId: "nfl-draft-simulator-9265f",
    storageBucket: "nfl-draft-simulator-9265f.firebasestorage.app",
    messagingSenderId: "900728713837",
    appId: "1:900728713837:web:3e0c47b05b144c758f8564",
    measurementId: "G-8QGNSTTZGH",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "AIzaSyCLO_VAZ9l6PK541-tFkYRquISv5x1I-Dw",
    authDomain: "nfl-draft-simulator-9265f.firebaseapp.com",
    projectId: "nfl-draft-simulator-9265f",
    storageBucket: "nfl-draft-simulator-9265f.firebasestorage.app",
    messagingSenderId: "900728713837",
    appId: "1:900728713837:web:3e0c47b05b144c758f8564",
    measurementId: "G-8QGNSTTZGH",
  );
}