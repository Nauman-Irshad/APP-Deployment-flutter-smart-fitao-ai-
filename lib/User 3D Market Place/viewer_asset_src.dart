import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';

import '../../config/fabric_local_config.dart';
import '../../config/media_cdn_config.dart';
import '../../config/production_urls.dart';
import '../../config/remote_media_resolver.dart';
import 'landing_page_products.dart';
import 'size prediction model/studio_config.dart';

const String kLandingHeroGlbPath = ProductionUrls.glbKurtaBlack;

final List<String> kBundledMarketplaceGltfPaths = [
  ...kLandingPageModelPaths,
];

bool isStitchedProduct(Map<String, dynamic> product) {
  final section = product['section']?.toString() ?? product['category']?.toString() ?? '';
  if (section == 'Fabric') return false;
  final path = product['modelPath']?.toString().trim() ?? '';
  return path.isNotEmpty;
}

/// Online GLB URL (R2 / https). Web: https only — no localhost / missing bundle paths.
bool productHasRemoteGlbUrl(Map<String, dynamic> product) {
  final section =
      product['section']?.toString() ?? product['category']?.toString() ?? '';
  if (section == 'Fabric') return false;

  for (final key in ['modelUrl', 'modelDirectUrl']) {
    final direct = product[key]?.toString().trim() ?? '';
    if (_isRemoteGlbUrl(direct)) return true;
  }

  return _isRemoteGlbUrl(modelSrcForProduct(product));
}

bool isFirebaseStorageGlbUrl(String url) {
  final lower = url.toLowerCase();
  return lower.contains('firebasestorage.googleapis.com') ||
      lower.contains('firebasestorage.app');
}

bool _isRemoteGlbUrl(String src) {
  if (src.isEmpty) return false;
  final uri = Uri.tryParse(src);
  if (uri == null || !uri.hasScheme) return false;
  if (kIsWeb) {
    return uri.scheme == 'https';
  }
  return uri.scheme == 'http' || uri.scheme == 'https';
}

/// Stitched listings that have an https GLB (before reachability check).
List<Map<String, dynamic>> productsWithHttpsGlb(
  Iterable<Map<String, dynamic>> all,
) {
  return all
      .where((p) {
        final cat =
            p['section']?.toString() ?? p['category']?.toString() ?? '';
        if (cat == 'Fabric') return true;
        return productHasRemoteGlbUrl(p);
      })
      .toList(growable: false);
}

/// Category / marketplace: only fabric + stitched with verified reachable GLB.
List<Map<String, dynamic>> categoryProductsWithGlbOrFabric(
  String section,
  List<Map<String, dynamic>> all, {
  Set<String>? reachableIds,
  bool glbCheckComplete = false,
}) {
  if (section == 'Fabric') return all;
  final withLink = productsWithHttpsGlb(all);
  if (!glbCheckComplete) return withLink;
  if (reachableIds == null || reachableIds.isEmpty) return withLink;
  return withLink
      .where((p) {
        final cat =
            p['section']?.toString() ?? p['category']?.toString() ?? '';
        if (cat == 'Fabric') return true;
        if (p['isSellerListing'] == true && productHasRemoteGlbUrl(p)) {
          return true;
        }
        final id = p['id']?.toString() ?? '';
        return id.isNotEmpty && reachableIds.contains(id);
      })
      .toList(growable: false);
}

String resolvedMarketplaceModelPath(Map<String, dynamic> product) {
  final raw = product['modelPath']?.toString().trim();
  if (raw != null && raw.isNotEmpty) {
    return modelSrcForProduct({'modelPath': raw});
  }
  if (kBundledMarketplaceGltfPaths.isEmpty) return '';
  final key =
      '${product['firebaseProductId'] ?? ''}|${product['id'] ?? ''}|${product['title'] ?? ''}';
  var h = 0;
  for (final c in key.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return modelSrcForProduct({
    'modelPath': kBundledMarketplaceGltfPaths[h % kBundledMarketplaceGltfPaths.length],
  });
}

String _webPublicUrl(String relativePath) {
  final encoded = relativePath
      .split('/')
      .map((segment) => segment.isEmpty ? '' : Uri.encodeComponent(segment))
      .join('/');
  final base = Uri.base;
  final root = base.path.endsWith('/') ? base.path : '${base.path}/';
  return '${base.origin}$root$encoded';
}

/// Uncompressed GLBs in `landing page product/` (run `scripts/uncompress_landing_glbs.ps1`).
String landingAssetSrc(String? assetPathRaw) {
  final key = (assetPathRaw ?? '').trim();
  if (key.isEmpty) return '';
  if (key.startsWith('http://') || key.startsWith('https://')) return key;

  // Fabric: local folder only (`App/landing page product/fabric/`).
  if (FabricLocalConfig.isFabricAssetPath(key)) {
    if (kIsWeb) return _webPublicUrl(key);
    return key;
  }

  if (!kIsWeb) {
    final remote = RemoteMediaResolver.instance.modelUrlForPath(key) ??
        RemoteMediaResolver.instance.imageUrlForPath(key);
    if (remote != null && remote.isNotEmpty) return remote;
    if (MediaCdnConfig.useCustomCdn) {
      return MediaCdnConfig.urlForRelativePath(key);
    }
    if (kReleaseMode) return StudioConfig.remotePublicUrl(key);
  }

  if (kIsWeb) {
    if (MediaCdnConfig.useCustomCdn) {
      return MediaCdnConfig.urlForRelativePath(key);
    }
    return _webPublicUrl(key);
  }
  return key;
}

String viewerAssetSrc(String? modelPathRaw) => landingAssetSrc(modelPathRaw);

String? _productModelPathRaw(Map<String, dynamic> product) {
  for (final key in ['modelPath', 'modelUrl', 'modelDirectUrl']) {
    final v = product[key]?.toString().trim() ?? '';
    if (v.isNotEmpty) return v;
  }
  final details = product['details'];
  if (details is Map) {
    for (final key in ['modelPath', 'modelUrl', 'modelDirectUrl']) {
      final v = details[key]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
  }
  return null;
}

String modelSrcForProduct(Map<String, dynamic> product) {
  final path = _productModelPathRaw(product);
  if (path == null || path.isEmpty) return '';
  return landingAssetSrc(path);
}

String imageSrcForProduct(Map<String, dynamic> product) {
  final path = product['imagePath']?.toString().trim() ?? '';
  if (path.isEmpty) return '';
  return landingAssetSrc(path);
}

Widget buildLandingProductImage(
  String? assetPath, {
  BoxFit fit = BoxFit.cover,
  Widget? fallback,
}) {
  final src = landingAssetSrc(assetPath);
  if (src.isEmpty) {
    return fallback ?? const SizedBox.shrink();
  }
  if (src.startsWith('http://') || src.startsWith('https://')) {
    return Image.network(
      src,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
    );
  }
  return Image.asset(
    src,
    fit: fit,
    errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
  );
}
