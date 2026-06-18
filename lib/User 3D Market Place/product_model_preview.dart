import 'dart:async';

import 'package:flutter/material.dart';

import 'glb_src_resolver.dart';
import 'model_viewer_load_bridge.dart';
import 'r2_model_viewer_stub.dart'
    if (dart.library.js_interop) 'r2_model_viewer_web.dart' as r2_viewer;
import 'viewer_asset_src.dart';

/// 3D GLB preview (R2 CDN / Firebase Storage). Shows step progress and errors.
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
  Timer? _progressTimer;
  Timer? _timeoutTimer;
  late String _bridgeKey;
  late ModelViewerLoadBridge _bridge;

  @override
  void initState() {
    super.initState();
    _bridgeKey = 'mv-${widget.src.hashCode}-${widget.staggerIndex}';
    _bridge = ModelViewerLoadBridge.forKey(_bridgeKey);
    _bridge.addListener(_onBridge);
    _resolveSrc();
  }

  @override
  void didUpdateWidget(covariant ProductModelPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src ||
        oldWidget.staggerIndex != widget.staggerIndex) {
      _cancelTimers();
      _bridgeKey = 'mv-${widget.src.hashCode}-${widget.staggerIndex}';
      _bridge.removeListener(_onBridge);
      _bridge = ModelViewerLoadBridge.forKey(_bridgeKey);
      _bridge.addListener(_onBridge);
      _viewerSrc = null;
      _resolveSrc();
    }
  }

  void _onBridge() {
    if (mounted) setState(() {});
  }

  void _cancelTimers() {
    _progressTimer?.cancel();
    _timeoutTimer?.cancel();
    _progressTimer = null;
    _timeoutTimer = null;
  }

  void _startProgressTicker({required int from, required int to, int stepNum = 2}) {
    _cancelTimers();
    _bridge.setStep(stepNum, progressPercent: from);
    var value = from;
    _progressTimer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (!mounted || _bridge.loaded || _bridge.errorMessage != null) {
        t.cancel();
        return;
      }
      value += 2;
      if (value >= to) {
        value = to;
        t.cancel();
      }
      _bridge.setProgress(value);
    });
  }

  void _armLoadTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 28), () {
      if (!mounted || _bridge.loaded) return;
      _bridge.markError(
        '3D model did not load in time. Pull to refresh or tap Retry.',
      );
    });
  }

  Future<void> _resolveSrc() async {
    final raw = widget.src.trim();
    if (raw.isEmpty) return;

    _bridge.reset();
    _bridge.setStep(1, progressPercent: 5);
    _startProgressTicker(from: 5, to: 30, stepNum: 1);

    if (!isFirebaseStorageGlbUrl(raw)) {
      if (!mounted) return;
      setState(() {
        _viewerSrc = raw;
        _resolving = false;
      });
      _bridge.setStep(2, progressPercent: 35);
      _startProgressTicker(from: 35, to: 88, stepNum: 2);
      _armLoadTimeout();
      return;
    }

    setState(() => _resolving = true);
    final resolved = await resolveGlbSrcForViewer(raw);
    if (!mounted) return;
    setState(() {
      _viewerSrc = resolved;
      _resolving = false;
    });
    _bridge.setStep(2, progressPercent: 40);
    _startProgressTicker(from: 40, to: 90, stepNum: 2);
    _armLoadTimeout();
  }

  void _retry() {
    _bridge.reset();
    _resolveSrc();
  }

  @override
  void dispose() {
    _cancelTimers();
    _bridge.removeListener(_onBridge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.src.isEmpty) {
      return _fallback(compact: widget.compact);
    }

    final err = _bridge.errorMessage;
    if (err != null) {
      return _errorPanel(err);
    }

    if (_resolving && _viewerSrc == null) {
      return _loadingPanel(step: 1);
    }

    final src = _viewerSrc ?? widget.src;
    final showOverlay = !_bridge.loaded;

    return ColoredBox(
      color: _bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SizedBox.expand(
            child: r2_viewer.buildR2ModelViewer(
              src: src,
              alt: widget.alt,
              compact: widget.compact,
              backgroundColor: _bg,
              staggerIndex: widget.staggerIndex,
              loadBridgeKey: _bridgeKey,
            ),
          ),
          if (showOverlay) _loadingPanel(step: _bridge.step),
        ],
      ),
    );
  }

  Widget _loadingPanel({required int step}) {
    final labels = [
      'Fetching 3D file',
      'Loading 3D model',
      'Ready — drag to rotate',
    ];
    final label = labels[(step - 1).clamp(0, 2)];
    final pct = _bridge.progress;

    return ColoredBox(
      color: _bg.withValues(alpha: 0.92),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: pct > 0 ? pct / 100 : null,
                  strokeWidth: 3,
                  color: const Color(0xFF059669),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Step $step / 3',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$pct%',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorPanel(String message) {
    return ColoredBox(
      color: _bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 40),
              const SizedBox(height: 10),
              Text(
                '3D preview failed',
                style: TextStyle(
                  color: Colors.red.shade200,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                ),
              ),
            ],
          ),
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
