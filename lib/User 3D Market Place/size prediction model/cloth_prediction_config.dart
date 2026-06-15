import 'package:flutter/foundation.dart';

import '../../../config/live_backend_config.dart';
import '../../../config/production_urls.dart';

/// Size API: phone APK = always Render. Web = local only with SIZE_API_LOCAL=true.
class ClothPredictionConfig {
  ClothPredictionConfig._();

  static const String renderApiBase = ProductionUrls.sizeApi;
  static const String localApiBase = 'http://127.0.0.1:5001';

  static const _localHost = String.fromEnvironment('LOCAL_DEV_HOST', defaultValue: '');

  static String get baseUrl {
    const override = String.fromEnvironment('CLOTH_PREDICT_BASE', defaultValue: '');
    if (override.trim().isNotEmpty) {
      return override.trim().replaceAll(RegExp(r'/+$'), '');
    }
    final h = _localHost.trim();
    if (h.isNotEmpty) return 'http://$h:5001';

    // Real phone APK — never localhost / emulator.
    if (LiveBackendConfig.isPhoneOrTabletApp) return renderApiBase;

    if (LiveBackendConfig.useLocalOnWeb) return localApiBase;
    return renderApiBase;
  }

  static bool get usesLiveRender =>
      baseUrl.contains('onrender.com') || baseUrl == renderApiBase;

  static const String defaultStudioUrl = String.fromEnvironment(
    'CLOTH_STUDIO_URL',
    defaultValue: ProductionUrls.shop,
  );

  static Uri uri(String path) {
    final b = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$b$p');
  }
}
