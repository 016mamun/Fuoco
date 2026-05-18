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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCCjt7S0k2rVVyxSaD9t9GEwpx4L5hfXAo',
    appId: '1:266560863544:web:f03605f301ba9b861e95cd',
    messagingSenderId: '266560863544',
    projectId: 'fuoco-253ac',
    authDomain: 'fuoco-253ac.firebaseapp.com',
    storageBucket: 'fuoco-253ac.firebasestorage.app',
    measurementId: 'G-3YZFRM607K',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDHhx-KUbS4iMw5wyvCJJj_COGtxWHATz8',
    appId: '1:266560863544:android:71cd9d78d412b9f81e95cd',
    messagingSenderId: '266560863544',
    projectId: 'fuoco-253ac',
    storageBucket: 'fuoco-253ac.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDHhx-KUbS4iMw5wyvCJJj_COGtxWHATz8',
    appId: '1:266560863544:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '266560863544',
    projectId: 'fuoco-253ac',
    storageBucket: 'fuoco-253ac.firebasestorage.app',
    iosBundleId: 'fuoco.company',
  );
}
