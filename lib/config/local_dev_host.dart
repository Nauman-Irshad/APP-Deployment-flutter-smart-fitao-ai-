import 'package:flutter/foundation.dart';

/// One flag for physical phone / emulator talking to PC backends on Wi‑Fi.
///
/// `flutter run -d android --dart-define=LOCAL_DEV_HOST=192.168.1.5`
class LocalDevHost {
  LocalDevHost._();

  static const String _host = String.fromEnvironment(
    'LOCAL_DEV_HOST',
    defaultValue: '',
  );

  static String? get pcHost {
    final h = _host.trim();
    if (h.isEmpty) return null;
    return h;
  }

  static bool get usePcOnWifi => pcHost != null;

  /// Android emulator → host machine localhost.
  static String get defaultHost {
    final override = pcHost;
    if (override != null) return override;
    if (kIsWeb) return '127.0.0.1';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }

  static String httpPort(int port) => 'http://${defaultHost}:$port';
}
