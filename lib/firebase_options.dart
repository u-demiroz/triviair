// Bu dosya FlutterFire CLI ile otomatik oluşturulacak.
// Kurulum adımları README'de açıklanmıştır.
// Şimdilik placeholder — FlutterFire CLI ile replace edilecek.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError('Bu platform desteklenmiyor.');
    }
  }

  // Bu değerler FlutterFire CLI ile doldurulacak
  // flutterfire configure komutuyla otomatik oluşturulur
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'triviair-2aa41',
    storageBucket: 'triviair-2aa41.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'triviair-2aa41',
    storageBucket: 'triviair-2aa41.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'triviair-2aa41',
    storageBucket: 'triviair-2aa41.appspot.com',
    iosClientId: 'REPLACE_ME',
    iosBundleId: 'com.trivair.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'triviair-2aa41',
    storageBucket: 'triviair-2aa41.appspot.com',
    iosClientId: 'REPLACE_ME',
    iosBundleId: 'com.trivair.app',
  );
}
