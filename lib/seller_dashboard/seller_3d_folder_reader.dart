import 'dart:typed_data';

class Seller3dFolderFile {
  const Seller3dFolderFile(this.relativePath, this.bytes);
  final String relativePath;
  final Uint8List bytes;
}

abstract class Seller3dFolderReader {
  Future<List<Seller3dFolderFile>> readDirectory(String dir);
  Future<Uint8List> readPath(String path);
}
