import 'dart:io';
import 'dart:typed_data';

import 'seller_3d_folder_reader.dart';

class Seller3dFolderIo implements Seller3dFolderReader {
  static final Seller3dFolderReader instance = Seller3dFolderIo();

  static final RegExp _useful = RegExp(
    r'\.(glb|gltf|bin|png|jpe?g|webp)$',
    caseSensitive: false,
  );

  @override
  Future<List<Seller3dFolderFile>> readDirectory(String dir) async {
    final root = Directory(dir);
    if (!await root.exists()) return [];

    final out = <Seller3dFolderFile>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final rel = entity.path
          .substring(root.path.length + 1)
          .replaceAll('\\', '/');
      if (!_useful.hasMatch(rel)) continue;
      out.add(Seller3dFolderFile(rel, await entity.readAsBytes()));
    }
    return out;
  }

  @override
  Future<Uint8List> readPath(String path) async => File(path).readAsBytes();
}
