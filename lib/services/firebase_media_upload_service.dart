import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../seller_dashboard/seller_3d_folder.dart';

/// Production uploads (Vercel / APK) — Firebase Storage public URLs.
class FirebaseMediaUploadService {
  FirebaseMediaUploadService._();

  static Future<Uint8List> _readFileBytes(PlatformFile f) async {
    if (f.bytes != null) return f.bytes!;
    if (f.path != null && f.path!.isNotEmpty) {
      return Seller3dFolderIo.instance.readPath(f.path!);
    }
    throw StateError('Could not read ${f.name}');
  }

  static String _baseName(String name) {
    final n = name.replaceAll('\\', '/');
    return n.contains('/') ? n.split('/').last : n;
  }

  /// Upload main `.glb` (+ optional preview image) for seller marketplace listing.
  static Future<({String modelUrl, String? imageUrl})> uploadSellerModelFiles({
    required List<PlatformFile> files,
    required String sellerId,
    required String productKey,
    void Function(String message)? onProgress,
  }) async {
    PlatformFile? glb;
    PlatformFile? image;
    for (final f in files) {
      final lower = f.name.toLowerCase();
      if (lower.endsWith('.glb')) glb = f;
      if (RegExp(r'\.(png|jpe?g|webp)$').hasMatch(lower)) image = f;
    }
    if (glb == null) {
      throw StateError('No .glb file found. Pick your 3D model file.');
    }

    onProgress?.call('Uploading 3D model to cloud…');
    final glbBytes = await _readFileBytes(glb);
    final glbName = _baseName(glb.name);
    // Flat path: seller-products/{uid}/{file} — matches Storage rules (video uses same depth).
    final storageName = '${productKey}_$glbName';
    final modelRef = FirebaseStorage.instance.ref().child(
      'seller-products/$sellerId/$storageName',
    );
    await modelRef.putData(
      glbBytes,
      SettableMetadata(contentType: 'model/gltf-binary'),
    );
    final modelUrl = await modelRef.getDownloadURL();

    String? imageUrl;
    if (image != null) {
      onProgress?.call('Uploading preview image…');
      final imgBytes = await _readFileBytes(image);
      final imgName = _baseName(image.name);
      final imgStorageName = '${productKey}_$imgName';
      final imgRef = FirebaseStorage.instance.ref().child(
        'seller-products/$sellerId/$imgStorageName',
      );
      final ext = imgName.split('.').last.toLowerCase();
      final mime = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';
      await imgRef.putData(imgBytes, SettableMetadata(contentType: mime));
      imageUrl = await imgRef.getDownloadURL();
    }

    return (modelUrl: modelUrl, imageUrl: imageUrl);
  }

  static Future<String> uploadReelVideo({
    required Uint8List bytes,
    required String tailorId,
    required String fileName,
    void Function(String message)? onProgress,
  }) async {
    if (bytes.isEmpty) {
      throw StateError('Video file is empty');
    }
    onProgress?.call('Uploading video to cloud…');
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        'marketplace-reels/$tailorId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'video/mp4'),
    );
    return ref.getDownloadURL();
  }
}
