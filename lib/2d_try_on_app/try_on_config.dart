import '../config/live_backend_config.dart';
import '../config/production_urls.dart';

/// Matches [id-2d-try-on] — FastAPI on 8765, garments bundled in assets.
class TryOnConfig {
  TryOnConfig._();

  static const _apiFromEnv = String.fromEnvironment(
    'TRYON_API_BASE',
    defaultValue: '',
  );

  static const _garmentCdnFromEnv = String.fromEnvironment(
    'TRYON_GARMENT_CDN',
    defaultValue: '',
  );

  static const kurtaDescription =
      'Pakistani kameez kurta upper body, loose festive traditional wear, not shirt not t-shirt';

  /// `npm run api` in id-2d-try-on (port 8765).
  static const _localHost = String.fromEnvironment('LOCAL_DEV_HOST', defaultValue: '');

  static String get apiBase {
    if (_apiFromEnv.isNotEmpty) return _apiFromEnv.replaceAll(RegExp(r'/+$'), '');
    final h = _localHost.trim();
    if (h.isNotEmpty) return 'http://$h:8765';
    if (LiveBackendConfig.isPhoneOrTabletApp) {
      return ProductionUrls.shop.replaceAll(RegExp(r'/+$'), '');
    }
    if (LiveBackendConfig.useLocalOnWeb) return 'http://127.0.0.1:8765';
    return ProductionUrls.shop.replaceAll(RegExp(r'/+$'), '');
  }

  static String apiUrl(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return '$apiBase$p';
  }

  /// Bundled kurta images (synced from id-2d-try-on/public/garments).
  static String assetGarmentPath(String fileName) =>
      'assets/2d_try_on_garments/$fileName';

  /// Optional override only — default is bundled [assets/2d_try_on_garments].
  static String? get remoteGarmentBase {
    if (_garmentCdnFromEnv.isEmpty) return null;
    return _garmentCdnFromEnv.replaceAll(RegExp(r'/+$'), '');
  }

  static String? remoteGarmentUrl(String fileName) {
    final base = remoteGarmentBase;
    if (base == null) return null;
    return '$base/${Uri.encodeComponent(fileName)}';
  }
}
