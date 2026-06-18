import 'package:flutter/foundation.dart';

import '../../config/media_cdn_config.dart';
import '../../config/production_urls.dart';

const Map<String, Map<String, dynamic>> kTailorShopProfiles = {
  'Cotton King Tailors': {
    'name': 'Cotton King Tailors',
    'image': 'assets/banner 1.png',
    'address': 'Shop 12, Liberty Market, Gulberg III, Lahore',
  },
  'Royal Stitch House': {
    'name': 'Royal Stitch House',
    'image': 'assets/banner 1.png',
    'address': '45 MM Alam Road, Gulberg II, Lahore',
  },
  'Heritage Tailors': {
    'name': 'Heritage Tailors',
    'image': 'assets/banner 2.png',
    'address': '789 Heritage Rd, Walled City, Lahore',
  },
  'Mars Tailors': {
    'name': 'Mars Tailors',
    'image': 'assets/banner 1.png',
    'address': 'Main Boulevard, DHA Phase 5, Lahore',
  },
  'Master Cutter Studio': {
    'name': 'Master Cutter Studio',
    'image': 'assets/banner 33.png',
    'address': 'Anarkali Bazaar, Lahore',
  },
};

/// Reels — online only (R2 `reels/`). Desktop URLs work on web and mobile.
List<ReelCatalogItem> get kReelCatalog => const [
      ReelCatalogItem(
        id: 1,
        shopName: 'Cotton King Tailors',
        videoTitle: 'Tailoring showcase',
        videoPath: ProductionUrls.reel1,
        posterAsset: 'assets/banner 1.png',
        fallbackVideoPath: ProductionUrls.reel4,
      ),
      ReelCatalogItem(
        id: 2,
        shopName: 'Royal Stitch House',
        videoTitle: 'Baju cutting & tailoring',
        videoPath: ProductionUrls.reel2,
        posterAsset: 'assets/banner 1.png',
        fallbackVideoPath: ProductionUrls.reel4,
      ),
      ReelCatalogItem(
        id: 3,
        shopName: 'Heritage Tailors',
        videoTitle: 'Ladies suit new design',
        videoPath: ProductionUrls.reel3,
        posterAsset: 'assets/banner 2.png',
        fallbackVideoPath: ProductionUrls.reel4,
      ),
      ReelCatalogItem(
        id: 4,
        shopName: 'Mars Tailors',
        videoTitle: 'Tailor reel',
        videoPath: ProductionUrls.reel4,
        posterAsset: 'assets/banner 33.png',
      ),
      ReelCatalogItem(
        id: 5,
        shopName: 'Master Cutter Studio',
        videoTitle: 'Trouser cutting',
        videoPath: ProductionUrls.reel5,
        posterAsset: 'assets/banner 2.png',
        fallbackVideoPath: ProductionUrls.reel4,
      ),
    ];

class ReelCatalogItem {
  const ReelCatalogItem({
    required this.id,
    required this.shopName,
    required this.videoTitle,
    required this.videoPath,
    required this.posterAsset,
    this.fallbackVideoPath,
    this.firestoreId,
  });

  final int id;
  final String shopName;
  final String videoTitle;
  final String videoPath;
  final String posterAsset;
  /// Used if primary URL fails to play on this device.
  final String? fallbackVideoPath;
  final String? firestoreId;
}

List<ReelCatalogItem> reelsForTailor(String shopName) {
  final key = shopName.trim();
  if (key.isEmpty) return kReelCatalog;
  final mine = kReelCatalog.where((r) => r.shopName == key).toList();
  return mine.isNotEmpty ? mine : kReelCatalog;
}

Map<String, dynamic> tailorProfileForShop(String shopName) {
  return Map<String, dynamic>.from(
    kTailorShopProfiles[shopName.trim()] ??
        kTailorShopProfiles['Cotton King Tailors']!,
  );
}

String reelVideoFileName(String path) => path.split('/').last;

/// Always network URL for reels (R2).
String reelVideoSource(String path, {String? fallback}) {
  final p = path.trim();
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  if (kIsWeb) {
    final base = Uri.base;
    final root = base.path.endsWith('/') ? base.path : '${base.path}/';
    return '${base.origin}$root'
        'reels_videos/${Uri.encodeComponent(reelVideoFileName(p))}';
  }
  return MediaCdnConfig.urlForRelativePath('reels/${reelVideoFileName(p)}');
}

String reelAssetKey(String assetPath) => assetPath;
