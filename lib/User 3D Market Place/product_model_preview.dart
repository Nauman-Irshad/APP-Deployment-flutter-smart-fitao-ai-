import 'package:flutter/material.dart';

import 'r2_model_viewer_stub.dart'
    if (dart.library.js_interop) 'r2_model_viewer_web.dart' as r2_viewer;

/// 3D GLB preview (R2 CDN). Web: DOM model-viewer with crossorigin.
class ProductModelPreview extends StatelessWidget {
  const ProductModelPreview({
    super.key,
    required this.src,
    required this.alt,
    this.compact = false,
    this.staggerIndex = 0,
  });

  final String src;
  final String alt;
  final bool compact;
  final int staggerIndex;

  static const _bg = Color(0xFF141414);

  @override
  Widget build(BuildContext context) {
    if (src.isEmpty) {
      return _fallback(compact: compact);
    }

    return ColoredBox(
      color: _bg,
      child: SizedBox.expand(
        child: r2_viewer.buildR2ModelViewer(
          src: src,
          alt: alt,
          compact: compact,
          backgroundColor: _bg,
        ),
      ),
    );
  }

  static Widget _fallback({required bool compact}) {
    return Container(
      color: _bg,
      alignment: Alignment.center,
      child: Icon(
        Icons.view_in_ar,
        size: compact ? 36 : 48,
        color: Colors.grey.shade600,
      ),
    );
  }
}
