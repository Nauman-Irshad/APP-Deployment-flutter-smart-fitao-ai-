// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void stripStripeQueryFromUrl() {
  final path = html.window.location.pathname;
  if (path != null && path.isNotEmpty) {
    html.window.history.replaceState(null, '', path);
  }
}
