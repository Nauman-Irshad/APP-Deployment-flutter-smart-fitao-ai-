import 'package:flutter/material.dart';

import 'glb_src_resolver.dart';
import 'r2_model_viewer_stub.dart'
    if (dart.library.js_interop) 'r2_model_viewer_web.dart' as r2_viewer;
import 'viewer_asset_src.dart';

/// 3D GLB preview (R2 CDN / Firebase Storage). Web: DOM model-viewer with crossorigin.
class ProductModelPreview extends StatefulWidget {
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

  @override
  State<ProductModelPreview> createState() => _ProductModelPreviewState();
}

class _ProductModelPreviewState extends State<ProductModelPreview> {
  static const _bg = Color(0xFF141414);

  String? _viewerSrc;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _resolveSrc();
  }

  @override
  void didUpdateWidget(covariant ProductModelPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) {
      _viewerSrc = null;
      _resolveSrc();
    }
  }

  Future<void> _resolveSrc() async {
    final raw = widget.src.trim();
    if (raw.isEmpty) return;

    if (!isFirebaseStorageGlbUrl(raw)) {
      if (mounted) setState(() => _viewerSrc = raw);
      return;
    }

    setState(() => _resolving = true);
    final resolved = await resolveGlbSrcForViewer(raw);
    if (!mounted) return;
    setState(() {
      _viewerSrc = resolved;
      _resolving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.src.isEmpty) {
      return _fallback(compact: widget.compact);
    }

    final src = _viewerSrc ?? widget.src;
    if (_resolving && _viewerSrc == null) {
      return const ColoredBox(
        color: _bg,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: _bg,
      child: SizedBox.expand(
        child: r2_viewer.buildR2ModelViewer(
          src: src,
          alt: widget.alt,
          compact: widget.compact,
          backgroundColor: _bg,
          staggerIndex: widget.staggerIndex,
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
