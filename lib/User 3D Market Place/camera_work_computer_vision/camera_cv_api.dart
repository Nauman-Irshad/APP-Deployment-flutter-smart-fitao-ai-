import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'camera_cv_config.dart';
import 'camera_cv_models.dart';

/// Calls Flask `POST /analyze` (same contract as the pose web UI).
class CameraCvApi {
  CameraCvApi._();
  static final CameraCvApi instance = CameraCvApi._();

  /// Sends a JPEG/PNG image; returns parsed human metrics.
  Future<CameraCvHumanEvent> analyzeImageBytes(
    Uint8List imageBytes, {
    String filename = 'capture.jpg',
  }) async {
    final uri = CameraCvConfig.uri('/analyze');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: filename,
        ),
      );

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    Map<String, dynamic> map;
    try {
      map = jsonDecode(body.isEmpty ? '{}' : body) as Map<String, dynamic>;
    } catch (_) {
      throw CameraCvApiException('Invalid JSON from server');
    }

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final err = map['error'];
      throw CameraCvApiException(
        err is String ? err : 'HTTP ${streamed.statusCode}',
      );
    }

    final hp = map['human_probability'];
    final prob = hp is num ? hp.toDouble() : 0.0;
    final hd = map['human_detected'];
    final detected = hd is bool ? hd : false;
    final lc = map['landmarks_count'];
    final count = lc is int ? lc : (lc is num ? lc.toInt() : 0);
    final msg = map['message'] as String?;

    return CameraCvHumanEvent(
      phase: 'capture',
      humanDetected: detected,
      humanProbability: prob.clamp(0.0, 1.0),
      landmarksCount: count,
      message: msg,
      poseRecord: null,
    );
  }
}

class CameraCvApiException implements Exception {
  CameraCvApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
