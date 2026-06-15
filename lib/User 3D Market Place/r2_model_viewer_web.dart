import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredViewTypes = <String>{};

/// Web: DOM [model-viewer] with crossorigin before src (innerHTML scripts do not run).
Widget buildR2ModelViewer({
  required String src,
  required String alt,
  required bool compact,
  required Color backgroundColor,
}) {
  final viewType = 'r2-mv-${src.hashCode.abs()}-${compact ? 'c' : 'f'}';
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

      mv.setAttribute('crossorigin', 'anonymous');
      mv.setAttribute('alt', alt);
      mv.setAttribute('loading', 'eager');
      mv.setAttribute('reveal', 'auto');
      mv.setAttribute('auto-rotate', '');
      mv.setAttribute('auto-rotate-delay', '0');
      mv.setAttribute('rotation-per-second', rotate);
      mv.setAttribute('interaction-prompt', 'none');
      // Drag on product = orbit/rotate (cursor over card).
      mv.setAttribute('camera-controls', '');
      mv.setAttribute('touch-action', 'none');
      if (compact) {
        mv.setAttribute('disable-zoom', '');
      }
      mv.style.cursor = 'grab';
      mv.setAttribute('src', src);
      root.append(mv);
      return root;
    });
  }

  return HtmlElementView(viewType: viewType);
}
