import 'package:flutter/foundation.dart';

import '../../config/live_backend_config.dart';
import '../../config/production_urls.dart';

/// CV camera — phone APK uses Vercel; Edge/web uses local Flask :5003 (no Vercel login).
class CameraCvConfig {
  CameraCvConfig._();

  static const String _envBase = String.fromEnvironment(
    'CV_CAMERA_BASE',
    defaultValue: '',
  );

  static const String _localHost = String.fromEnvironment(
    'LOCAL_DEV_HOST',
    defaultValue: '',
  );

  static bool get _isLocalWebHost {
    if (!kIsWeb) return false;
    final h = Uri.base.host.toLowerCase();
    return h == '127.0.0.1' || h == 'localhost';
  }

  static String get baseUrl {
    var b = _envBase.trim();
    if (b.isEmpty) {
      final localHost = _localHost.trim();
      final useLocalCv = localHost.isNotEmpty ||
          (kIsWeb && (_isLocalWebHost || LiveBackendConfig.useLocalOnWeb));
      if (LiveBackendConfig.isPhoneOrTabletApp || !useLocalCv) {
        b = ProductionUrls.cvCamera;
      } else {
        b = localHost.isNotEmpty
            ? 'http://$localHost:5003'
            : 'http://127.0.0.1:5003';
      }
    }
    if (!b.contains('://')) b = 'http://$b';
    return b.replaceAll(RegExp(r'/+$'), '');
  }

  static Uri get baseUri => Uri.parse(baseUrl);

  static Uri get embedUri => embedUriForApp();

  static String get embedUrl => embedUri.toString();

  static Uri embedUriForApp({
    double? heightCm,
    double? weightKg,
    int? ageYears,
    String? returnTo,
    String? tryonReturn,
    String? handoff,
  }) {
    final q = Map<String, String>.from(baseUri.queryParameters);
    q['flutter_embed'] = '1';
    q['app_mode'] = '1';
    q['auto_start'] = '1';
    q['fast'] = '1';
    if (returnTo != null && returnTo.trim().isNotEmpty) {
      q['return_to'] = returnTo.trim();
    }
    if (tryonReturn != null && tryonReturn.trim().isNotEmpty) {
      q['tryon_return'] = tryonReturn.trim();
    }
    if (handoff != null && handoff.trim().isNotEmpty) {
      q['handoff'] = handoff.trim();
    }
    q['min_landmarks'] = '30';
    q['timer_sec'] = '3';
    q['capture_v'] = '20260604_landmarks';
    if (heightCm != null && heightCm > 0) {
      q['height_cm'] = heightCm.toString();
    }
    if (weightKg != null && weightKg > 0) {
      q['weight_kg'] = weightKg.toString();
    }
    if (ageYears != null && ageYears > 0) {
      q['age'] = ageYears.toString();
    }
    return baseUri.replace(queryParameters: q);
  }

  static String embedUrlForApp({
    double? heightCm,
    double? weightKg,
    int? ageYears,
    String? returnTo,
    String? tryonReturn,
  }) =>
      embedUriForApp(
        heightCm: heightCm,
        weightKg: weightKg,
        ageYears: ageYears,
        returnTo: returnTo,
        tryonReturn: tryonReturn,
      ).toString();

  static Uri uri(String path) {
    final b =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$b$p');
  }
}
