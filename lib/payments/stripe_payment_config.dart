import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/production_urls.dart';

/// Stripe Checkout API (Django in `strip payment gateway`).
///
/// Release APK: deploy Django on Render, then build with
/// `--dart-define=STRIPE_PAYMENT_BASE=https://your-stripe.onrender.com`
class StripePaymentConfig {
  StripePaymentConfig._();

  static const String _envBase = String.fromEnvironment(
    'STRIPE_PAYMENT_BASE',
    defaultValue: '',
  );

  static const String _localHost = String.fromEnvironment(
    'LOCAL_DEV_HOST',
    defaultValue: '',
  );

  /// Main Django admin often uses :8000 — Stripe runs on :8002 when that happens.
  static const int _localStripePort = 8002;

  static String? _resolvedLocalBase;

  static String get baseUrl {
    final b = _envBase.trim();
    if (b.isNotEmpty) return b.replaceAll(RegExp(r'/+$'), '');
    if (_resolvedLocalBase != null) {
      return _resolvedLocalBase!.replaceAll(RegExp(r'/+$'), '');
    }
    final h = _localHost.trim();
    if (h.isNotEmpty) return 'http://$h:$_localStripePort';
    final prod = ProductionUrls.stripePayment.trim();
    if (prod.isNotEmpty) return prod.replaceAll(RegExp(r'/+$'), '');
    if (kReleaseMode) return '';
    return 'http://127.0.0.1:$_localStripePort';
  }

  static bool get isConfigured => baseUrl.isNotEmpty;

  static String get createSessionUrl =>
      '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/api/create-checkout-session/';

  /// Finds Stripe API on :8000 or :8002 (avoids main Django on :8000).
  static Future<String> resolveBaseUrl() async {
    final b = _envBase.trim();
    if (b.isNotEmpty) return b.replaceAll(RegExp(r'/+$'), '');
    final prod = ProductionUrls.stripePayment.trim();
    if (prod.isNotEmpty) return prod.replaceAll(RegExp(r'/+$'), '');
    if (kReleaseMode) return '';

    if (_resolvedLocalBase != null) {
      return _resolvedLocalBase!.replaceAll(RegExp(r'/+$'), '');
    }

    final host = _localHost.trim().isEmpty ? '127.0.0.1' : _localHost.trim();
    for (final port in [8000, _localStripePort]) {
      try {
        final res = await http
            .get(Uri.parse('http://$host:$port/api/health/'))
            .timeout(const Duration(seconds: 3));
        if (res.statusCode != 200) continue;
        final body = res.body;
        try {
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['service'] == 'smartfitao-stripe-api') {
            _resolvedLocalBase = 'http://$host:$port';
            return _resolvedLocalBase!;
          }
        } catch (_) {
          if (body.contains('smartfitao-stripe-api')) {
            _resolvedLocalBase = 'http://$host:$port';
            return _resolvedLocalBase!;
          }
        }
      } catch (_) {}
    }

    _resolvedLocalBase = 'http://$host:$_localStripePort';
    return _resolvedLocalBase!;
  }
}
