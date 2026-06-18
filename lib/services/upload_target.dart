import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

/// When true, seller/tailor uploads go to Firebase Storage (not localhost:5190).
bool get preferFirebaseUpload {
  if (const bool.fromEnvironment('FORCE_FIREBASE_UPLOAD', defaultValue: false)) {
    return true;
  }
  if (kIsWeb) {
    final host = Uri.base.host.toLowerCase();
    if (host != 'localhost' && host != '127.0.0.1') return true;
  }
  // Release APK / desktop build → cloud
  if (!kDebugMode) return true;
  return false;
}
