import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'media_cdn_config.dart';

/// Loads `assets/remote_media_urls.json` — paste Cloudflare R2 / any https links.
class RemoteMediaResolver {
  RemoteMediaResolver._();

  static final RemoteMediaResolver instance = RemoteMediaResolver._();

  static const _assetPath = 'assets/remote_media_urls.json';

  Map<String, dynamic>? _data;
  Future<void>? _loadFuture;

  Future<void> ensureLoaded() {
    _loadFuture ??= _load();
    return _loadFuture!;
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      _data = jsonDecode(raw) as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('RemoteMediaResolver: no manifest ($e)');
      _data = null;
    }
  }

  String? _mapLookup(String mapKey, String key) {
    final root = _data;
    if (root == null) return null;
    final map = root[mapKey];
    if (map is! Map) return null;
    final v = map[key] ?? map[key.replaceAll('\\', '/')];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Full https URL for a reel file name, or null to use CDN base / Vercel / asset.
  String? reelUrlForFileName(String fileName) {
    final fromJson = _mapLookup('reelsByFileName', fileName);
    if (fromJson != null && _isHttp(fromJson)) return fromJson;
    if (MediaCdnConfig.useCustomCdn) {
      return MediaCdnConfig.urlForRelativePath('reels_videos/$fileName');
    }
    return null;
  }

  String? modelUrlForPath(String modelPath) {
    final key = modelPath.trim();
    final fromJson = _mapLookup('modelsByPath', key);
    if (fromJson != null && _isHttp(fromJson)) return fromJson;
    if (MediaCdnConfig.useCustomCdn) {
      return MediaCdnConfig.urlForRelativePath(key);
    }
    return null;
  }

  String? imageUrlForPath(String imagePath) {
    final key = imagePath.trim();
    final fromJson = _mapLookup('imagesByPath', key);
    if (fromJson != null && _isHttp(fromJson)) return fromJson;
    if (MediaCdnConfig.useCustomCdn) {
      return MediaCdnConfig.urlForRelativePath(key);
    }
    return null;
  }

  static bool _isHttp(String s) =>
      s.startsWith('http://') || s.startsWith('https://');
}
