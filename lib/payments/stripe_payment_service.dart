import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'stripe_payment_config.dart';

class StripeCheckoutSession {
  StripeCheckoutSession({
    required this.url,
    this.sessionId,
    this.isMock = false,
    this.message,
  });

  final String url;
  final String? sessionId;
  final bool isMock;
  final String? message;
}

class StripePaymentService {
  StripePaymentService._();

  /// Current Flutter app URL without query (for Stripe return URLs).
  static String appReturnBase() {
    if (kIsWeb) {
      final u = Uri.base;
      final port = u.hasPort ? ':${u.port}' : '';
      final path = u.path.isEmpty ? '/' : u.path;
      // Must match the exact tab origin (localhost:65109 ≠ 127.0.0.1:65109 for sessionStorage).
      return '${u.scheme}://${u.host}$port$path';
    }
    return const String.fromEnvironment(
      'STRIPE_FLUTTER_RETURN_BASE',
      defaultValue: 'http://127.0.0.1:65107',
    );
  }

  static String successReturnUrl() {
    final base = appReturnBase();
    final sep = base.contains('?') ? '&' : '?';
    return '$base${sep}stripe_success=1&session_id={CHECKOUT_SESSION_ID}';
  }

  static String cancelReturnUrl() {
    final base = appReturnBase();
    final sep = base.contains('?') ? '&' : '?';
    return '$base${sep}stripe_cancel=1';
  }

  /// Quick check before pay — skips in debug when server uses demo checkout.
  static Future<void> ensureLiveCheckoutMode() async {
    final base = await StripePaymentConfig.resolveBaseUrl();
    try {
      final res = await http
          .get(Uri.parse('$base/api/payment-mode/'))
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['mock_checkout'] == true) {
        if (kDebugMode) return;
        throw Exception(
          'Payment server is in DEMO mode (no Stripe page). '
          'Close Stripe window, run .\\RUN-STRIPE-SERVER.ps1 again (do NOT set MOCK=1).',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Cannot read payment mode from $base/api/payment-mode/');
    }
  }

  static Future<void> ensurePaymentServerReachable({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final base = await StripePaymentConfig.resolveBaseUrl();
    if (base.isEmpty) {
      throw Exception(
        'Payment server URL not set in this APK. '
        'Deploy strip payment gateway on Render, then rebuild: '
        '.\\RUN-BUILD-APK-LIVE.ps1 -StripeBase https://YOUR.onrender.com',
      );
    }
    try {
      final res = await http.get(Uri.parse('$base/')).timeout(timeout);
      if (res.statusCode >= 500) {
        throw Exception('Payment server error HTTP ${res.statusCode} at $base');
      }
    } on TimeoutException {
      throw Exception(
        'Payment server not responding ($base). '
        'Run: cd "strip payment gateway"; .\\RUN-STRIPE-SERVER.ps1 (port 8002 if Django uses :8000)',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Cannot reach payment server at $base — $e');
    }
  }

  static Future<StripeCheckoutSession> createCheckoutSession({
    required int amountPkr,
    required String productName,
    String description = '',
    Duration? timeout,
  }) async {
    final base = await StripePaymentConfig.resolveBaseUrl();
    final uri = Uri.parse('$base/api/create-checkout-session/');
    final request = http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount_pkr': amountPkr,
        'product_name': productName,
        'description': description,
        'success_url': successReturnUrl(),
        'cancel_url': cancelReturnUrl(),
      }),
    );
    final res = timeout != null
        ? await request.timeout(
            timeout,
            onTimeout: () => throw TimeoutException(
              'Payment server slow (${timeout.inSeconds}s). '
              'Stripe server slow — check strip payment gateway is running (:8002) and internet/VPN.',
            ),
          )
        : await request;

    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final err = data['error']?.toString() ?? res.body;
      throw Exception(err.isEmpty ? 'Stripe API error (${res.statusCode})' : err);
    }

    final url = data['url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('Stripe did not return a checkout URL');
    }
    final isMock = data['mock'] == true;
    if (isMock) {
      if (kDebugMode) {
        return StripeCheckoutSession(
          url: url,
          sessionId: data['session_id']?.toString(),
          isMock: true,
          message: data['message']?.toString(),
        );
      }
      throw Exception(
        data['message']?.toString() ??
            'Demo payment blocked. Restart Stripe server for real checkout.stripe.com '
            '(STRIPE_MOCK_CHECKOUT must be off). Try VPN if Pay was slow before.',
      );
    }
    if (!url.contains('checkout.stripe.com')) {
      throw Exception(
        'Expected Stripe Checkout URL (checkout.stripe.com). Got: $url',
      );
    }
    return StripeCheckoutSession(
      url: url,
      sessionId: data['session_id']?.toString(),
      isMock: false,
      message: data['message']?.toString(),
    );
  }

  static Future<void> openCheckoutUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(
      uri,
      webOnlyWindowName: kIsWeb ? '_self' : null,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
    if (!ok) {
      throw Exception('Could not open Stripe Checkout');
    }
  }
}
