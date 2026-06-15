import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'Order-Tracking-System/login_as_tailor.dart';
import 'Tailor/botm_navi.dart';
import 'core/themes/app_theme.dart';
import 'firebase_options.dart';
import 'register_webview.dart';

/// Tailor dashboard entry — login → Messages / orders / income.
/// Run: flutter run -t lib/main_tailor_dashboard.dart -d edge --web-port=65110
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensureWebViewPlatformRegistered();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TailorDashboardApp());
}

class TailorDashboardApp extends StatelessWidget {
  const TailorDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartFitao — Tailor',
      theme: AppTheme.light,
      home: const _TailorGate(),
    );
  }
}

class _TailorGate extends StatelessWidget {
  const _TailorGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data != null) {
          return const BotmNavScreen();
        }
        return const LoginAsTailorScreen();
      },
    );
  }
}
