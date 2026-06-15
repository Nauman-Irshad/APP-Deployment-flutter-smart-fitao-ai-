import 'package:flutter/material.dart';

import '../User 3D Market Place/3d_marketplace.dart';
import '../User 3D Market Place/auth-login-sign/ultra_splash_screen.dart';
import '../User 3D Market Place/futuristic_onboarding.dart';
import '../Order-Tracking-System/tracking.dart' show RoleSelectionScreen;
import '../User 3D Market Place/profile.dart';
import '../Tailor/tailor_center.dart';
import '../seller_dashboard/seller_center.dart';
import '../2d_try_on_app/cv_return_listener.dart';
import '../app_navigator.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String marketplace = '/marketplace';
  static const String profile = '/profile';
  static const String tailorCenter = '/tailor-center';
  static const String sellerCenter = '/seller-center';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => UltraSplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => FuturisticOnboardingScreen());
      case auth:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      case marketplace:
        return MaterialPageRoute(
          builder: (_) => CvReturnListener(
            navigatorKey: rootNavigatorKey,
            child: const MarketPlace3D(),
          ),
        );
      case profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case tailorCenter:
        return MaterialPageRoute(builder: (_) => const TailorCenterScreen());
      case sellerCenter:
        return MaterialPageRoute(builder: (_) => const SellerCenterScreen());
      default:
        return MaterialPageRoute(builder: (_) => UltraSplashScreen());
    }
  }
}

