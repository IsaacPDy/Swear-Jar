import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web {
    String authDomain = 'swear-jar-5b12c.firebaseapp.com';
    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      if (host.contains('swear-jar-5b12c.web.app')) {
        authDomain = 'swear-jar-5b12c.web.app';
      } else if (host.isNotEmpty && !host.contains('localhost') && !host.contains('127.0.0.1')) {
        authDomain = host;
      }
    }
    return FirebaseOptions(
      apiKey: 'AIzaSyAoYYCTXJ5ls7qrMga4-LY-gDQqxDYJTLs',
      appId: '1:526966419923:web:34317b6193dfe3a8aaff26',
      messagingSenderId: '526966419923',
      projectId: 'swear-jar-5b12c',
      authDomain: authDomain,
      storageBucket: 'swear-jar-5b12c.firebasestorage.app',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAoYYCTXJ5ls7qrMga4-LY-gDQqxDYJTLs',
    appId: '1:526966419923:android:34317b6193dfe3a8aaff26',
    messagingSenderId: '526966419923',
    projectId: 'swear-jar-5b12c',
    storageBucket: 'swear-jar-5b12c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAoYYCTXJ5ls7qrMga4-LY-gDQqxDYJTLs',
    appId: '1:526966419923:ios:34317b6193dfe3a8aaff26',
    messagingSenderId: '526966419923',
    projectId: 'swear-jar-5b12c',
    storageBucket: 'swear-jar-5b12c.firebasestorage.app',
    iosBundleId: 'com.swearjar.swearJar',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAoYYCTXJ5ls7qrMga4-LY-gDQqxDYJTLs',
    appId: '1:526966419923:ios:34317b6193dfe3a8aaff26',
    messagingSenderId: '526966419923',
    projectId: 'swear-jar-5b12c',
    storageBucket: 'swear-jar-5b12c.firebasestorage.app',
    iosBundleId: 'com.swearjar.swearJar',
  );
}
