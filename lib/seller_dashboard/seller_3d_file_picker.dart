import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'seller_3d_folder.dart';
import 'seller_3d_web_picker.dart';

/// Picks GLB / textures — web uses native browser dialog (Edge-safe).
class Seller3dFilePicker {
  Seller3dFilePicker._();

  static final RegExp _useful = RegExp(
    r'\.(glb|gltf|bin|png|jpe?g|webp|zip)$',
    caseSensitive: false,
  );

  static List<PlatformFile> _filter(List<PlatformFile>? files) {
    if (files == null || files.isEmpty) return [];
    return files
        .where((f) {
          final n = f.name.toLowerCase();
          return _useful.hasMatch(n) &&
              (f.bytes != null || (f.path != null && f.path!.isNotEmpty));
        })
        .toList();
  }

  static Future<List<PlatformFile>> pickModelFiles() async {
    if (kIsWeb) {
      final picked = await Seller3dWebPicker.pick(folder: false);
      return _filter(picked);
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
      dialogTitle: 'Select .glb and texture files',
      withData: false,
    );
    if (result == null || result.files.isEmpty) return [];
    return _filter(result.files);
  }

  static Future<List<PlatformFile>> pickModelFolder() async {
    if (kIsWeb) {
      final picked = await Seller3dWebPicker.pick(folder: true);
      return _filter(picked);
    }

    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select folder with .glb model',
    );
    if (dir == null || dir.isEmpty) return [];

    final folderFiles = await Seller3dFolderIo.instance.readDirectory(dir);
    return folderFiles
        .map(
          (f) => PlatformFile(
            name: f.relativePath,
            size: f.bytes.length,
            bytes: f.bytes,
          ),
        )
        .toList();
  }
}
