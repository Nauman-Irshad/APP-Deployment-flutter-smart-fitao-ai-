/// Set when user taps **Continue to Camera** so the CV iframe starts on load
/// (same user-gesture chain on Edge).
class CameraCvGestureBridge {
  CameraCvGestureBridge._();

  static var _armed = false;

  static void arm() => _armed = true;

  static bool consume() {
    if (!_armed) return false;
    _armed = false;
    return true;
  }
}
