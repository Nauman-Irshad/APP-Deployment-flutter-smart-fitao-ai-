import 'dart:typed_data';



/// Holds the latest pose-capture photo for the 2D try-on step.

class CapturedPhotoSession {

  CapturedPhotoSession._();



  static String? imageUrl;

  static Uint8List? personBytes;

  static int landmarkCount = 0;



  static void apply({

    required String? url,

    int landmarks = 0,

  }) {

    imageUrl = url;

    personBytes = null;

    landmarkCount = landmarks;

  }



  static void applyBytes(Uint8List bytes, {int landmarks = 0}) {

    personBytes = bytes;

    imageUrl = null;

    landmarkCount = landmarks;

  }



  static void clear() {

    imageUrl = null;

    personBytes = null;

    landmarkCount = 0;

  }

}


