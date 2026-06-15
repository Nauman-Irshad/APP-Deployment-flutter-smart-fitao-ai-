import 'package:flutter/foundation.dart';

/// Phone APK / tablet: always use [ProductionUrls] (deployed). Web: local optional.
class LiveBackendConfig {
  LiveBackendConfig._();

  /// True on Android/iOS builds (including release APK on a real phone).
  static bool get isPhoneOrTabletApp => !kIsWeb;

  static const bool _sizeApiLocal =
      bool.fromEnvironment('SIZE_API_LOCAL', defaultValue: false);

  /// Edge at http://127.0.0.1:65106 — use local Flask without extra dart-defines.
  static bool get _isLocalWebHost {
    if (!kIsWeb) return false;
    final h = Uri.base.host.toLowerCase();
    return h == '127.0.0.1' || h == 'localhost';
  }

  static bool get useLocalOnWeb => kIsWeb && (_sizeApiLocal || _isLocalWebHost);
}
