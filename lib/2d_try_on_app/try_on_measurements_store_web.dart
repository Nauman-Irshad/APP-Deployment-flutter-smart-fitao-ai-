// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

Map<String, double>? loadTryOnMeasurementsCm() {
  try {
    final raw = html.window.sessionStorage['smartfitao_measurements'];
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final out = <String, double>{};
    decoded.forEach((k, v) {
      final key = k.toString();
      if (v is num) out[key] = v.toDouble();
    });
    return out.isEmpty ? null : out;
  } catch (_) {
    return null;
  }
}
