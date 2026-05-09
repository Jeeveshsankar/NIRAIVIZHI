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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDcU_GuD9cQqCtKn_pElZNbQvn_aVEQpM4',
    appId: '1:855373928998:web:812ead9a87915c1319a4e7',
    messagingSenderId: '855373928998',
    projectId: 'aquaguard-b0b2c',
    authDomain: 'aquaguard-b0b2c.firebaseapp.com',
    storageBucket: 'aquaguard-b0b2c.firebasestorage.app',
    measurementId: 'G-KQ9HEWP4E9',
    databaseURL:
        "https://aquaguard-b0b2c-default-rtdb.asia-southeast1.firebasedatabase.app/",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDr3Da_N9fW-pxKlF-z5uCKjk6vlsNGy70',
    appId: '1:855373928998:android:b34e54df09c39f6519a4e7',
    messagingSenderId: '855373928998',
    projectId: 'aquaguard-b0b2c',
    storageBucket: 'aquaguard-b0b2c.firebasestorage.app',
    databaseURL:
        "https://aquaguard-b0b2c-default-rtdb.asia-southeast1.firebasedatabase.app/",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBu_uA6BOGTEO_RUdgBj4GP4oM_cBAgsas',
    appId: '1:855373928998:ios:1c6b52dd0920883e19a4e7',
    messagingSenderId: '855373928998',
    projectId: 'aquaguard-b0b2c',
    storageBucket: 'aquaguard-b0b2c.firebasestorage.app',
    iosBundleId: 'com.example.aquaguard',
  );
}
