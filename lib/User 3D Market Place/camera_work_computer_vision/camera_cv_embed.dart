// Mobile/desktop: webview_flutter. Web: iframe with camera/microphone allow.
export 'camera_cv_embed_mobile.dart'
    if (dart.library.html) 'camera_cv_embed_web.dart';
