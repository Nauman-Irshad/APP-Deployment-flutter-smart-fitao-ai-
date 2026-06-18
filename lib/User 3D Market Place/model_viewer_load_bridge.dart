import 'package:flutter/foundation.dart';

/// Loading / error state for [ProductModelPreview] (web model-viewer + mobile).
class ModelViewerLoadBridge extends ChangeNotifier {
  ModelViewerLoadBridge._();

  static final Map<String, ModelViewerLoadBridge> _cache = {};

  static ModelViewerLoadBridge forKey(String key) {
    return _cache.putIfAbsent(key, () => ModelViewerLoadBridge._());
  }

  int step = 1;
  int progress = 0;
  bool loaded = false;
  String? errorMessage;

  void setStep(int s, {int? progressPercent}) {
    step = s.clamp(1, 3);
    if (progressPercent != null) {
      progress = progressPercent.clamp(0, 100);
    }
    notifyListeners();
  }

  void setProgress(int percent) {
    progress = percent.clamp(0, 100);
    notifyListeners();
  }

  void markLoaded() {
    step = 3;
    progress = 100;
    loaded = true;
    errorMessage = null;
    notifyListeners();
  }

  void markError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  void reset() {
    step = 1;
    progress = 0;
    loaded = false;
    errorMessage = null;
    notifyListeners();
  }
}
