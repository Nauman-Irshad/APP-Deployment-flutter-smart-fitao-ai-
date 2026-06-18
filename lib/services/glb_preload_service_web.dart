import 'package:web/web.dart' as web;

import '../User 3D Market Place/size prediction model/cloth_prediction_service.dart';

/// Prefetch marketplace GLBs into the browser cache (faster model-viewer).
void warmMarketplaceGlbUrls(Iterable<String> urls) {
  final seen = <String>{};
  for (final raw in urls) {
    final url = raw.trim();
    if (url.isEmpty || !url.startsWith('http') || seen.contains(url)) continue;
    seen.add(url);

    final link = web.HTMLLinkElement()
      ..rel = 'preload'
      ..as = 'fetch'
      ..href = url
      ..crossOrigin = 'anonymous';
    web.document.head?.append(link);
  }
}

/// Ping Render size API while user browses (reduces cold-start wait on Predict).
void warmSizePredictionApi() {
  ClothPredictionService.instance.warmApiInBackground();
}
