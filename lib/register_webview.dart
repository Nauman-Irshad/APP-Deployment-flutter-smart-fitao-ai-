import 'webview_platform_register_stub.dart'
    if (dart.library.html) 'webview_platform_register_web.dart';

/// Call once after [WidgetsFlutterBinding.ensureInitialized] when the app uses
/// [webview_flutter] on **web** (Edge/Chrome). Safe on mobile/desktop (no-op).
void ensureWebViewPlatformRegistered() => registerWebViewPlatformForWeb();
