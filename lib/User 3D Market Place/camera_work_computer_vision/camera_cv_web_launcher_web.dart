// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

import '../../2d_try_on_app/try_on_app_config.dart';
import 'camera_cv_config.dart';

/// Edge / Chrome: open pose scanner as a **top-level** page so the browser
/// (not the Flutter iframe) shows the native **Allow camera** dialog.
class CameraCvWebLauncher {
  CameraCvWebLauncher._();

  static const _measurementsKey = 'smartfitao_measurements';
  static const _payloadKey = 'smartfitao_cv_payload';
  static const _tryonPendingKey = 'smartfitao_open_tryon';

  static void openFromContinueGesture({
    required Map<String, double> measurementsCm,
    double? heightCm,
    double? weightKg,
    int? ageYears,
  }) {
    try {
      html.window.sessionStorage[_measurementsKey] =
          jsonEncode(measurementsCm);
    } catch (_) {}

    String? handoffB64;
    try {
      final handoff = <String, dynamic>{
        'measurements': measurementsCm,
      };
      const productKey = 'smartfitao_marketplace_product';
      const fitKey = 'snapmeasure_last_fit';
      final prod = html.window.sessionStorage[productKey];
      if (prod != null && prod.isNotEmpty) {
        handoff['product'] = jsonDecode(prod);
      }
      final fit = html.window.sessionStorage[fitKey];
      if (fit != null && fit.isNotEmpty) {
        handoff['lastFit'] = jsonDecode(fit);
      }
      handoffB64 = base64Url.encode(utf8.encode(jsonEncode(handoff)));
    } catch (_) {}

    final returnTo = html.window.location.href.split('#').first;
    // Return to same Flutter app (e.g. :65106) — no separate :65109 required.
    final tryonReturn = Uri.parse(returnTo).origin;
    final uri = CameraCvConfig.embedUriForApp(
      heightCm: heightCm,
      weightKg: weightKg,
      ageYears: ageYears,
      returnTo: returnTo,
      tryonReturn: tryonReturn,
      handoff: handoffB64,
    );
    html.window.location.assign(uri.toString());
  }

  static bool _openTryOnPending = false;

  /// True once after camera return when user tapped **2D Try On** on the capture popup.
  static bool consumeOpenTryOnFlag() {
    final v = _openTryOnPending;
    _openTryOnPending = false;
    return v;
  }

  /// Standalone try-on app (:65109) — clean URL, no ?cv_return in the address bar.
  static Map<String, dynamic>? consumeTryOnPayload() {
    _stripUrlQueryParams();
    try {
      if (html.window.sessionStorage[_tryonPendingKey] != '1') return null;
      html.window.sessionStorage.remove(_tryonPendingKey);
      final raw = html.window.sessionStorage[_payloadKey];
      if (raw == null || raw.isEmpty) return null;
      html.window.sessionStorage.remove(_payloadKey);
      final m = jsonDecode(raw);
      if (m is Map<String, dynamic>) return m;
      if (m is Map) return Map<String, dynamic>.from(m);
    } catch (_) {}
    return null;
  }

  static Map<String, dynamic>? consumeReturnPayload() {
    final params = Uri.base.queryParameters;
    if (params['cv_return'] != '1') return null;

    _openTryOnPending = params['open_tryon'] == '1';

    try {
      final raw = html.window.sessionStorage[_payloadKey];
      if (raw == null || raw.isEmpty) return null;
      html.window.sessionStorage.remove(_payloadKey);
      final m = jsonDecode(raw);
      if (m is! Map<String, dynamic>) return null;

      if (m['open_tryon'] == true) _openTryOnPending = true;

      _stripUrlQueryParams();

      return m;
    } catch (_) {}
    return null;
  }

  static void _stripUrlQueryParams() {
    final uri = Uri.base;
    if (uri.queryParameters.isEmpty) return;
    final clean = uri.replace(queryParameters: <String, String>{});
    html.window.history.replaceState(null, '', clean.toString());
  }
}
