// Filled in with your real Firebase project config (myrsu-9add6).
// If you ever add Android/iOS, re-run `flutterfire configure` to add
// those platform blocks — this file currently only covers Web.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        throw UnsupportedError(
          'MyRSU is configured for Flutter Web only in this template. '
          'Run `flutterfire configure` and add platform entries if you '
          'also want Android/iOS builds.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD916MM2UYyOrmxiZdFpSEP1BABM905WGU',
    appId: '1:646937736270:web:3ceec22fef04e1abe07f1f',
    messagingSenderId: '646937736270',
    projectId: 'myrsu-9add6',
    authDomain: 'myrsu-9add6.firebaseapp.com',
    storageBucket: 'myrsu-9add6.firebasestorage.app',
    measurementId: 'G-38B3WWYBHJ',
  );
}
