// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'size prediction model/studio_config.dart';

/// Flutter Web (Edge / Chrome): iframe embed — WebView APIs are not implemented on web.
class AiChatbotScreen extends StatefulWidget {
  const AiChatbotScreen({super.key});

  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  static int _nextId = 0;

  String? _viewType;
  var _loading = true;
  String? _error;

  /// Fixed chat build in `web/smart-fitao-chat/` (3D works; Vercel deploy may be outdated).
  String get _chatUrl {
    if (StudioConfig.useLocalWebsite) {
      return StudioConfig.smartFitaoChatUri
          .replace(queryParameters: const {'embed': '1', 'mobile': '1'})
          .toString();
    }
    if (kIsWeb && StudioConfig.useLocalNlpOnWeb) {
      return Uri.parse('http://127.0.0.1:5002/')
          .replace(queryParameters: const {'embed': '1', 'mobile': '1'})
          .toString();
    }
    const override = String.fromEnvironment('SMARTFITAO_CHAT_URL', defaultValue: '');
    if (override.trim().isNotEmpty) {
      var u = override.trim();
      if (!u.endsWith('/')) u = '$u/';
      return Uri.parse(u)
          .replace(queryParameters: const {'embed': '1', 'mobile': '1'})
          .toString();
    }
    final base = Uri.base;
    var path = base.path;
    if (!path.endsWith('/')) path = '$path/';
    return Uri.parse('${base.origin}$path''smart-fitao-chat/index.html')
        .replace(queryParameters: const {'embed': '1', 'mobile': '1'})
        .toString();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _registerIframe();
    });
  }

  void _registerIframe() {
    final unique = _nextId++;
    final viewType = 'smart_fitao_chat_iframe_$unique';
    _viewType = viewType;

    final iframe = html.IFrameElement()
      ..src = _chatUrl
      ..style.border = '0'
      ..style.margin = '0'
      ..style.padding = '0'
      ..style.display = 'block'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true
      ..allow = 'fullscreen *; autoplay *; xr-spatial-tracking *';

    iframe.onLoad.listen((_) {
      if (mounted) setState(() => _loading = false);
    });

    iframe.onError.listen((_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _loadErrorMessage();
        });
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int _) => iframe,
    );

    if (mounted) setState(() {});
  }

  String _loadErrorMessage() {
    if (StudioConfig.isLocalChat) {
      return 'Could not load local AI chat.\n'
          '1) Run App\\scripts\\start-local-website-for-app.ps1\n'
          '2) flutter run -d edge --dart-define=STUDIO_LOCAL_DEV=true\n'
          '$_chatUrl';
    }
    return 'Could not load AI chat.\n$_chatUrl';
  }

  void _openInBrowser() {
    html.window.open(_chatUrl, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final viewType = _viewType;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'AI Chat Bot',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open in browser',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: viewType == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : Stack(
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
                          Text('Loading SmartFitao AI…'),
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
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
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
                            onPressed: _openInBrowser,
                            child: const Text('Open chat in new tab'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
