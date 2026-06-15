import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '2d_try_on_app/try_on_app_root.dart';
import 'app_navigator.dart';
import 'core/themes/app_theme.dart';
import 'firebase_options.dart';
import 'payments/stripe_return_listener.dart';
import 'register_webview.dart';

/// 2D try-on only — no marketplace, camera, or size wizard.
/// Run: flutter run -t lib/main_2d_try_on.dart -d edge --web-port=65109
/// Camera **2D Try On** opens: http://127.0.0.1:65109/
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensureWebViewPlatformRegistered();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Smart Fiatio — 2D Try On',
      theme: AppTheme.light,
      home: StripeReturnListener(
        navigatorKey: rootNavigatorKey,
        child: const TryOnAppRoot(),
      ),
    ),
  );
}
