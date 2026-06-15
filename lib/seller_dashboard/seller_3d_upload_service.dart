import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'seller_3d_file_picker.dart';
import 'seller_3d_folder.dart';

/// Uploads GLB folder to local product server (same as React `sellerProducts.js`).
/// Start server: `App\scripts\start-local-product-server.ps1` (port 5190).
class Seller3dUploadService {
  Seller3dUploadService._();

  static const String apiBase = String.fromEnvironment(
    'LOCAL_PRODUCT_API_BASE',
    defaultValue: 'http://127.0.0.1:5190',
  );

  static String get _api => apiBase.replaceAll(RegExp(r'/+$'), '');

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

  /// Pick `.glb` and related files (textures, .bin). Works on web (Edge) and desktop.
  static Future<List<PlatformFile>> pickModelFiles() =>
      Seller3dFilePicker.pickModelFiles();

  /// Pick a folder (Windows) or whole folder on Edge (webkitdirectory).
  static Future<List<PlatformFile>> pickModelFolder() =>
      Seller3dFilePicker.pickModelFolder();

  static Future<Uint8List> _readFileBytes(PlatformFile f) async {
    if (f.bytes != null) return f.bytes!;
    if (f.path != null && f.path!.isNotEmpty) {
      return Seller3dFolderIo.instance.readPath(f.path!);
    }
    throw StateError('Could not read ${f.name}');
  }

  static Future<String?> uploadFilesAsZip({
    required List<PlatformFile> files,
    void Function(String message)? onProgress,
  }) async {
    if (files.isEmpty) return null;

    onProgress?.call('Preparing zip…');
    final archive = Archive();
    var entryGlb = 'model.glb';

    for (final f in files) {
      final name = f.name.replaceAll('\\', '/');
      if (name.isEmpty) continue;
      final bytes = await _readFileBytes(f);
      final zipName = name.contains('/') ? name.split('/').last : name;
      archive.addFile(ArchiveFile(zipName, bytes.length, bytes));
      if (RegExp(r'\.glb$', caseSensitive: false).hasMatch(zipName)) {
        entryGlb = zipName;
      }
    }

    if (archive.files.isEmpty) {
      throw StateError(
        'No .glb / .gltf / image files in selection. Pick your model.glb and textures.',
      );
    }

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw StateError('Failed to zip 3D files');
    }
    final zipBytes = Uint8List.fromList(encoded);
    final productKey = '${DateTime.now().millisecondsSinceEpoch}';
    final archiveName = '$productKey-3d-model.zip';

    onProgress?.call('Uploading to local 3D server (port 5190)…');

    final uri = Uri.parse(
      '$_api/api/local-products/archive?productKey=$productKey&fileName=${Uri.encodeComponent(archiveName)}',
    );
    final res = await http.put(
      uri,
      headers: {'content-type': 'application/zip'},
      body: zipBytes,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError(
        'Upload failed (${res.statusCode}). Start the local product server: App\\scripts\\start-local-product-server.ps1',
      );
    }

    final body = jsonDecode(res.body);
    if (body is! Map) {
      throw StateError('Invalid response from local product server');
    }

    final direct = body['directModelUrl']?.toString() ?? '';
    if (direct.isEmpty) {
      return '$_api/local-products/models/$productKey/$entryGlb';
    }
    if (direct.startsWith('http')) return direct;
    return '$_api$direct';
  }

  static String? previewImageUrl(List<PlatformFile> files, String productKey) {
    for (final f in files) {
      final name = f.name.toLowerCase();
      if (RegExp(r'\.(png|jpe?g|webp)$').hasMatch(name)) {
        final base = name.split('/').last;
        return '$_api/local-products/models/$productKey/$base';
      }
    }
    return null;
  }

  static Future<void> saveProductToLocalCatalog(Map<String, dynamic> product) async {
    final res = await http.post(
      Uri.parse('$_api/api/local-products'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(product),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('Local catalog save failed (${res.statusCode})');
    }
  }
}
