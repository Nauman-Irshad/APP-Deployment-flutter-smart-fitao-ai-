import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Browser file dialog for Edge/Chrome — avoids file_picker web crash and shows .glb.
class Seller3dWebPicker {
  Seller3dWebPicker._();

  static final RegExp _useful = RegExp(
    r'\.(glb|gltf|bin|png|jpe?g|webp|zip)$',
    caseSensitive: false,
  );

  /// [folder] true → pick whole folder (webkitdirectory).
  static Future<List<PlatformFile>> pick({bool folder = false}) async {
    final input = html.FileUploadInputElement()
      ..multiple = true
      ..accept =
          '.glb,.gltf,.bin,.png,.jpg,.jpeg,.webp,.zip,model/gltf-binary,application/octet-stream,*/*';

    if (folder) {
      input.setAttribute('webkitdirectory', '');
      input.setAttribute('directory', '');
    }

    final completer = Completer<List<PlatformFile>>();
    var done = false;

    void finish(List<PlatformFile> files) {
      if (done) return;
      done = true;
      input.remove();
      if (!completer.isCompleted) completer.complete(files);
    }

    input.onChange.listen((_) async {
      final list = input.files;
      if (list == null || list.isEmpty) {
        finish([]);
        return;
      }
      final out = <PlatformFile>[];
      for (var i = 0; i < list.length; i++) {
        final file = list[i];
        final rel = _relativeName(file);
        if (!_useful.hasMatch(rel)) continue;
        try {
          final bytes = await _readBlob(file);
          out.add(PlatformFile(name: rel, size: file.size, bytes: bytes));
        } catch (_) {
          // skip unreadable entry
        }
      }
      finish(out);
    });

    html.document.body?.append(input);
    input.click();

    // If user closes dialog without choosing, onChange may never fire.
    Future.delayed(const Duration(seconds: 90), () {
      if (!done) finish([]);
    });

    return completer.future;
  }

  static String _relativeName(html.File file) {
    try {
      final rel = (file as dynamic).webkitRelativePath as String?;
      if (rel != null && rel.isNotEmpty) return rel.replaceAll('\\', '/');
    } catch (_) {}
    return file.name;
  }

  static Future<Uint8List> _readBlob(html.File file) {
    final reader = html.FileReader();
    final c = Completer<Uint8List>();
    reader.onLoad.listen((_) {
      final raw = reader.result;
      if (raw is ByteBuffer) {
        c.complete(Uint8List.view(raw));
      } else if (raw is TypedData) {
        c.complete(Uint8List.fromList(raw.buffer.asUint8List()));
      } else {
        c.completeError(StateError('Could not read ${file.name}'));
      }
    });
    reader.onError.listen((_) {
      c.completeError(StateError('Could not read ${file.name}'));
    });
    reader.readAsArrayBuffer(file);
    return c.future;
  }
}
