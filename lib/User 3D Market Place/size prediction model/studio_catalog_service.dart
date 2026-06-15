import 'dart:convert';

import 'package:http/http.dart' as http;

import 'studio_config.dart';

class StudioCatalogProduct {
  const StudioCatalogProduct({
    required this.id,
    required this.label,
    required this.fileLabel,
    required this.publicPath,
    required this.modelUrl,
    required this.price,
  });

  final String id;
  final String label;
  final String fileLabel;
  final String publicPath;
  final String modelUrl;
  final String price;

  factory StudioCatalogProduct.fromJson(Map<String, dynamic> json) {
    return StudioCatalogProduct(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      fileLabel: json['fileLabel']?.toString() ?? '',
      publicPath: json['publicPath']?.toString() ?? '',
      modelUrl: json['modelUrl']?.toString() ?? json['publicPath']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
    );
  }
}

class StudioCatalog {
  const StudioCatalog({
    required this.products,
    required this.studioBase,
  });

  final List<StudioCatalogProduct> products;
  final String studioBase;

  factory StudioCatalog.fromJson(Map<String, dynamic> json) {
    final raw = json['products'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => StudioCatalogProduct.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <StudioCatalogProduct>[];
    return StudioCatalog(
      products: list,
      studioBase: json['studioBase']?.toString() ?? StudioConfig.studioBaseUrl,
    );
  }
}

/// Fetches all 3D studio products — tries live API then static JSON (Vercel).
class StudioCatalogService {
  StudioCatalogService._();

  static final StudioCatalogService instance = StudioCatalogService._();

  Future<StudioCatalog?> fetchCatalog() async {
    for (final uri in [
      StudioConfig.catalogApiUri,
      StudioConfig.catalogStaticUri,
    ]) {
      try {
        final res = await http.get(uri).timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) continue;
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          return StudioCatalog.fromJson(decoded);
        }
        if (decoded is List) {
          return StudioCatalog(
            products: decoded
                .whereType<Map>()
                .map((e) => StudioCatalogProduct.fromJson(Map<String, dynamic>.from(e)))
                .toList(),
            studioBase: StudioConfig.studioBaseUrl,
          );
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
