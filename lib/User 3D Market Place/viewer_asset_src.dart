import 'package:flutter/foundation.dart' show kIsWeb;

/// Bundled demos under `3d viewer work/models/` (see `pubspec.yaml` assets).
/// Used when a Firebase listing has no `modelPath` so tiles still spin.
const List<String> kBundledMarketplaceGltfPaths = [
  '3d viewer work/models/product1/product1.glb',
];

/// Picks `product['modelPath']` when set (including `https://…glb|gltf`), otherwise a stable
/// bundled GLTF from [kBundledMarketplaceGltfPaths].  
/// Web previews use `<model-viewer>` ([model_viewer_plus]), which renders GLTF via Three.js.
String resolvedMarketplaceModelPath(Map<String, dynamic> product) {
  final raw = product['modelPath']?.toString().trim();
  if (raw != null && raw.isNotEmpty) return raw;
  if (kBundledMarketplaceGltfPaths.isEmpty) return '';
  final key =
      '${product['firebaseProductId'] ?? ''}|${product['id'] ?? ''}|${product['title'] ?? ''}';
  var h = 0;
  for (final c in key.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return kBundledMarketplaceGltfPaths[h % kBundledMarketplaceGltfPaths.length];
}

/// URL/path for GLTF bundled via [pubspec.yaml] (`3d viewer work/models/...`).
/// Normalizes legacy keys like `models/product1/product1.glb`.
String viewerAssetSrc(String? modelPathRaw) {
  var key = (modelPathRaw ?? '').trim();
  if (key.isEmpty) return '';
  if (key.startsWith('http://') || key.startsWith('https://')) return key;

  if (!key.contains('3d viewer work')) {
    if (key.startsWith('models/')) {
      key = '3d viewer work/models/${key.substring('models/'.length)}';
    } else if (!key.startsWith('assets/')) {
      key = '3d viewer work/models/$key';
    }
  }

  if (kIsWeb) {
    // IMPORTANT: Do not use [Uri.encodeFull] on the whole path — it encodes `/`
    // as `%2F`, and Flutter's web asset server often fails to resolve those URLs,
    // which breaks `<model-viewer src="...">`. Encode each segment only.
    final encoded =
        key.split('/').map((segment) => Uri.encodeComponent(segment)).join('/');
    return '${Uri.base.origin}/assets/$encoded';
  }
  return key;
}
