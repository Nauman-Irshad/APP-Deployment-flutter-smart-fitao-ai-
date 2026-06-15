import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

/// Flutter Web does not always invoke plugin registrants before widgets build.
void registerWebViewPlatformForWeb() {
  WebViewPlatform.instance ??= WebWebViewPlatform();
}
