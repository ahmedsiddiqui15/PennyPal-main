

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
    apiKey: 'AIzaSyAYYsTHQblcSX34mHLbeZbBCWy1XKhyHYc',
    appId: '1:85001060800:web:629fbcf70283a33de58825',
    messagingSenderId: '85001060800',
    projectId: 'pennypal-c7942',
    authDomain: 'pennypal-c7942.firebaseapp.com',
    storageBucket: 'pennypal-c7942.firebasestorage.app',
    measurementId: 'G-9GFTS0L3L1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBROiXkw5lX_KoUW_RpCFUl5E8i2olurec',
    appId: '1:85001060800:android:4f989c648dfd52f8e58825',
    messagingSenderId: '85001060800',
    projectId: 'pennypal-c7942',
    storageBucket: 'pennypal-c7942.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyADBQX0QUqk1rjhlBuKE3GvqMZzYAP6E8s',
    appId: '1:85001060800:ios:36cb81cd9a950dc8e58825',
    messagingSenderId: '85001060800',
    projectId: 'pennypal-c7942',
    storageBucket: 'pennypal-c7942.firebasestorage.app',
    iosBundleId: 'com.pennypal.pennypal',
  );
}
