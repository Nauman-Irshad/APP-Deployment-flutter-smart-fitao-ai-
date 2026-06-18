import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/marketplace_demo_seller.dart';
import 'fabric_product_screen.dart';
import 'landing_catalog_store.dart';
import 'landing_page_products.dart';
import 'marketplace_pkr.dart';
import 'product_viewer.dart';
import 'marketplace_theme.dart';
import 'seller_profile_screen.dart';
import 'shopping_cart.dart';
import 'stitched_purchase_flow.dart';
import 'landing_models_api.dart';
import 'product_model_preview.dart';
import 'viewer_asset_src.dart';

/// Opens the correct detail page (fabric vs stitched 3D).
void openLandingProduct(BuildContext context, Map<String, dynamic> product) async {
  final stamped = await MarketplaceDemoSeller.attachAsync(product);
  if (!context.mounted) return;
  final isFabric =
      stamped['section'] == 'Fabric' || stamped['category'] == 'Fabric';
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => isFabric
          ? FabricProductScreen(product: stamped)
          : ProductViewerScreen(product: stamped),
    ),
  );
}

void openCategoryPage(BuildContext context, String sectionTitle) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => CategoryProductsPage(sectionTitle: sectionTitle),
    ),
  );
}

/// Full-page grid for one category (Kurta Shalwar / Shalwar Kameez / Fabric).
class CategoryProductsPage extends StatefulWidget {
  const CategoryProductsPage({super.key, required this.sectionTitle});

  final String sectionTitle;

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  @override
  void initState() {
    super.initState();
    LandingCatalogStore.instance.addListener(_rebuild);
    LandingCatalogStore.instance.ensureLoaded().then((_) {
      if (!mounted) return;
      setState(() {});
      try {
        LandingCatalogStore.instance.startFirebaseSync();
      } catch (_) {}
    });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LandingCatalogStore.instance.removeListener(_rebuild);
    super.dispose();
  }

  int _columns(double w) {
    if (w > 1000) return 4;
    if (w > 600) return 2;
    return 2;
  }

  List<Map<String, dynamic>> _sellersIn(List<Map<String, dynamic>> products) {
    final byId = <String, Map<String, dynamic>>{};
    for (final p in products) {
      final id = p['sellerId']?.toString() ?? '';
      if (id.isEmpty) continue;
      byId[id] = {
        'sellerId': id,
        'sellerName': p['sellerName']?.toString() ?? 'Seller',
        'sellerAddress': p['sellerAddress']?.toString() ?? '',
      };
    }
    return byId.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = LandingCatalogStore.instance;
    final products = categoryProductsWithGlbOrFabric(
      widget.sectionTitle,
      landingAllProductsForSection(widget.sectionTitle),
      reachableIds: store.reachableGlbIds,
      glbCheckComplete: store.glbCheckComplete,
    );
    final sellers = _sellersIn(products);
    final w = MediaQuery.sizeOf(context).width;
    final cols = _columns(w);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        title: Text(
          widget.sectionTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${products.length} products',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            if (sellers.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Sellers in this category',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ...sellers.map((s) {
                final name = s['sellerName']?.toString() ?? 'Seller';
                final addr = s['sellerAddress']?.toString() ?? '';
                final sid = s['sellerId']?.toString() ?? '';
                final sellerProducts = products
                    .where((p) => p['sellerId']?.toString() == sid)
                    .toList();
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF059669),
                      child: Icon(Icons.store, color: Colors.white),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      addr.isNotEmpty ? addr : 'Tap for seller profile & all listings',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => SellerProfileScreen(
                            sellerName: name,
                            sellerAddress: addr,
                            firebaseSellerId: sid,
                            products: sellerProducts,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No products in ${widget.sectionTitle} yet. Sellers can add items from the seller dashboard with "Show on 3D landing" enabled.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final spacing = 14.0;
                  final itemWidth =
                      (constraints.maxWidth - spacing * (cols - 1)) / cols;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: products.map((product) {
                      return SizedBox(
                        width: itemWidth,
                        child: CategoryProductCard(
                          product: product,
                          show3dPreview: productHasRemoteGlbUrl(product),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

String _productTitle(Map<String, dynamic> product) {
  final t = product['title']?.toString().trim();
  if (t != null && t.isNotEmpty && t != 'null') return t;
  return 'Product';
}

int _productStaggerIndex(Map<String, dynamic> product) {
  final id = product['id']?.toString() ?? product['title']?.toString() ?? '';
  var h = 0;
  for (final c in id.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h % 8;
}

/// Reusable product card for landing + category pages.
class CategoryProductCard extends StatelessWidget {
  const CategoryProductCard({
    super.key,
    required this.product,
    this.show3dPreview = false,
    this.staggerIndex,
  });

  final Map<String, dynamic> product;
  /// Full category page: live 3D preview. Landing grid: poster only.
  final bool show3dPreview;
  final int? staggerIndex;

  void _addToCart(BuildContext context, {required bool openCart}) {
    if (isStitchedOutfit(product)) {
      showStitchedPurchaseSheet(context, product, openCartAfter: openCart);
      return;
    }
    final isFabric =
        product['section'] == 'Fabric' || product['category'] == 'Fabric';
    final colorOptions = product['colorOptions'] as List<dynamic>?;
    final color = isFabric && colorOptions != null && colorOptions.isNotEmpty
        ? colorOptions.first.toString()
        : product['colorName']?.toString() ?? 'Default';
    final item = cartItemFromProduct(
      product,
      size: isFabric
          ? product['defaultSize']?.toString() ?? '4.5M'
          : 'Standard',
      color: color,
      material: isFabric
          ? product['material']?.toString() ?? 'Cotton'
          : product['category']?.toString() ?? 'Stitched',
      quantity: 1,
    );
    if (openCart) {
      ShoppingCart.instance.addAndOpenCart(item);
    } else {
      ShoppingCart.instance.addItem(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_productTitle(product)} added to cart'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = product['price'];
    final original = product['originalPrice'];
    final disc = product['discountPercent'];
    final discPct = disc is num
        ? disc.round()
        : int.tryParse(disc?.toString() ?? '') ?? 0;
    final isFabric = product['section'] == 'Fabric';
    final sellerName = product['sellerName']?.toString() ?? '';
    final canRotate3d = show3dPreview && productHasRemoteGlbUrl(product);

    final previewStack = AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: _Preview(
              product: product,
              title: _productTitle(product),
              compact: true,
              show3dPreview: show3dPreview,
              staggerIndex: staggerIndex ?? _productStaggerIndex(product),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isFabric || !productHasRemoteGlbUrl(product)
                    ? 'View'
                    : (canRotate3d ? 'Drag to rotate' : '3D View'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final productInfo = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _productTitle(product),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (sellerName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sellerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            product['colorName']?.toString() ?? '',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              Text(
                formatPkr(price is num ? price : num.tryParse('$price')),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF059669),
                ),
              ),
              if (original != null && original != 0)
                Text(
                  formatPkr(original is num ? original : num.tryParse('$original')),
                  style: TextStyle(
                    fontSize: 11,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade400,
                  ),
                ),
              if (discPct > 0)
                Text(
                  '-$discPct%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.red.shade700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canRotate3d) ...[
            previewStack,
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => openLandingProduct(context, product),
                child: productInfo,
              ),
            ),
          ] else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => openLandingProduct(context, product),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [previewStack, productInfo],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _addToCart(context, openCart: false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Color(0xFF059669)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Add to cart',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addToCart(context, openCart: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Buy now',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _productImage(String src, Map<String, dynamic> product, String title) {
  final path = product['imagePath']?.toString();
  return buildLandingProductImage(
    path != null && path.isNotEmpty ? path : src,
    fallback: _LandingGridThumbnail(product: product, title: title),
  );
}

/// Fast landing-grid tile — avoids 8× heavy GLB WebViews on Chrome/Edge.
class _LandingGridThumbnail extends StatelessWidget {
  const _LandingGridThumbnail({
    required this.product,
    required this.title,
  });

  final Map<String, dynamic> product;
  final String title;

  @override
  Widget build(BuildContext context) {
    final imagePath = product['imagePath']?.toString();
    if (imagePath != null && imagePath.isNotEmpty) {
      return ColoredBox(
        color: const Color(0xFF1a1a1a),
        child: buildLandingProductImage(
          imagePath,
          fallback: _placeholder(isFabric: true),
        ),
      );
    }
    // Stitched outfits: R2 GLB only (no PNG poster). Fabric keeps imagePath above.
    if (productHasRemoteGlbUrl(product)) {
      final src = modelSrcForProduct(product);
      if (src.isNotEmpty) {
        return ProductModelPreview(
          src: src,
          alt: title,
          compact: true,
          staggerIndex: _productStaggerIndex(product),
        );
      }
    }
    return _placeholder(isFabric: false);
  }

  Widget _placeholder({required bool isFabric}) {
    final colorName = product['colorName']?.toString() ?? '';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2937), Color(0xFF111827)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFabric ? Icons.texture : Icons.view_in_ar,
            size: 40,
            color: Colors.white70,
          ),
          if (colorName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                colorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            isFabric ? 'Fabric' : 'Tap for 3D',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.product,
    required this.title,
    this.compact = true,
    this.show3dPreview = false,
    this.staggerIndex = 0,
  });

  final Map<String, dynamic> product;
  final String title;
  /// Grid cards on the landing page (smaller preview).
  final bool compact;
  final bool show3dPreview;
  final int staggerIndex;

  @override
  Widget build(BuildContext context) {
    final imagePath = product['imagePath']?.toString();
    if (imagePath != null && imagePath.isNotEmpty) {
      return ColoredBox(
        color: const Color(0xFF1a1a1a),
        child: buildLandingProductImage(
          imagePath,
          fallback: _LandingGridThumbnail(product: product, title: title),
        ),
      );
    }

    if (!show3dPreview || !productHasRemoteGlbUrl(product)) {
      return _LandingGridThumbnail(product: product, title: title);
    }

    final src = modelSrcForProduct(product);
    if (!productHasRemoteGlbUrl(product)) {
      return _LandingGridThumbnail(product: product, title: title);
    }

    return ProductModelPreview(
      src: src,
      alt: title,
      compact: compact,
      staggerIndex: staggerIndex,
    );
  }
}

/// Clickable category chips — opens [CategoryProductsPage].
class LandingCategorySlider extends StatelessWidget {
  const LandingCategorySlider({super.key});

  IconData _iconFor(String tab) {
    if (tab == 'Fabric') return Icons.texture;
    if (tab == 'Kurta Shalwar') return Icons.checkroom_outlined;
    if (tab == 'Shalwar Kameez') return Icons.person_outline;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shop by category',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MarketplaceTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: kLandingCatalogTabs.map((tab) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: tab != kLandingCatalogTabs.last ? 8 : 0,
                  ),
                  child: Material(
                    color: MarketplaceTheme.surface,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => openCategoryPage(context, tab),
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MarketplaceTheme.border),
                          boxShadow: [MarketplaceTheme.cardShadow],
                        ),
                        child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 11,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _iconFor(tab),
                              color: MarketplaceTheme.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                tab,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: MarketplaceTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
