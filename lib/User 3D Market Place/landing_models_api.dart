import 'landing_page_products.dart';
import 'viewer_asset_src.dart';

/// Local catalog from `landing page product/` (no external CDN).
class LandingModelsApi {
  LandingModelsApi._();

  static final LandingModelsApi instance = LandingModelsApi._();

  bool _loaded = false;

  bool get isLoaded => _loaded;
  String? get lastError => null;

  Future<void> load() async {
    _loaded = true;
  }

  List<Map<String, dynamic>> productsWithRemoteUrls(
    List<Map<String, dynamic>> source,
  ) {
    return source.map((p) {
      final copy = Map<String, dynamic>.from(p);
      final modelPath = copy['modelPath']?.toString();
      if (modelPath != null && modelPath.isNotEmpty) {
        copy['modelUrl'] = modelSrcForProduct(copy);
      }
      final imagePath = copy['imagePath']?.toString();
      if (imagePath != null && imagePath.isNotEmpty) {
        copy['imageUrl'] = imageSrcForProduct(copy);
      }
      return copy;
    }).toList(growable: false);
  }
}
