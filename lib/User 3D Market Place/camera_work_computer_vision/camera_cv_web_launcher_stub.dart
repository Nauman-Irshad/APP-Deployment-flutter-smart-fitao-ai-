/// Non-web: camera stays in-app (WebView / iframe not used on mobile via this launcher).
class CameraCvWebLauncher {
  CameraCvWebLauncher._();

  static void openFromContinueGesture({
    required Map<String, double> measurementsCm,
    double? heightCm,
    double? weightKg,
    int? ageYears,
  }) {}

  static Map<String, dynamic>? consumeReturnPayload() => null;

  static Map<String, dynamic>? consumeTryOnPayload() => null;

  static bool consumeOpenTryOnFlag() => false;
}
