import 'landing_section_utils.dart';

/// Live seller products from Firestore (updated by [LandingCatalogStore] / [MarketPlace3D]).
class MarketplaceFirebaseCatalog {
  MarketplaceFirebaseCatalog._();

  static List<Map<String, dynamic>> _products = <Map<String, dynamic>>[];

  static List<Map<String, dynamic>> get products =>
      List<Map<String, dynamic>>.from(_products);

  static set products(List<Map<String, dynamic>> value) {
    _products = value.isNotEmpty
        ? List<Map<String, dynamic>>.from(value)
        : <Map<String, dynamic>>[];
  }

  static List<Map<String, dynamic>> forSection(String section) {
    final src = _products;
    if (src.isEmpty) return <Map<String, dynamic>>[];
    final out = <Map<String, dynamic>>[];
    for (final p in src) {
      if (p.isEmpty) continue;
      if (productMatchesLandingSection(p, section)) {
        out.add(Map<String, dynamic>.from(p));
      }
    }
    return out;
  }
}
