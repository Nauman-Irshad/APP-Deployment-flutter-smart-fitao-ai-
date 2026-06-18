import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'firebase_media_upload_service.dart';
import 'upload_target.dart';

/// Pick tailor reel from gallery; upload to local dev server or Firebase Storage.
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

  static Future<PlatformFile?> pickVideoFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  static Future<Uint8List> _readXFile(XFile file) => file.readAsBytes();

  static Future<String?> _uploadToLocalServer({
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
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
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

  /// Local server when running; otherwise Firebase Storage (deployed app).
  static Future<String> uploadVideo({
    required Uint8List bytes,
    required String fileName,
    required String tailorId,
    void Function(String message)? onProgress,
  }) async {
    if (bytes.isEmpty) {
      throw StateError('Video file is empty');
    }
    final useLocal = !preferFirebaseUpload && await isServerReachable();
    if (useLocal) {
      final url = await _uploadToLocalServer(
        bytes: bytes,
        fileName: fileName,
        onProgress: onProgress,
      );
      if (url != null && url.isNotEmpty) return url;
    }
    return FirebaseMediaUploadService.uploadReelVideo(
      bytes: bytes,
      tailorId: tailorId,
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  static Future<String> uploadPickedVideo(
    XFile file, {
    required String tailorId,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Reading video…');
    final bytes = await _readXFile(file);
    return uploadVideo(
      bytes: bytes,
      fileName: file.name.isNotEmpty ? file.name : 'reel.mp4',
      tailorId: tailorId,
      onProgress: onProgress,
    );
  }
}
