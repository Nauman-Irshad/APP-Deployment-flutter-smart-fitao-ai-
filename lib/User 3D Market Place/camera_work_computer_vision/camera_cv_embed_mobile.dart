import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../register_webview.dart';
import 'camera_cv_config.dart';
import 'camera_cv_models.dart';

/// In-app camera: Flask pose page inside a **WebView** (Android / iOS / desktop).
class CameraCvEmbedPanel extends StatefulWidget {
  const CameraCvEmbedPanel({
    super.key,
    /// Ignored on mobile (embed loads immediately).
    this.loadOnUserGesture = false,
    this.primeCameraPermissionOnHost = false,
    this.autoStartFromContinue = true,
    /// Prefill embedded form from app profile / wizard (optional).
    this.prefillHeightCm,
    this.prefillWeightKg,
    this.prefillAgeYears,
    /// [SmartFitaoCv] JS channel messages from the embedded page.
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
  WebViewController? _controller;
  var _loading = true;
  String? _error;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    ensureWebViewPlatformRegistered();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _ensureCameraPermission();
    if (!mounted) return;
    _initWebView();
  }

  Future<void> _ensureCameraPermission() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final status = await Permission.camera.status;
    if (status.isGranted) return;
    final result = await Permission.camera.request();
    if (!mounted) return;
    if (result.isGranted) return;
    setState(() {
      _cameraError = result.isPermanentlyDenied
          ? 'Camera blocked. Open Settings → Apps → allow Camera, then tap Allow camera & start again.'
          : 'Camera permission is required. Tap Allow when prompted, then tap Allow camera & start again.';
    });
  }

  Future<void> _grantCameraFromEmbedPage() async {
    await _ensureCameraPermission();
    if (!mounted) return;
    final granted = await Permission.camera.isGranted;
    if (!granted && mounted) {
      setState(() {
        _cameraError ??=
            'Camera permission denied. Allow Camera for this app, then tap Allow camera & start again.';
      });
    } else if (mounted) {
      setState(() => _cameraError = null);
    }
  }

  void _initWebView() {
    final uri = CameraCvConfig.embedUriForApp(
      heightCm: widget.prefillHeightCm,
      weightKg: widget.prefillWeightKg,
      ageYears: widget.prefillAgeYears,
    );

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'SmartFitaoCv',
        onMessageReceived: (JavaScriptMessage message) {
          _onCvMessage(message.message);
        },
      )
      ..addJavaScriptChannel(
        'SmartFitaoApp',
        onMessageReceived: (JavaScriptMessage message) async {
          if (message.message == 'request_camera') {
            await _grantCameraFromEmbedPage();
            if (!mounted) return;
            await controller.runJavaScript(
              'window.__smartFitaoCameraGranted && window.__smartFitaoCameraGranted();',
            );
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (WebResourceError err) {
            if (mounted) {
              setState(() {
                _loading = false;
                _error = err.description.isNotEmpty
                    ? err.description
                    : 'Could not load page (${err.errorCode}).';
              });
            }
          },
        ),
      )
      ..loadRequest(uri);

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
      platform.setMixedContentMode(MixedContentMode.alwaysAllow);
      platform.setOnPlatformPermissionRequest(
        (PlatformWebViewPermissionRequest request) {
          request.grant();
        },
      );
    } else if (platform is WebKitWebViewController) {
      platform.setOnPlatformPermissionRequest(
        (PlatformWebViewPermissionRequest request) {
          request.grant();
        },
      );
    }

    _controller = controller;
    if (mounted) setState(() {});
  }

  void _onCvMessage(String raw) {
    final cb = widget.onHumanEvent;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final ev = CameraCvHumanEvent.fromJsonMap(m);
      if (ev == null || !mounted) return;
      if (ev.phase == 'error' && (ev.message?.isNotEmpty ?? false)) {
        setState(() => _cameraError = ev.message);
      } else if (ev.phase == 'camera_ready') {
        setState(() => _cameraError = null);
      }
      cb?.call(ev);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: _cameraError != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: _CameraErrorBanner(
                    message: _cameraError!,
                    onOpenSettings: () => openAppSettings(),
                  ),
                )
              : const CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: controller),
        if (_loading)
          const ColoredBox(
            color: Colors.black54,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        if (_error != null && !_loading)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.red.shade900.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'In-app pose camera unreachable.\n$_error\n\n'
                    'URL: ${CameraCvConfig.baseUrl}\n'
                    'On your PC run: camera_work_computer_vision/reference_original_server/app.py '
                    '(SMARTFITAO_HTTP=1, port 5000). '
                    'Emulator: --dart-define=CV_CAMERA_BASE=http://10.0.2.2:5000',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        if (_cameraError != null && !_loading)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: _CameraErrorBanner(
                message: _cameraError!,
                onOpenSettings: () => openAppSettings(),
              ),
            ),
          ),
      ],
    );
  }
}

class _CameraErrorBanner extends StatelessWidget {
  const _CameraErrorBanner({
    required this.message,
    required this.onOpenSettings,
  });

  final String message;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade900.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.videocam_off, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Camera failed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            if (message.contains('Settings'))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: onOpenSettings,
                  child: const Text('Open Settings'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
