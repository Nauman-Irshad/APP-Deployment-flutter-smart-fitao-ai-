import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Pick tailor reel from gallery and upload to local media server (port 5190).
class TailorReelUploadService {
  TailorReelUploadService._();

  static const String apiBase = String.fromEnvironment(
    'LOCAL_PRODUCT_API_BASE',
    defaultValue: 'http://127.0.0.1:5190',
  );

  static String get _api => apiBase.replaceAll(RegExp(r'/+$'), '');

  static final _picker = ImagePicker();

  static Future<bool> isServerReachable() async {
    try {
      final res = await http
          .get(Uri.parse('$_api/api/local-products'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Gallery / photo library video picker.
  static Future<XFile?> pickVideoFromGallery() async {
    try {
      return await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
    } catch (_) {
      return null;
    }
  }

  /// Fallback file picker (some desktops / web).
  static Future<PlatformFile?> pickVideoFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  static Future<Uint8List> _readXFile(XFile file) async {
    if (kIsWeb) {
      return await file.readAsBytes();
    }
    return await file.readAsBytes();
  }

  static Future<String?> uploadVideoBytes({
    required Uint8List bytes,
    required String fileName,
    void Function(String message)? onProgress,
  }) async {
    if (bytes.isEmpty) return null;
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final reelKey = '${DateTime.now().millisecondsSinceEpoch}';
    onProgress?.call('Uploading video…');

    final uri = Uri.parse(
      '$_api/api/local-reels/video?reelKey=$reelKey&fileName=${Uri.encodeComponent(safeName)}',
    );
    final res = await http.put(
      uri,
      headers: {'content-type': 'video/mp4'},
      body: bytes,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError(
        'Video upload failed (${res.statusCode}). Run App\\scripts\\start-local-product-server.ps1',
      );
    }
    final body = jsonDecode(res.body);
    if (body is Map) {
      final url = body['videoUrl']?.toString() ?? '';
      if (url.isNotEmpty) {
        if (url.startsWith('http')) return url;
        return '$_api$url';
      }
    }
    return '$_api/local-reels/videos/$reelKey/$safeName';
  }

  static Future<String?> uploadPickedVideo(
    XFile file, {
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Reading video…');
    final bytes = await _readXFile(file);
    return uploadVideoBytes(
      bytes: bytes,
      fileName: file.name.isNotEmpty ? file.name : 'reel.mp4',
      onProgress: onProgress,
    );
  }
}
