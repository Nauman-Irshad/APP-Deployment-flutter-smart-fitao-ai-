// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Flutter Web: full-screen iframe for 3D Studio (Vercel / local Vite).
class Studio3dEmbedPanel extends StatefulWidget {
  const Studio3dEmbedPanel({super.key, required this.embedUrl});

  final Uri embedUrl;

  @override
  State<Studio3dEmbedPanel> createState() => _Studio3dEmbedPanelState();
}

class _Studio3dEmbedPanelState extends State<Studio3dEmbedPanel> {
  static int _nextId = 0;

  String? _viewType;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _registerIframe();
    });
  }

  void _registerIframe() {
    final unique = _nextId++;
    final viewType = 'studio_3d_iframe_$unique';
    _viewType = viewType;

    final iframe = html.IFrameElement()
      ..src = widget.embedUrl.toString()
      ..style.border = '0'
      ..style.outline = 'none'
      ..style.margin = '0'
      ..style.padding = '0'
      ..style.display = 'block'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true
      ..allow = 'fullscreen *; autoplay *';

    iframe.onLoad.listen((_) {
      if (mounted) setState(() => _loading = false);
    });

    iframe.onError.listen((_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Could not load 3D Studio at ${widget.embedUrl.origin}. '
              'Check CLOTH_STUDIO_URL and that the studio is deployed.';
        });
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int _) => iframe,
    );

    if (mounted) setState(() {});
  }

  void _openInNewTab() {
    html.window.open(widget.embedUrl.toString(), '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final viewType = _viewType;
    if (viewType == null) {
      return const ColoredBox(
        color: Color(0xFFF1F5F9),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        HtmlElementView(viewType: viewType),
        if (_loading)
          const ColoredBox(
            color: Color(0x66000000),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      TextButton(
                        onPressed: _openInNewTab,
                        child: const Text('Open in new tab'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
