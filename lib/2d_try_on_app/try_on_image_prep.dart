import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Same sizes as id-2d-try-on/public/fast — faster Hugging Face IDM-VTON uploads.
class TryOnImagePrep {
  TryOnImagePrep._();

  static const int personMaxSide = 768;
  static const int garmMaxSide = 512;
  static const int jpegQuality = 85;

  static Uint8List forApi(Uint8List raw, {required int maxSide}) {
    try {
      final decoded = img.decodeImage(raw);
      if (decoded == null) return raw;

      img.Image out = decoded;
      final longest = out.width > out.height ? out.width : out.height;
      if (longest > maxSide) {
        if (out.width >= out.height) {
          out = img.copyResize(
            out,
            width: maxSide,
            interpolation: img.Interpolation.linear,
          );
        } else {
          out = img.copyResize(
            out,
            height: maxSide,
            interpolation: img.Interpolation.linear,
          );
        }
      }

      return Uint8List.fromList(img.encodeJpg(out, quality: jpegQuality));
    } catch (_) {
      return raw;
    }
  }

  static Uint8List person(Uint8List raw) =>
      forApi(raw, maxSide: personMaxSide);

  static Uint8List garment(Uint8List raw) =>
      forApi(raw, maxSide: garmMaxSide);
}
