import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'viewer_asset_src.dart';

/// Caches R2 / CDN GLB reachability (HEAD, then tiny GET).
class GlbUrlValidator {
  GlbUrlValidator._();

  static final Map<String, bool> _cache = <String, bool>{};
  static final Map<String, Future<bool>> _inFlight = <String, Future<bool>>{};

  static Future<bool> isReachable(String url) async {
    final key = url.trim();
    if (key.isEmpty) return false;
    // Firebase Storage GLBs work in model-viewer; HEAD often returns 403.
    if (_isFirebaseStorageUrl(key)) {
      _cache[key] = true;
      return true;
    }
    final cached = _cache[key];
    if (cached != null) return cached;

    return _inFlight.putIfAbsent(key, () async {
      try {
        final ok = await _probe(key);
        _cache[key] = ok;
        if (!ok) {
          debugPrint('GlbUrlValidator: unreachable $key');
        }
        return ok;
      } finally {
        _inFlight.remove(key);
      }
    });
  }

  static bool _isFirebaseStorageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('firebasestorage.googleapis.com') ||
        lower.contains('firebasestorage.app');
  }

  static Future<bool> _probe(String url) async {
    try {
      final head = await http
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      if (head.statusCode >= 200 && head.statusCode < 400) return true;
    } catch (_) {}

    try {
      final get = await http
          .get(
            Uri.parse(url),
            headers: const {'Range': 'bytes=0-1'},
          )
          .timeout(const Duration(seconds: 15));
      return get.statusCode == 200 || get.statusCode == 206;
    } catch (_) {
      return false;
    }
  }

  static Future<Set<String>> reachableProductIds(
    Iterable<Map<String, dynamic>> products,
  ) async {
    final ids = <String>{};
    final checks = <Future<void>>[];
    for (final p in products) {
      checks.add(() async {
        final section =
            p['section']?.toString() ?? p['category']?.toString() ?? '';
        if (section == 'Fabric') {
          final id = p['id']?.toString();
          if (id != null && id.isNotEmpty) ids.add(id);
          return;
        }
        if (!productHasRemoteGlbUrl(p)) return;
        final id = p['id']?.toString();
        if (id == null || id.isEmpty) return;
        final url = modelSrcForProduct(p);
        if (await isReachable(url)) ids.add(id);
      }());
    }
    await Future.wait(checks);
    return ids;
  }
}
