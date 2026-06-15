// Mobile/desktop: webview_flutter. Web (Edge/Chrome): iframe — setJavaScriptMode is not supported on web.
export 'ai_chatbot_mobile.dart'
    if (dart.library.html) 'ai_chatbot_web.dart';
