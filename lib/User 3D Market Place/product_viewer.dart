import 'package:flutter/material.dart';

import '../../services/customer_fitting_store.dart';
import 'fabric_product_screen.dart';
import 'size prediction model/live_measurement.dart';
import 'standard_sizes.dart';
import 'marketplace_pkr.dart';
import '../services/marketplace_demo_seller.dart';
import 'seller_profile_screen.dart';
import 'chat.dart';
import 'viewer_asset_src.dart';
import 'landing_page_products.dart';
import 'product_model_preview.dart';
import 'marketplace_bottom_nav.dart';

/// Seller profile listings — full landing catalog + shop info.
List<Map<String, dynamic>> sellerMarketplaceProducts({
  String sellerName = 'SmartFitao Store',
  String sellerAddress = '45 E1, near Lacas School, Johar Town, Lahore',
}) {
  return [
    for (final p in kLandingPageProducts)
      {
        ...Map<String, dynamic>.from(p),
        'sellerName': sellerName,
        'sellerAddress': sellerAddress,
      },
  ];
}

final List<Map<String, dynamic>> _sellerProducts = sellerMarketplaceProducts();

class ProductViewerScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductViewerScreen({super.key, required this.product});

  @override
  _ProductViewerScreenState createState() => _ProductViewerScreenState();
}

class _ProductViewerScreenState extends State<ProductViewerScreen> {
  String? _measurementMode;

  @override
  void initState() {
    super.initState();
    CustomerFittingStore.saveSelectedProduct(widget.product);
  }

  Widget _buildProductHero(double viewerHeight) {
    final isFabric = widget.product['section'] == 'Fabric' ||
        widget.product['category'] == 'Fabric';
    if (isFabric) {
      final fabricImg = widget.product['imagePath']?.toString() ?? '';
      if (fabricImg.isEmpty) return _noModelPlaceholder();
      return SizedBox(
        height: viewerHeight,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _fabricImage(imageSrcForProduct(widget.product)),
        ),
      );
    }

    final imagePath = widget.product['imagePath']?.toString();
    if (imagePath != null && imagePath.isNotEmpty) {
      return SizedBox(
        height: viewerHeight,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _fabricImage(landingAssetSrc(imagePath)),
        ),
      );
    }

    final src = modelSrcForProduct(widget.product);
    if (src.isEmpty) return _noModelPlaceholder();
    return SizedBox(
      height: viewerHeight,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ProductModelPreview(
          src: src,
          alt: widget.product['title']?.toString() ?? 'Outfit preview',
          compact: false,
        ),
      ),
    );
  }

  Widget _fabricImage(String src) {
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _noModelPlaceholder(),
      );
    }
    return Image.asset(
      src,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _noModelPlaceholder(),
    );
  }

  Widget _noModelPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.threed_rotation, size: 48, color: Colors.grey[500]),
          SizedBox(height: 8),
          Text(
            'No preview',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  bool get _isFabric =>
      widget.product['section'] == 'Fabric' ||
      widget.product['category'] == 'Fabric';

  @override
  Widget build(BuildContext context) {
    if (_isFabric) {
      return FabricProductScreen(product: widget.product);
    }

    if (_measurementMode == 'live') {
      return LiveMeasurementScreen(
        product: widget.product,
        onBack: () => setState(() => _measurementMode = null),
      );
    }

    if (_measurementMode == 'standard') {
      return StandardSizesScreen(
        product: widget.product,
        onBack: () => setState(() => _measurementMode = null),
      );
    }

    final outOfStock = widget.product['outOfStock'] == true;

    return Scaffold(
      floatingActionButton: null,
      backgroundColor: Color(0xFF171717),
      bottomNavigationBar: MarketplaceBottomNav(
        selectedIndex: 0,
        onTap: (i) => MarketplaceBottomNav.goToTab(context, i),
      ),
      appBar: AppBar(
        backgroundColor: Color(0xFF171717),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Back to Marketplace',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = 16.0;
          final screenW = constraints.maxWidth;
          final contentW = screenW - (padding * 2);
          final viewerHeight = contentW.clamp(200.0, 450.0);

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenW > 400 ? 20 : 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0f172a),
                          Color(0xFF111827),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 20,
                          offset: Offset(0, 12),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: double.infinity,
                            height: viewerHeight,
                            child: _buildProductHero(viewerHeight),
                          ),
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22c55e).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFF22c55e).withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.auto_awesome_motion,
                                    color: Color(0xFF22c55e), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Interactive 3D View',
                                  style: TextStyle(
                                    color: Color(0xFFbbf7d0),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          widget.product['title'] ?? '',
                          style: TextStyle(
                            fontSize: screenW > 360 ? 22 : 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        if (widget.product['colorName'] != null) ...[
                          SizedBox(height: 6),
                          Text(
                            'Color: ${widget.product['colorName']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                        if (widget.product['category'] != null) ...[
                          SizedBox(height: 4),
                          Text(
                            '${widget.product['category']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              formatPkr(widget.product['price'] is num
                                  ? widget.product['price'] as num
                                  : num.tryParse('${widget.product['price']}')),
                              style: TextStyle(
                                fontSize: screenW > 360 ? 20 : 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF22c55e),
                              ),
                            ),
                            if (widget.product['originalPrice'] != null &&
                                widget.product['originalPrice'] != 0) ...[
                              SizedBox(width: 10),
                              Text(
                                formatPkr(widget.product['originalPrice'] is num
                                    ? widget.product['originalPrice'] as num
                                    : num.tryParse('${widget.product['originalPrice']}')),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Premium quality ${(widget.product['category'] ?? '').toString().toLowerCase()} fabric with traditional tailoring details inspired by leading South Asian brands.',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.local_shipping_outlined,
                                      size: 18, color: Color(0xFF4ade80)),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Free delivery on orders above PKR 5,000 within Pakistan.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[200],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.schedule_outlined,
                                      size: 18, color: Color(0xFF4ade80)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Dispatch within 3–5 working days.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[200],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.category_outlined,
                                      size: 16, color: Colors.grey[300]),
                                  SizedBox(width: 6),
                                  Text(
                                    widget.product['category'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[200],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14),
                        // Seller – tap to open seller profile (Firestore-backed when sellerId is set)
                        GestureDetector(
                          onTap: () async {
                            final seller = await MarketplaceDemoSeller.resolve();
                            final stamped =
                                MarketplaceDemoSeller.attach(widget.product, seller);
                            if (!context.mounted) return;
                            final sName = stamped['sellerName']?.toString() ?? 'Seller';
                            final sAddr = stamped['sellerAddress']?.toString() ?? '';
                            final img = widget.product['imageUrl']?.toString();
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => SellerProfileScreen(
                                  sellerName: sName,
                                  sellerAddress: sAddr,
                                  shopImageUrl: img != null && img.isNotEmpty ? img : null,
                                  firebaseSellerId: seller.uid,
                                  products: const [],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.12)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF022c22),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.store, color: Color(0xFF22c55e), size: 24),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Seller',
                                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        widget.product['sellerName']?.toString() ?? 'SmartFitao Store',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.message_outlined, color: Color(0xFF22c55e), size: 22),
                                  onPressed: () async {
                                    final seller = await MarketplaceDemoSeller.resolve();
                                    final stamped =
                                        MarketplaceDemoSeller.attach(widget.product, seller);
                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => ChatScreen(
                                          initialChatName:
                                              stamped['sellerName']?.toString() ?? 'Seller',
                                          initialChatType: 'Seller',
                                          initialPeerId: seller.uid,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Icon(Icons.chevron_right, color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 18),
                        if (outOfStock) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade900.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade400),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.block, color: Colors.red.shade200, size: 22),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Out of stock — this item cannot be ordered until the seller adds stock.',
                                    style: TextStyle(
                                      color: Colors.red.shade100,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                        Text(
                          'Choose your measurement',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        GestureDetector(
                          onTap: outOfStock
                              ? null
                              : () => setState(() => _measurementMode = 'live'),
                          child: Container(
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(outOfStock ? 0.01 : 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(outOfStock ? 0.06 : 0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF022c22),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: outOfStock ? Colors.grey : Color(0xFF22c55e),
                                    size: 22,
                                  ),
                                ),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Live Measurement',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Use AI camera for perfect fit.',
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        GestureDetector(
                          onTap: outOfStock
                              ? null
                              : () =>
                                  setState(() => _measurementMode = 'standard'),
                          child: Container(
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(outOfStock ? 0.01 : 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(outOfStock ? 0.06 : 0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF111827),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.straighten,
                                    color: outOfStock ? Colors.grey : Color(0xFF22c55e),
                                    size: 22,
                                  ),
                                ),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Standard Sizes',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Quick choose from size chart.',
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),


              // Rating/review section removed as app does not use reviews anymore.

              SizedBox(height: 24),
            ],
          ),
        ),
      );
    },
    ),
    );
  }
}
