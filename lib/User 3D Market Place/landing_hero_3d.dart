import 'package:flutter/material.dart';

import 'category_products_page.dart';
import 'landing_page_products.dart';
import 'marketplace_theme.dart';
import 'product_model_preview.dart';
import 'viewer_asset_src.dart';

/// Single live 3D on landing — product #1 black kurta (avoids 8× WebView + null errors).
class LandingHero3D extends StatelessWidget {
  const LandingHero3D({super.key});

  @override
  Widget build(BuildContext context) {
    final product = kLandingPageProducts.firstWhere(
      (p) => p['id'] == 'lp_kurta_black',
      orElse: () => kLandingPageProducts.first,
    );
    final title = product['title']?.toString() ?? 'Black Kurta';
    final src = modelSrcForProduct(product);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shadowColor: Colors.black26,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MarketplaceTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '3D LIVE',
                      style: TextStyle(
                        color: MarketplaceTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 300,
              child: src.isEmpty
                  ? const Center(child: Icon(Icons.view_in_ar, size: 48))
                  : ProductModelPreview(
                      src: src,
                      alt: title,
                      compact: false,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: FilledButton(
                onPressed: () => openLandingProduct(context, product),
                style: FilledButton.styleFrom(
                  backgroundColor: MarketplaceTheme.primary,
                  minimumSize: const Size.fromHeight(44),
                ),
                child: const Text('View product details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
