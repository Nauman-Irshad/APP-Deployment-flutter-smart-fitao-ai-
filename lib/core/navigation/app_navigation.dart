import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../User 3D Market Place/auth-login-sign/auth_flow.dart';
import '../../User 3D Market Place/shopping_cart.dart';
import '../utils/auth_storage.dart';

/// Consistent back / logout behaviour — never restart the whole app stack.
class AppNavigation {
  AppNavigation._();

  /// Pop nested routes (checkout, product, etc.) and switch marketplace tab.
  static void popToMarketplaceHome(BuildContext context, {int tabIndex = 0}) {
    final nav = Navigator.of(context);
    while (nav.canPop()) {
      nav.pop();
    }
    ShoppingCart.instance.onNavigateToTab?.call(tabIndex);
  }

  /// Standard back — one screen only.
  static void popOne(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Sign out but keep Firestore orders (same email on re-login).
  static Future<void> logoutToRolePicker(BuildContext context) async {
    await AuthStorage.clearAllData();
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => AuthFlow()),
    );
  }
}
