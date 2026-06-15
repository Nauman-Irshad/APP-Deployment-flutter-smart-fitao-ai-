import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'register_webview.dart';
import 'core/themes/app_theme.dart';
import 'User 3D Market Place/3d_marketplace.dart';

/// Android Studio: select run config **「3D Landing (Android)」** (not `main.dart`).
/// Hot reload only works when you **Run ▶** from the IDE — not when opening the installed app icon.
/// Opens directly on the 3D marketplace landing (all revolving products).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensureWebViewPlatformRegistered();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartFitao AI – 3D Marketplace',
      theme: AppTheme.light,
      home: const MarketPlace3D(),
    ),
  );
}
