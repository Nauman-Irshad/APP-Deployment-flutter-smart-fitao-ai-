// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

const _key = 'smartfitao_pending_stripe_checkout';

void webSavePendingCheckout(String json) {
  try {
    html.window.sessionStorage[_key] = json;
  } catch (_) {}
}

String? webLoadPendingCheckout() {
  try {
    return html.window.sessionStorage[_key];
  } catch (_) {
    return null;
  }
}

void webClearPendingCheckout() {
  try {
    html.window.sessionStorage.remove(_key);
  } catch (_) {}
}
