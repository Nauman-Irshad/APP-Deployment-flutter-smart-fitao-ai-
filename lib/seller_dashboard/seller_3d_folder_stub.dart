import 'dart:typed_data';

import 'seller_3d_folder_reader.dart';

class Seller3dFolderIo implements Seller3dFolderReader {
  static final Seller3dFolderReader instance = Seller3dFolderIo();

  @override
  Future<List<Seller3dFolderFile>> readDirectory(String dir) async => [];

  @override
  Future<Uint8List> readPath(String path) async {
    throw UnsupportedError('Folder pick is not supported on web — use "Pick GLB files"');
  }
}
