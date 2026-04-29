import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Firebase configuration for this Flutter app.
///
/// Note: Because you're running on Chrome (web), you ideally should have
/// `FirebaseOptions.web` as well. If you only filled `android` values,
/// the app may still compile but web initialization can fail at runtime.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Your provided config only includes `android` options.
    // This selects them for all platforms for now.
    return android;
    // If you add a `web` block, replace the line above with:
    // return kIsWeb ? web : android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBgLrPpx9TowdhgGVVbjCIk4irliybdKb8',
    appId: '1:15597410237:android:b9c5447c5a8dc33d5aa4d4',
    messagingSenderId: '15597410237',
    projectId: 'websmart-702de',
    storageBucket: 'websmart-702de.firebasestorage.app',
  );
}

