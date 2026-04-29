import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/themes/app_theme.dart';
import 'User 3D Market Place/3d_marketplace.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'SmartFitao AI – 3D Marketplace',
    theme: AppTheme.light,
    home: const MarketPlace3D(),
  ));
}
