

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBjYPdRnwuRSAfTZDZ9fkS-f7hDQccOjOY',
    appId: '1:297491352350:web:e9ee8f4f49bf71afd0570f',
    messagingSenderId: '297491352350',
    projectId: 'smart-fitao-web-app',
    authDomain: 'smart-fitao-web-app.firebaseapp.com',
    storageBucket: 'smart-fitao-web-app.firebasestorage.app',
    measurementId: 'G-4NM9QS41KQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyALdfHuCGK48j44Kyk2ZFhW0Hz6YcaQ_Og',
    appId: '1:297491352350:android:bbc254fb1ffe7bded0570f',
    messagingSenderId: '297491352350',
    projectId: 'smart-fitao-web-app',
    storageBucket: 'smart-fitao-web-app.firebasestorage.app',
  );
}