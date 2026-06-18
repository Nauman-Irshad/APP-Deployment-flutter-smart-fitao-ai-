import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'model_viewer_load_bridge.dart';

/// Mobile/desktop: package [ModelViewer].
Widget buildR2ModelViewer({
  required String src,
  required String alt,
  required bool compact,
  required Color backgroundColor,
  int staggerIndex = 0,
  String? loadBridgeKey,
}) {
  final eager = staggerIndex == 0;
  final bridgeKey = loadBridgeKey ?? 'mv-${src.hashCode}-$staggerIndex';
  if (bridgeKey.isNotEmpty) {
    Future<void>.delayed(const Duration(seconds: 4), () {
      ModelViewerLoadBridge.forKey(bridgeKey).markLoaded();
    });
  }
  return ModelViewer(
    key: ValueKey(src),
    src: src,
    alt: alt,
    loading: eager ? Loading.eager : Loading.lazy,
    reveal: Reveal.auto,
    autoRotate: true,
    autoRotateDelay: 0,
    rotationPerSecond: compact ? 'pi/10' : 'pi/6',
    cameraControls: true,
    disableZoom: compact,
    interactionPrompt: InteractionPrompt.none,
    touchAction: TouchAction.none,
    ar: false,
    debugLogging: false,
    backgroundColor: backgroundColor,
  );
}
