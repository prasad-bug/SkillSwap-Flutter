import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with SkillSwap Firebase apps.
///
/// Connected to project: flutter-skillswap (858318991819)
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
    apiKey: 'AIzaSyDVWUMCkiQqE__Gyh6xf05aMk2XZjtx1Wc',
    appId: '1:858318991819:web:971e99b051fc31d7e2c64e',
    messagingSenderId: '858318991819',
    projectId: 'flutter-skillswap',
    authDomain: 'flutter-skillswap.firebaseapp.com',
    storageBucket: 'flutter-skillswap.firebasestorage.app',
    measurementId: 'G-DD552LBN23',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyARatdIHODr5vfni6otABpVvvSREUW5TL0',
    appId: '1:858318991819:android:8099de7dd8f2a7a2e2c64e',
    messagingSenderId: '858318991819',
    projectId: 'flutter-skillswap',
    storageBucket: 'flutter-skillswap.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDxLOhGtKD667m9X8sG2i57C5_gLayLLEU',
    appId: '1:858318991819:ios:e4f0325aa55f2e58e2c64e',
    messagingSenderId: '858318991819',
    projectId: 'flutter-skillswap',
    storageBucket: 'flutter-skillswap.firebasestorage.app',
    iosBundleId: 'com.skillswap.skillSwap',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDxLOhGtKD667m9X8sG2i57C5_gLayLLEU',
    appId: '1:858318991819:ios:e4f0325aa55f2e58e2c64e',
    messagingSenderId: '858318991819',
    projectId: 'flutter-skillswap',
    storageBucket: 'flutter-skillswap.firebasestorage.app',
    iosBundleId: 'com.skillswap.skillSwap',
  );
}
