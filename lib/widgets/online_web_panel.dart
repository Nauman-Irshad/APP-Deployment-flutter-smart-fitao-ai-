import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../register_webview.dart';

/// Full-screen WebView for deployed Vercel / HTTPS pages (chat, 2D try-on, etc.).
class OnlineWebPanel extends StatefulWidget {
  const OnlineWebPanel({
    super.key,
    required this.url,
    this.title = 'SmartFitao',
    this.showAppBar = true,
  });

  final Uri url;
  final String title;
  final bool showAppBar;

  @override
  State<OnlineWebPanel> createState() => _OnlineWebPanelState();
}

class _OnlineWebPanelState extends State<OnlineWebPanel> {
  WebViewController? _controller;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    ensureWebViewPlatformRegistered();
    _init();
  }

  Future<void> _init() async {
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
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (err) {
            if (mounted) {
              setState(() {
                _loading = false;
                _error = err.description;
              });
            }
          },
        ),
      );

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
      platform.setMixedContentMode(MixedContentMode.alwaysAllow);
    }

    await controller.loadRequest(widget.url);
    if (!mounted) return;
    setState(() => _controller = controller);
  }

  @override
  Widget build(BuildContext context) {
    final body = _controller == null
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
        : Stack(
            fit: StackFit.expand,
            children: [
              WebViewWidget(controller: _controller!),
              if (_loading)
                const ColoredBox(
                  color: Color(0x99FFFFFF),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF059669)),
                        SizedBox(height: 12),
                        Text('Loading online…'),
                      ],
                    ),
                  ),
                ),
              if (_error != null && !_loading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load page.\nCheck mobile data / Wi‑Fi.\n\n$_error',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _controller?.loadRequest(widget.url);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );

    if (!widget.showAppBar) {
      return ColoredBox(color: Colors.white, child: SafeArea(child: body));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: body,
    );
  }
}
