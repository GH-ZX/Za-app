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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - ',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyApDrYZv4Da5HkHTIQH6ks7zpktj9K7iw8',
    appId: '1:293518909640:web:089191e1ee0ce3dd5645fd',
    messagingSenderId: '293518909640',
    projectId: 'za-project-b1bc6',
    authDomain: 'za-project-b1bc6.firebaseapp.com',
    storageBucket: 'za-project-b1bc6.firebasestorage.app',
    measurementId: 'G-TZ85LWXQWS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB03AjhiqGU9gQW0qLlfpNEpdfQTIfv0yQ',
    appId: '1:293518909640:android:23e2748666e828a15645fd',
    messagingSenderId: '293518909640',
    projectId: 'za-project-b1bc6',
    storageBucket: 'za-project-b1bc6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDDLA03rmotgiva8RnYuWLcWQXZLkZx-Yw',
    appId: '1:293518909640:ios:cf0949aa5ee9d3445645fd',
    messagingSenderId: '293518909640',
    projectId: 'za-project-b1bc6',
    storageBucket: 'za-project-b1bc6.firebasestorage.app',
    iosClientId: '293518909640-hfbhc4939t8feek0ll44u76n197cdkmv.apps.googleusercontent.com',
    iosBundleId: 'com.def.z',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDDLA03rmotgiva8RnYuWLcWQXZLkZx-Yw',
    appId: '1:293518909640:ios:cbf9b3ca4dff9fdc5645fd',
    messagingSenderId: '293518909640',
    projectId: 'za-project-b1bc6',
    storageBucket: 'za-project-b1bc6.firebasestorage.app',
    iosClientId: '293518909640-um17263i732637up4ijlhm17ifru3t9g.apps.googleusercontent.com',
    iosBundleId: 'zaapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyApDrYZv4Da5HkHTIQH6ks7zpktj9K7iw8',
    appId: '1:293518909640:web:d37d0918d9a4cb835645fd',
    messagingSenderId: '293518909640',
    projectId: 'za-project-b1bc6',
    authDomain: 'za-project-b1bc6.firebaseapp.com',
    storageBucket: 'za-project-b1bc6.firebasestorage.app',
    measurementId: 'G-NKNKGD3SH4',
  );

}