// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'viewer_asset_src.dart';

/// Web: Firebase Storage download URLs often fail in model-viewer (CORS + crossorigin).
/// Load bytes via the Firebase SDK, then feed a same-origin blob URL to model-viewer.
Future<String> resolveGlbSrcForViewer(String src) async {
  final trimmed = src.trim();
  if (trimmed.isEmpty) return trimmed;
  if (!isFirebaseStorageGlbUrl(trimmed)) return trimmed;

  try {
    final ref = FirebaseStorage.instance.refFromURL(trimmed);
    final Uint8List? bytes = await ref.getData(100 * 1024 * 1024);
    if (bytes == null || bytes.isEmpty) {
      debugPrint('resolveGlbSrcForViewer: empty bytes for $trimmed');
      return trimmed;
    }
    final blob = html.Blob([bytes]);
    return html.Url.createObjectUrlFromBlob(blob);
  } catch (e, st) {
    debugPrint('resolveGlbSrcForViewer firebase blob: $e\n$st');
    return trimmed;
  }
}
