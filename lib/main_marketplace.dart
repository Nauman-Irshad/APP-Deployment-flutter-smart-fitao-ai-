import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'register_webview.dart';
import 'core/themes/app_theme.dart';
import 'User 3D Market Place/3d_marketplace.dart';
import '2d_try_on_app/cv_return_listener.dart';
import 'app_navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensureWebViewPlatformRegistered();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    navigatorKey: rootNavigatorKey,
    debugShowCheckedModeBanner: false,
    title: 'SmartFitao AI – 3D Marketplace',
    theme: AppTheme.light,
    home: CvReturnListener(
      navigatorKey: rootNavigatorKey,
      child: const MarketPlace3D(),
    ),
  ));
}
