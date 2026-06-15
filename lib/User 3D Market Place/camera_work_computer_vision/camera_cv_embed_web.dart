// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../../2d_try_on_app/try_on_handoff.dart';
import 'camera_cv_config.dart';
import 'camera_cv_gesture_bridge.dart';
import 'camera_cv_models.dart';

/// Flutter Web (Edge / Chrome): iframe with **Permissions Policy** so MediaPipe
/// can call `getUserMedia`. User taps once on the host page first so Edge can
/// grant camera, then the pose page loads full-screen in the iframe.
class CameraCvEmbedPanel extends StatefulWidget {
  const CameraCvEmbedPanel({
    super.key,
    /// Load pose scanner iframe immediately (one tap inside for Edge camera).
    this.loadOnUserGesture = false,
    /// Warm up Edge camera permission on the Flutter origin before iframe load.
    this.primeCameraPermissionOnHost = false,
    /// After **Continue to Camera**, start scanner without a second tap.
    this.autoStartFromContinue = true,
    this.prefillHeightCm,
    this.prefillWeightKg,
    this.prefillAgeYears,
    this.onHumanEvent,
  });

  final bool loadOnUserGesture;
  final bool primeCameraPermissionOnHost;
  final bool autoStartFromContinue;
  final double? prefillHeightCm;
  final double? prefillWeightKg;
  final int? prefillAgeYears;
  final void Function(CameraCvHumanEvent event)? onHumanEvent;

  @override
  State<CameraCvEmbedPanel> createState() => _CameraCvEmbedPanelState();
}

class _CameraCvEmbedPanelState extends State<CameraCvEmbedPanel> {
  static int _nextId = 0;

  String? _viewType;
  var _loading = true;
  var _embedReady = false;
  var _cameraLive = false;
  html.IFrameElement? _iframe;
  String? _hostError;
  StreamSubscription<html.MessageEvent>? _cvMessageSub;

  String get _embedUrl {
    final returnTo = html.window.location.href.split('#').first;
    return CameraCvConfig.embedUrlForApp(
      heightCm: widget.prefillHeightCm,
      weightKg: widget.prefillWeightKg,
      ageYears: widget.prefillAgeYears,
      returnTo: returnTo,
      tryonReturn: Uri.parse(returnTo).origin,
    );
  }

  @override
  void initState() {
    super.initState();
    _cvMessageSub = html.window.onMessage.listen(_onWindowMessage);
    if (!widget.loadOnUserGesture) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _registerIframe();
      });
    }
  }

  void _onWindowMessage(html.MessageEvent e) {
    final cb = widget.onHumanEvent;
    final raw = e.data;
    if (raw is! String) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final ev = CameraCvHumanEvent.fromJsonMap(m);
      if (ev == null || !mounted) return;
      if (ev.phase == 'error' && (ev.message?.isNotEmpty ?? false)) {
        setState(() => _hostError = ev.message);
      } else if (ev.phase == 'camera_ready') {
        setState(() {
          _hostError = null;
          _cameraLive = true;
        });
      }
      if (ev.phase == 'tryon_2d') {
        if (ev.handoff != null) {
          unawaited(TryOnHandoff.applyFromSessionJson(jsonEncode(ev.handoff)));
        }
        cb?.call(ev);
        return;
      }
      cb?.call(ev);
    } catch (_) {}
  }

  Future<bool> _primeEdgeCamera() async {
    try {
      final md = html.window.navigator.mediaDevices;
      if (md == null) {
        setState(() {
          _hostError =
              'This browser has no camera API. Use Microsoft Edge or Chrome on desktop.';
        });
        return false;
      }
      html.MediaStream stream;
      try {
        stream = await md.getUserMedia({
          'video': {
            'facingMode': {'ideal': 'user'},
          },
          'audio': false,
        });
      } catch (_) {
        stream = await md.getUserMedia({'video': true, 'audio': false});
      }
      for (final t in stream.getTracks()) {
        t.stop();
      }
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _hostError =
              'Edge blocked the camera. Click the camera icon in the address bar → Allow, then try again.\n($e)';
        });
      }
      return false;
    }
  }

  Future<void> _onStartPressed() async {
    setState(() {
      _hostError = null;
      _loading = true;
    });
    if (!_embedReady) _registerIframe();
  }

  void _signalIframeStart() {
    try {
      _iframe?.contentWindow?.postMessage('smartfitao_start_camera', '*');
    } catch (_) {}
  }

  void _registerIframe() {
    if (_embedReady) return;
    _embedReady = true;

    final unique = _nextId++;
    final viewType = 'camera_cv_iframe_$unique';
    _viewType = viewType;

    final iframe = _iframe = html.IFrameElement()
      ..src = _embedUrl
      ..style.border = '0'
      ..style.outline = 'none'
      ..style.margin = '0'
      ..style.padding = '0'
      ..style.display = 'block'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.verticalAlign = 'top'
      ..allowFullscreen = true
      // Edge / Chrome: delegate camera + mic into cross-origin iframe (Flask on :5000).
      ..allow = 'camera *; microphone *; fullscreen *; autoplay *';

    iframe.onLoad.listen((_) {
      try {
        iframe.focus();
      } catch (_) {}
      if (widget.autoStartFromContinue ||
          CameraCvGestureBridge.consume()) {
        _signalIframeStart();
      }
      if (mounted) setState(() => _loading = false);
    });

    iframe.onError.listen((_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hostError =
              'Could not load pose camera at ${CameraCvConfig.baseUrl}. '
              'Run: .\\RUN-EDGE-LOCAL-BACKEND.ps1 or CV on port 5003.';
        });
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int _) => iframe,
    );

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cvMessageSub?.cancel();
    super.dispose();
  }

  Widget _startScreen() {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam, size: 52, color: Color(0xFF80CBC4)),
                const SizedBox(height: 16),
                const Text(
                  'Body scan uses your Edge webcam',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Camera opens automatically after Continue to Camera from size prediction.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.35),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  onPressed: _onStartPressed,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Open body scanner'),
                ),
                const SizedBox(height: 12),
                if (_hostError != null) ...[
                  const SizedBox(height: 16),
                  Material(
                    color: Colors.red.shade900.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _hostError!,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.loadOnUserGesture || _embedReady) {
      final vt = _viewType;
      if (vt == null) {
        return const ColoredBox(
          color: Colors.black,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          HtmlElementView(viewType: vt),
          if (_loading)
            const ColoredBox(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          if (_hostError != null && !_loading)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.red.shade900.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      _hostError!,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return _startScreen();
  }
}
