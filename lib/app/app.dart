import 'package:flutter/material.dart';

import '../User 3D Market Place/3d_marketplace.dart';
import '../core/themes/app_theme.dart';
import 'routes.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartFitao AI',
      theme: AppTheme.light,
      // Reliable on all platforms / web (initialRoute + onGenerateRoute can ignore
      // the first route in some setups). Splash screen file is unchanged; this
      // only sets what the root `MaterialApp` shows first.
      home: const MarketPlace3D(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}


