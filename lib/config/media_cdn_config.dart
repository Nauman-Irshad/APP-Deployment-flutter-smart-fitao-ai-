import 'production_urls.dart';

/// Cloudflare R2 (or override with `--dart-define=MEDIA_CDN_BASE=...`).
class MediaCdnConfig {
  MediaCdnConfig._();

  static const String _envBase = String.fromEnvironment(
    'MEDIA_CDN_BASE',
    defaultValue: '',
  );

  static String get cdnBase {
    final e = _envBase.trim();
    if (e.isNotEmpty) return e.endsWith('/') ? e.substring(0, e.length - 1) : e;
    return ProductionUrls.mediaCdn;
  }

  static bool get useCustomCdn => cdnBase.isNotEmpty;

  static String urlForRelativePath(String relativePath) {
    var p = relativePath.trim().replaceAll('\\', '/');
    if (p.isEmpty) return '';
    var base = cdnBase;
    if (!base.endsWith('/')) base = '$base/';
    if (p.startsWith('/')) p = p.substring(1);
    return '$base$p';
  }
}
