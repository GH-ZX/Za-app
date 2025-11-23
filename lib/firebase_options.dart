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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - ',
        );
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
    storageBucket: 'za-project-b1bc6.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyApDrYZv4Da5HkHTIQH6ks7zpktj9K7iw8',
    appId: '1:293518909640:android:3c753d043d8396ad5645fd',
    messagingSenderId: '293518909640',
    projectId: 'za-project-b1bc6',
    storageBucket: 'za-project-b1bc6.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyApDrYZv4Da5HkHTIQH6ks7zpktj9K7iw8',
    appId: '1:293518909640:ios:8c70ce35b5a83c7a5645fd',
    messagingSenderId: '293518909640',
    projectId: 'za-project-b1bc6',
    storageBucket: 'za-project-b1bc6.appspot.com',
    iosClientId: '293518909640-k8v2jcfh83g2b5b5j4j2c6q8q5q8g5q2.apps.googleusercontent.com',
    iosBundleId: 'com.example.taskManager',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyApDrYZv4Da5HkHTIQH6ks7zpktj9K7iw8',
    appId: '1:293518909640:ios:8c70ce35b5a83c7a5645fd',
    messagingSenderId: '293518909640',
    projectId: 'za-project-b1bc6',
    storageBucket: 'za-project-b1bc6.appspot.com',
    iosClientId: '293518909640-k8v2jcfh83g2b5b5j4j2c6q8q5q8g5q2.apps.googleusercontent.com',
    iosBundleId: 'com.example.taskManager',
  );
}
