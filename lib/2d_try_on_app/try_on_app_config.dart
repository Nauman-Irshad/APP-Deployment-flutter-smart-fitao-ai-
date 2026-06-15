import 'package:flutter/foundation.dart';

/// Standalone 2D try-on Flutter web app URL (separate from marketplace port).
class TryOnAppConfig {
  TryOnAppConfig._();

  static const _envBase = String.fromEnvironment(
    'TRYON_APP_BASE',
    defaultValue: '',
  );

  static const _localHost = String.fromEnvironment('LOCAL_DEV_HOST', defaultValue: '');

  static String get baseUrl {
    var b = _envBase.trim();
    if (b.isEmpty) {
      if (kIsWeb) {
        final origin = Uri.base.origin;
        final host = Uri.base.host.toLowerCase();
        if (host == '127.0.0.1' || host == 'localhost') {
          b = origin;
        }
      }
      if (b.isEmpty) {
        final h = _localHost.trim();
        b = h.isNotEmpty ? 'http://$h:65109' : 'http://127.0.0.1:65109';
      }
    }
    if (!b.contains('://')) b = 'http://$b';
    return b.replaceAll(RegExp(r'/+$'), '');
  }
}
