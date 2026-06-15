// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

const _productKey = 'smartfitao_marketplace_product';
const _lastFitKey = 'snapmeasure_last_fit';
const _measurementsKey = 'smartfitao_measurements';
const _tryonHandoffKey = 'smartfitao_tryon_handoff';

void webWriteProductJson(String json) {
  try {
    html.window.sessionStorage[_productKey] = json;
  } catch (_) {}
}

String? webReadProductJson() {
  try {
    return html.window.sessionStorage[_productKey];
  } catch (_) {
    return null;
  }
}

void webWriteLastFitJson(String json) {
  try {
    html.window.sessionStorage[_lastFitKey] = json;
  } catch (_) {}
}

String? webReadLastFitJson() {
  try {
    return html.window.sessionStorage[_lastFitKey];
  } catch (_) {
    return null;
  }
}

void webWriteMeasurementsJson(String json) {
  try {
    html.window.sessionStorage[_measurementsKey] = json;
  } catch (_) {}
}

String? webReadMeasurementsJson() {
  try {
    return html.window.sessionStorage[_measurementsKey];
  } catch (_) {}
}

void webWriteTryonHandoffJson(String json) {
  try {
    html.window.sessionStorage[_tryonHandoffKey] = json;
  } catch (_) {}
}

String? webReadTryonHandoffJson() {
  try {
    return html.window.sessionStorage[_tryonHandoffKey];
  } catch (_) {
    return null;
  }
}

void webClearTryonHandoff() {
  try {
    html.window.sessionStorage.remove(_tryonHandoffKey);
  } catch (_) {}
}

void webClearHandoffQuery() {
  try {
    final uri = Uri.base;
    final q = uri.queryParameters;
    if (!q.containsKey('handoff') && !q.containsKey('open_tryon')) return;
    final clean = uri.replace(queryParameters: <String, String>{});
    html.window.history.replaceState(null, '', clean.toString());
  } catch (_) {}
}
