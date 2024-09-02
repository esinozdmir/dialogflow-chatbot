// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        return windows;
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
    apiKey: 'AIzaSyDEwIHGm9KuLEL6Gco-zxogwGMLhael6j4',
    appId: '1:857915399259:web:ca3905f9b909659163b37e',
    messagingSenderId: '857915399259',
    projectId: 'biyorobot-33e61',
    authDomain: 'biyorobot-33e61.firebaseapp.com',
    storageBucket: 'biyorobot-33e61.appspot.com',
    measurementId: 'G-2DJVQLSLTD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDKeIgq1uMvWMdB4IYi0-fxgNlQ87w1scM',
    appId: '1:857915399259:android:44dd8cfc80ad94d163b37e',
    messagingSenderId: '857915399259',
    projectId: 'biyorobot-33e61',
    storageBucket: 'biyorobot-33e61.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCu2rP7xpVrGvjVn-PksfrdinudU9JL6Ak',
    appId: '1:857915399259:ios:7ef2c017e29a485763b37e',
    messagingSenderId: '857915399259',
    projectId: 'biyorobot-33e61',
    storageBucket: 'biyorobot-33e61.appspot.com',
    iosBundleId: 'com.example.chatbotkou',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCu2rP7xpVrGvjVn-PksfrdinudU9JL6Ak',
    appId: '1:857915399259:ios:7ef2c017e29a485763b37e',
    messagingSenderId: '857915399259',
    projectId: 'biyorobot-33e61',
    storageBucket: 'biyorobot-33e61.appspot.com',
    iosBundleId: 'com.example.chatbotkou',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDEwIHGm9KuLEL6Gco-zxogwGMLhael6j4',
    appId: '1:857915399259:web:cd78243e5f15fc0b63b37e',
    messagingSenderId: '857915399259',
    projectId: 'biyorobot-33e61',
    authDomain: 'biyorobot-33e61.firebaseapp.com',
    storageBucket: 'biyorobot-33e61.appspot.com',
    measurementId: 'G-TED9DJRG5S',
  );
}
