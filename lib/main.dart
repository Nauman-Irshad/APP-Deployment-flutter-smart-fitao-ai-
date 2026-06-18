import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'register_webview.dart';
import 'app/app.dart';
import '2d_try_on_app/cv_return_listener.dart';
import 'payments/stripe_return_listener.dart';
import 'app_navigator.dart';
import 'services/glb_preload_service.dart';
import 'config/mobile_media_config.dart';
import 'services/demo_accounts_service.dart';
import 'services/marketplace_demo_seller.dart';
import 'services/marketplace_badge_service.dart';
import 'User 3D Market Place/landing_page_products.dart';

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

  warmMarketplaceGlbUrls(
    kLandingPageModelPaths.take(glbPreloadCount),
  );
  warmSizePredictionApi();
  unawaited(DemoAccountsService.instance.preload());
  unawaited(MarketplaceDemoSeller.resolve());
  unawaited(MarketplaceBadgeService.instance.ensureLoaded());

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
