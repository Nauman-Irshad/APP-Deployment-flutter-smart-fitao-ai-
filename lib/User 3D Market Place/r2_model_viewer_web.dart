import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'model_viewer_load_bridge.dart';
import 'viewer_asset_src.dart';

final Set<String> _registeredViewTypes = <String>{};

bool _skipCrossOrigin(String src) {
  if (src.startsWith('blob:')) return true;
  if (isFirebaseStorageGlbUrl(src)) return true;
  final lower = src.toLowerCase();
  // R2 / CDN often omit ACAO — crossorigin breaks model-viewer on Flutter web.
  if (lower.contains('r2.dev') ||
      lower.contains('cloudflare') ||
      lower.contains('r2.cloudflarestorage.com')) {
    return true;
  }
  return false;
}

void _wireModelViewerEvents(web.HTMLElement mv, String bridgeKey) {
  final bridge = ModelViewerLoadBridge.forKey(bridgeKey);

  void onLoad(web.Event _) {
    bridge.markLoaded();
  }

  void onError(web.Event _) {
    bridge.markError(
      'Could not display this 3D file. The GLB may be invalid or blocked.',
    );
  }

  void onProgress(web.Event event) {
    bridge.setStep(2, progressPercent: bridge.progress < 70 ? 70 : bridge.progress + 2);
  }

  mv.addEventListener('load', onLoad.toJS);
  mv.addEventListener('error', onError.toJS);
  mv.addEventListener('progress', onProgress.toJS);
}

/// Web: DOM [model-viewer] with crossorigin before src (innerHTML scripts do not run).
Widget buildR2ModelViewer({
  required String src,
  required String alt,
  required bool compact,
  required Color backgroundColor,
  int staggerIndex = 0,
  String? loadBridgeKey,
}) {
  final bridgeKey = loadBridgeKey ?? 'mv-${src.hashCode}-$staggerIndex';
  final viewType =
      'r2-mv-${src.hashCode.abs()}-${compact ? 'c' : 'f'}-$staggerIndex-$bridgeKey';
  if (!_registeredViewTypes.contains(viewType)) {
    _registeredViewTypes.add(viewType);
    const bgCss = '#141414';
    final rotate = compact ? 'pi/10' : 'pi/6';
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final root = web.HTMLDivElement()
        ..style.setProperty('width', '100%')
        ..style.setProperty('height', '100%')
        ..style.setProperty('margin', '0')
        ..style.setProperty('padding', '0')
        ..style.setProperty('overflow', 'hidden')
        ..style.backgroundColor = bgCss;

      final mv = web.document.createElement('model-viewer') as web.HTMLElement?;
      if (mv == null) return root;

      mv.style.setProperty('width', '100%');
      mv.style.setProperty('height', '100%');
      mv.style.setProperty('display', 'block');
      mv.style.backgroundColor = bgCss;

      mv.setAttribute('shadow-intensity', '0');
      mv.setAttribute('environment-image', 'neutral');
      if (!_skipCrossOrigin(src)) {
        mv.setAttribute('crossorigin', 'anonymous');
      }
      mv.setAttribute('alt', alt);
      final eager = staggerIndex == 0;
      mv.setAttribute('loading', eager ? 'eager' : 'lazy');
      mv.setAttribute('fetchpriority', eager ? 'high' : 'low');
      mv.setAttribute('reveal', 'auto');
      mv.setAttribute('auto-rotate', '');
      mv.setAttribute('auto-rotate-delay', '0');
      mv.setAttribute('rotation-per-second', rotate);
      mv.setAttribute('interaction-prompt', 'none');
      mv.setAttribute('camera-controls', '');
      mv.setAttribute('touch-action', 'none');
      if (compact) {
        mv.setAttribute('disable-zoom', '');
      }
      mv.style.cursor = 'grab';
      _wireModelViewerEvents(mv, bridgeKey);
      mv.setAttribute('src', src);
      root.append(mv);
      return root;
    });
  }

  return HtmlElementView(viewType: viewType);
}
