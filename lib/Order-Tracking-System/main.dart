import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import '../app/app.dart';

/// Same startup as `lib/main.dart` — opens **3D marketplace** via [AppRoot].
/// Use this entry only if you pass `-t lib/Order-Tracking-System/main.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AppRoot());
}
