import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../Order-Tracking-System/services/app_backend.dart';
import '../services/marketplace_demo_seller.dart';
import 'glb_url_validator.dart';
import 'landing_models_api.dart';
import 'landing_page_products.dart' show kIncludeSellerListingsInMarketplace, kLandingPageProducts, kProductsPerLandingCategory;
import 'landing_section_utils.dart';
import 'marketplace_firebase_catalog.dart';
import 'viewer_asset_src.dart';

/// Bundled GLBs (unchanged on landing) + seller Firestore products (added separately).
class LandingCatalogStore extends ChangeNotifier {
  LandingCatalogStore._();

  static final LandingCatalogStore instance = LandingCatalogStore._();

  StreamSubscription? _firebaseSub;

  /// Product ids whose GLB URL responded OK on R2 (broken links excluded from UI).
  Set<String> _reachableGlbIds = {};
  bool _glbCheckComplete = false;

  /// Loaded URLs for bundled GLBs — does not replace [kLandingPageProducts] layout.
  List<Map<String, dynamic>> _bundled = _defaultBundled();

  bool get glbCheckComplete => _glbCheckComplete;
  Set<String> get reachableGlbIds => Set<String>.from(_reachableGlbIds);

  static List<Map<String, dynamic>> _defaultBundled() => [
        for (final p in kLandingPageProducts) Map<String, dynamic>.from(p),
      ];

  List<Map<String, dynamic>> get products => List<Map<String, dynamic>>.from(_bundled);

  static bool _isBundledProductId(String? id) {
    if (id == null || id.isEmpty) return false;
    for (final p in kLandingPageProducts) {
      if (p['id']?.toString() == id) return true;
    }
    return false;
  }

  List<Map<String, dynamic>> _filterListable(
    List<Map<String, dynamic>> items, {
    int? limit,
  }) {
    final list = items.where((p) {
      final cat =
          p['section']?.toString() ?? p['category']?.toString() ?? '';
      if (cat == 'Fabric') return true;
      if (!productHasRemoteGlbUrl(p)) return false;
      final id = p['id']?.toString() ?? '';
      // Always show 4 kurta from catalog (R2 URLs) — network probe must not hide them.
      if (_isBundledProductId(id)) return true;
      if (!_glbCheckComplete) return true;
      return id.isNotEmpty && _reachableGlbIds.contains(id);
    }).toList(growable: false);
    if (limit != null && limit > 0) {
      return list.take(limit).toList(growable: false);
    }
    return list;
  }

  /// Original landing products only — skips stitched items with dead GLB links.
  List<Map<String, dynamic>> originalBundledForSection(
    String section, {
    int? limit,
  }) {
    final out = <Map<String, dynamic>>[];
    for (final p in kLandingPageProducts) {
      if (!productMatchesLandingSection(p, section)) continue;
      out.add(Map<String, dynamic>.from(p));
    }
    return _filterListable(out, limit: limit);
  }

  Map<String, dynamic>? _loadedBundledById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final p in _bundled) {
      if (p['id']?.toString() == id) {
        return Map<String, dynamic>.from(p);
      }
    }
    return null;
  }

  /// Landing home grid — original 4 bundled items only (seller items are not mixed in).
  List<Map<String, dynamic>> previewForSection(String section) {
    try {
      final base = originalBundledForSection(
        section,
        limit: kProductsPerLandingCategory,
      );
      if (base.isEmpty && section != 'Fabric') return const [];
      return base.map((p) {
        final loaded = _loadedBundledById(p['id']?.toString());
        return loaded ?? p;
      }).toList(growable: false);
    } catch (e, st) {
      debugPrint('previewForSection($section): $e\n$st');
      return instance.originalBundledForSection(
        section,
        limit: kProductsPerLandingCategory,
      );
    }
  }

  /// Seller listings sync — always resolves [AppBackend.instance] at call time (web hot-reload safe).
  void startFirebaseSync() {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('LandingCatalogStore: Firebase not initialized yet');
        return;
      }
      final backend = AppBackend.instance;
      if (_firebaseSub != null) return;

      _firebaseSub = backend.streamAllProducts().listen(
        (list) async {
          try {
            final seller = await MarketplaceDemoSeller.resolve();
            final maps = <Map<String, dynamic>>[];
            final b = AppBackend.instance;
            for (final p in list) {
              try {
                if (p.isOutOfStock) continue;
                if (!p.showOnLanding) continue;
                final m = MarketplaceDemoSeller.attach(
                  b.marketplaceProductMap(p),
                  seller,
                );
                m['isSellerListing'] = true;
                maps.add(m);
              } catch (e, st) {
                debugPrint('Skip product ${p.id}: $e\n$st');
              }
            }
            MarketplaceFirebaseCatalog.products = maps;
            unawaited(refreshGlbReachability().then((_) {
              notifyListeners();
            }));
          } catch (e, st) {
            debugPrint('LandingCatalogStore firebase sync: $e\n$st');
            MarketplaceFirebaseCatalog.products = <Map<String, dynamic>>[];
          }
          notifyListeners();
        },
        onError: (e, st) {
          debugPrint('streamAllProducts error: $e\n$st');
          MarketplaceFirebaseCatalog.products = <Map<String, dynamic>>[];
          notifyListeners();
        },
      );
    } catch (e, st) {
      debugPrint('startFirebaseSync failed: $e\n$st');
      _firebaseSub?.cancel();
      _firebaseSub = null;
    }
  }

  Future<void> ensureLoaded() async {
    try {
      await LandingModelsApi.instance.load();
      final next = LandingModelsApi.instance.productsWithRemoteUrls(
        kLandingPageProducts,
      );
      if (next.isNotEmpty) {
        _bundled = next;
      }
    } catch (e, st) {
      debugPrint('LandingCatalogStore.ensureLoaded: $e\n$st');
      _bundled = _defaultBundled();
    }
    try {
      final seller = await MarketplaceDemoSeller.resolve();
      MarketplaceDemoSeller.cache(seller);
      _bundled = _bundled
          .map((p) => MarketplaceDemoSeller.attach(p, seller))
          .toList();
    } catch (e, st) {
      debugPrint('LandingCatalogStore demo seller stamp: $e\n$st');
    }
    await _validateGlbLinks();
    notifyListeners();
  }

  Future<void> _validateGlbLinks() async {
    _reachableGlbIds = {
      for (final p in kLandingPageProducts)
        if (productHasRemoteGlbUrl(p))
          (p['id']?.toString() ?? ''),
    }..remove('');
    _glbCheckComplete = true;
    notifyListeners();

    if (!kIncludeSellerListingsInMarketplace) {
      debugPrint(
        'LandingCatalogStore: ${_reachableGlbIds.length} bundled 3D products',
      );
      return;
    }
    try {
      final extra = await GlbUrlValidator.reachableProductIds(
        MarketplaceFirebaseCatalog.products,
      );
      _reachableGlbIds = {..._reachableGlbIds, ...extra};
      debugPrint(
        'LandingCatalogStore: ${_reachableGlbIds.length} products with GLB',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('LandingCatalogStore GLB probe: $e');
    }
  }

  /// Re-check after Firebase seller sync.
  Future<void> refreshGlbReachability() => _validateGlbLinks();

  /// See more / category page — bundled + seller, no dead GLB listings.
  List<Map<String, dynamic>> allForSection(String section) {
    try {
      final bundled = _allBundledForSection(section);
      final seller = MarketplaceFirebaseCatalog.forSection(section);
      final seenSeller = <String>{};
      final out = <Map<String, dynamic>>[...bundled];

      if (kIncludeSellerListingsInMarketplace) {
        for (final p in seller) {
          final id =
              p['firebaseProductId']?.toString() ?? p['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            if (seenSeller.contains(id)) continue;
            seenSeller.add(id);
          }
          if (!_glbCheckComplete) {
            if (!productHasRemoteGlbUrl(p)) continue;
          } else {
            final pid = p['id']?.toString() ?? '';
            if (pid.isEmpty || !_reachableGlbIds.contains(pid)) continue;
          }
          out.add(Map<String, dynamic>.from(p)..['isSellerListing'] = true);
        }
      }
      return _filterListable(out);
    } catch (e, st) {
      debugPrint('allForSection($section): $e\n$st');
      return _allBundledForSection(section);
    }
  }

  List<Map<String, dynamic>> _allBundledForSection(String section) {
    final base = <Map<String, dynamic>>[];
    for (final p in kLandingPageProducts) {
      if (!productMatchesLandingSection(p, section)) continue;
      final loaded = _loadedBundledById(p['id']?.toString());
      base.add(loaded ?? Map<String, dynamic>.from(p));
    }
    return _filterListable(base);
  }

  @override
  void dispose() {
    _firebaseSub?.cancel();
    _firebaseSub = null;
    super.dispose();
  }
}

/// Landing grid — original bundled products only (4 per category).
List<Map<String, dynamic>> landingProductsForSection(String section) {
  return LandingCatalogStore.instance.previewForSection(section);
}

/// Full category page — all bundled + seller listings (works even if Firebase sync fails).
List<Map<String, dynamic>> landingAllProductsForSection(String section) {
  return LandingCatalogStore.instance.allForSection(section);
}
