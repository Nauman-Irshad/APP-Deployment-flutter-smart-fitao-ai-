import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'Order-Tracking-System/login_as_seller.dart';
import 'core/themes/app_theme.dart';
import 'firebase_options.dart';
import 'register_webview.dart';
import 'seller_dashboard/bottom_navi.dart';

/// Seller dashboard only — login → products + Firebase order tracking.
/// Run: flutter run -t lib/main_seller_dashboard.dart -d edge
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensureWebViewPlatformRegistered();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SellerDashboardApp());
}

class SellerDashboardApp extends StatelessWidget {
  const SellerDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartFitao — Seller Dashboard',
      theme: AppTheme.light,
      home: const _SellerAuthGate(),
    );
  }
}

class _SellerAuthGate extends StatelessWidget {
  const _SellerAuthGate();

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
          return const BottomNavScreen();
        }
        return const LoginAsSellerScreen();
      },
    );
  }
}
