import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'register_webview.dart';
import 'app/app.dart';
import '2d_try_on_app/cv_return_listener.dart';
import 'payments/stripe_return_listener.dart';
import 'app_navigator.dart';

/// Full SmartFitao app: splash → onboarding → auth → marketplace.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensureWebViewPlatformRegistered();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('Firebase init failed: $e\n$st');
  }
  runApp(
    StripeReturnListener(
      navigatorKey: rootNavigatorKey,
      child: CvReturnListener(
        navigatorKey: rootNavigatorKey,
        child: const AppRoot(),
      ),
    ),
  );
}
