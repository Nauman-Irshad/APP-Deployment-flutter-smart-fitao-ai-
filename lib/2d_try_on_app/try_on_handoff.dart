import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/customer_fitting_store.dart';
import '../services/customer_fitting_store_stub.dart'
    if (dart.library.html) '../services/customer_fitting_store_web.dart';
import '../User 3D Market Place/camera_work_computer_vision/camera_cv_config.dart';
import 'captured_photo_session.dart';
import 'try_on_order_session.dart';

String? _readWebLastFit() => kIsWeb ? webReadLastFitJson() : null;
String? _readWebMeasurements() => kIsWeb ? webReadMeasurementsJson() : null;

/// Cross-port handoff (marketplace → camera :5003 → try-on tab).
class TryOnHandoff {
  TryOnHandoff._();

  static String? _safeStr(Object? v) {
    if (v == null) return null;
    final s = v is String ? v : '$v';
    final t = s.trim();
    if (t.isEmpty || t == 'null') return null;
    return t;
  }

  static Map<String, dynamic>? decode(String encoded) {
    if (encoded.isEmpty) return null;
    final normalized = encoded.replaceAll(' ', '+');

    final decoders = <String Function(String)>[
      (s) => utf8.decode(base64Url.decode(base64Url.normalize(s))),
      (s) {
        var pad = s;
        final mod = pad.length % 4;
        if (mod > 0) pad += '=' * (4 - mod);
        return utf8.decode(base64.decode(pad));
      },
      (s) => Uri.decodeComponent(s),
    ];

    for (final decode in decoders) {
      try {
        final jsonStr = decode(normalized);
        final m = jsonDecode(jsonStr);
        if (m is Map<String, dynamic>) return m;
        if (m is Map) return Map<String, dynamic>.from(m);
      } catch (_) {}
    }
    return null;
  }

  static String encode(Map<String, dynamic> payload) {
    return base64Url.encode(utf8.encode(jsonEncode(payload)));
  }

  static Future<bool> applyFromQueryParam(String? encoded) async {
    if (encoded == null || encoded.isEmpty) return false;
    final data = decode(encoded);
    if (data == null) return false;
    await _applyPayload(data);
    return true;
  }

  /// Camera stores full handoff in sessionStorage (photo too large for URL).
  static Future<bool> applyFromSessionJson(String json) async {
    if (json.trim().isEmpty) return false;
    try {
      final m = jsonDecode(json);
      if (m is Map<String, dynamic>) {
        await _applyPayload(m);
        return true;
      }
      if (m is Map) {
        await _applyPayload(Map<String, dynamic>.from(m));
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> _applyPayload(Map<String, dynamic> data) async {
    final product = data['product'];
    if (product is Map) {
      final map = Map<String, dynamic>.from(product);
      await CustomerFittingStore.saveSelectedProduct(map);
      final garment = garmentFileForProduct(map);
      if (garment != null) {
        TryOnOrderSession.instance.applyGarment(garment);
      }
    }

    final lastFit = data['lastFit'];
    if (lastFit is Map) {
      CustomerFittingStore.webPersistLastFitJson(jsonEncode(lastFit));
      await CustomerFittingStore.applySavedSizeToSession();
    }

    final measurements = data['measurements'];
    if (measurements is Map) {
      final cm = <String, double>{};
      for (final e in measurements.entries) {
        final key = _safeStr(e.key);
        final v = e.value;
        if (key == null || v is! num) continue;
        cm[key] = v.toDouble();
      }
      if (cm.isNotEmpty) {
        TryOnOrderSession.instance.applyMeasurements(cm);
        CustomerFittingStore.webPersistMeasurementsJson(jsonEncode(cm));
      }
    }

    final capture = data['capture'];
    if (capture is Map) {
      await _applyCapture(Map<String, dynamic>.from(capture));
    }

    await CustomerFittingStore.syncSessionFromLocal();
  }

  static Future<void> _applyCapture(Map<String, dynamic> capture) async {
    final b64 = _safeStr(capture['person_jpeg_base64']) ??
        _safeStr(capture['jpeg_base64']);
    if (b64 != null) {
      try {
        final raw = b64.contains(',') ? b64.split(',').last : b64;
        Uint8List bytes;
        try {
          bytes = Uint8List.fromList(
            base64Url.decode(base64Url.normalize(raw)),
          );
        } catch (_) {
          bytes = Uint8List.fromList(base64.decode(raw));
        }
        CapturedPhotoSession.applyBytes(bytes, landmarks: _landmarksFrom(capture));
        return;
      } catch (_) {}
    }

    final imageUrl = resolveCaptureImageUrl(_safeStr(capture['image_url']));
    if (imageUrl.isNotEmpty) {
      CapturedPhotoSession.apply(
        url: imageUrl,
        landmarks: _landmarksFrom(capture),
      );
    }
  }

  static int _landmarksFrom(Map<String, dynamic> capture) {
    final lmRaw = capture['landmarks_count'];
    if (lmRaw is int) return lmRaw;
    if (lmRaw is num) return lmRaw.toInt();
    return int.tryParse(_safeStr(lmRaw) ?? '') ?? 0;
  }

  static String? garmentFileForProduct(Map<String, dynamic> product) {
    final color = (_safeStr(product['colorName']) ?? '').toLowerCase();
    final id = (_safeStr(product['id']) ?? '').toLowerCase();
    if (color.contains('black') || id.contains('black')) return '12.png';
    if (color.contains('white') || id.contains('white')) return '2.png';
    if (color.contains('blue') || id.contains('blue')) return '5.png';
    if (color.contains('green') || id.contains('green')) return '7.png';
    return '12.png';
  }

  static String resolveCaptureImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    var u = url.trim();
    if (u.startsWith('http://localhost:')) {
      u = u.replaceFirst('http://localhost:', 'http://127.0.0.1:');
    }
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    final base = CameraCvConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = u.startsWith('/') ? u : '/$u';
    return '$base$path';
  }

  static Future<Map<String, dynamic>> buildOutgoingPayload() async {
    final product = await CustomerFittingStore.loadSelectedProduct();
    Map<String, dynamic>? lastFit;
    Map<String, dynamic>? measurements;

    final fitRaw = _readWebLastFit();
    if (fitRaw != null && fitRaw.isNotEmpty) {
      try {
        final m = jsonDecode(fitRaw);
        if (m is Map) lastFit = Map<String, dynamic>.from(m);
      } catch (_) {}
    }

    final measRaw = _readWebMeasurements();
    if (measRaw != null && measRaw.isNotEmpty) {
      try {
        final m = jsonDecode(measRaw);
        if (m is Map) measurements = Map<String, dynamic>.from(m);
      } catch (_) {}
    }

    return {
      if (product != null) 'product': product,
      if (lastFit != null) 'lastFit': lastFit,
      if (measurements != null) 'measurements': measurements,
    };
  }
}
