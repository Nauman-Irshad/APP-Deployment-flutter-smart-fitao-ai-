import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'try_on_config.dart';
import 'try_on_image_prep.dart';

class TryOnGarmentService {
  TryOnGarmentService._();

  static List<String>? _cached;
  static final Map<String, Uint8List> _preparedCache = {};

  static Future<List<String>> loadGarmentNames() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString(
      'assets/2d_try_on_garments/manifest.json',
    );
    final decoded = jsonDecode(raw);
    final names = decoded is Map ? decoded['names'] : null;
    if (names is! List) {
      throw StateError('Invalid garments manifest.json');
    }
    _cached = names.map((e) => e.toString()).toList()..sort();
    return _cached!;
  }

  static String displayName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'\.[^.]+$'), '')
        .replaceAll(RegExp(r'[-_]'), ' ');
  }

  static String assetImagePath(String fileName) =>
      TryOnConfig.assetGarmentPath(fileName);

  static String? networkImageUrl(String fileName) =>
      TryOnConfig.remoteGarmentUrl(fileName);

  /// Kurta bytes for API — cached + resized to 512px (HF fast path).
  static Future<Uint8List> loadGarmentBytes(String fileName) async {
    final cached = _preparedCache[fileName];
    if (cached != null) return cached;

    Uint8List raw;
    final remote = networkImageUrl(fileName);
    if (remote != null) {
      try {
        final res = await http.get(Uri.parse(remote));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          raw = Uint8List.fromList(res.bodyBytes);
        } else {
          raw = await _loadAssetBytes(fileName);
        }
      } catch (_) {
        raw = await _loadAssetBytes(fileName);
      }
    } else {
      raw = await _loadAssetBytes(fileName);
    }

    final prepared = TryOnImagePrep.garment(raw);
    _preparedCache[fileName] = prepared;
    return prepared;
  }

  static Future<Uint8List> _loadAssetBytes(String fileName) async {
    final data = await rootBundle.load(assetImagePath(fileName));
    return data.buffer.asUint8List();
  }

  /// Warm cache so Run Try-On does not wait on garment resize.
  static Future<void> preloadGarments([List<String>? names]) async {
    final list = names ?? await loadGarmentNames();
    await Future.wait(
      list.map((n) => loadGarmentBytes(n).catchError((_) => Uint8List(0))),
    );
  }
}
