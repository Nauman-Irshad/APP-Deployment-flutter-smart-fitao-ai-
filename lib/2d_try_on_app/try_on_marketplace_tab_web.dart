// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'try_on_vercel_webview.dart';

/// Flutter web: iframe embed of live Vercel 2D try-on (same as website).
class TryOnMarketplaceTab extends StatefulWidget {
  const TryOnMarketplaceTab({
    super.key,
    this.embeddedInNav = false,
  });

  final bool embeddedInNav;

  @override
  State<TryOnMarketplaceTab> createState() => _TryOnMarketplaceTabState();
}

class _TryOnMarketplaceTabState extends State<TryOnMarketplaceTab> {
  static int _nextId = 0;

  String? _viewType;
  var _loading = true;
  String? _error;

  String get _tryOnUrl => TryOnVercelWebView.vercelTryOnUri.toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _registerIframe();
    });
  }

  void _registerIframe() {
    final viewType = 'try_on_iframe_${_nextId++}';
    _viewType = viewType;

    final iframe = html.IFrameElement()
      ..src = _tryOnUrl
      ..style.border = '0'
      ..style.margin = '0'
      ..style.padding = '0'
      ..style.display = 'block'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true
      ..allow = 'camera *; microphone *; fullscreen *';

    iframe.onLoad.listen((_) {
      if (mounted) setState(() => _loading = false);
    });

    iframe.onError.listen((_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load 2D try-on.\n$_tryOnUrl';
        });
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) => iframe);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final viewType = _viewType;
    if (viewType == null) {
      return const ColoredBox(
        color: Colors.white,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
      );
    }

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            HtmlElementView(viewType: viewType),
            if (_loading)
              const ColoredBox(
                color: Color(0x66FFFFFF),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF059669)),
                      SizedBox(height: 12),
                      Text('Loading 2D Try-On…'),
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
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                            _viewType = null;
                          });
                          _registerIframe();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                        ),
                        child: const Text('Retry'),
                      ),
                      TextButton(
                        onPressed: () => html.window.open(_tryOnUrl, '_blank'),
                        child: const Text('Open try-on in new tab'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
