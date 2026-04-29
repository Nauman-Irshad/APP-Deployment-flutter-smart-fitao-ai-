import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'model 1 ai size prediction/live_measurement.dart';
import 'standard_sizes.dart';
import 'seller_profile_screen.dart';
import 'chat.dart';
import 'viewer_asset_src.dart';

/// Default seller profile listing — same single SKU as marketplace (`product1` GLB only).
final List<Map<String, dynamic>> _sellerProducts = [
  {'id': 1, 'title': 'Classic White Shalwar Kameez', 'price': 5490, 'category': 'Shalwar Kameez', 'modelPath': '3d viewer work/models/product1/product1.glb'},
];

class ProductViewerScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductViewerScreen({super.key, required this.product});

  @override
  _ProductViewerScreenState createState() => _ProductViewerScreenState();
}

class _ProductViewerScreenState extends State<ProductViewerScreen> {
  String? _measurementMode;

  Widget _buildProductHero(double viewerHeight) {
    final path = resolvedMarketplaceModelPath(widget.product);
    if (path.isEmpty) return _noModelPlaceholder();
    return SizedBox(
      height: viewerHeight,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ModelViewer(
          // `<model-viewer>` uses Three.js on web for GLTF.
          src: viewerAssetSrc(path),
          alt: widget.product['title']?.toString() ?? 'Outfit preview',
          loading: Loading.eager,
          reveal: Reveal.auto,
          autoRotate: true,
          autoRotateDelay: 0,
          rotationPerSecond: 'pi/6',
          cameraControls: true,
          interactionPrompt: InteractionPrompt.none,
          ar: false,
          debugLogging: false,
          backgroundColor: Colors.transparent,
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
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
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'PKR ${widget.product['price']}',
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
                                'PKR ${widget.product['originalPrice']}',
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
                          onTap: () {
                            final sid = widget.product['sellerId']?.toString();
                            final sName = widget.product['sellerName']?.toString() ?? 'Seller';
                            final sAddr = widget.product['sellerAddress']?.toString() ?? '';
                            final img = widget.product['imageUrl']?.toString();
                            if (sid != null && sid.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => SellerProfileScreen(
                                    sellerName: sName,
                                    sellerAddress: sAddr,
                                    shopImageUrl: img != null && img.isNotEmpty ? img : null,
                                    firebaseSellerId: sid,
                                    products: const [],
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => SellerProfileScreen(
                                    sellerName: 'SmartFitao Store',
                                    sellerAddress: '45 E1, near Lacas School, Johar Town, Lahore',
                                    shopImagePath: 'assets/banner 1.png',
                                    products: List<Map<String, dynamic>>.from(_sellerProducts),
                                  ),
                                ),
                              );
                            }
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
                                  onPressed: () {
                                    final sid = widget.product['sellerId']?.toString();
                                    final sName = widget.product['sellerName']?.toString() ?? 'Seller';
                                    final chatId = (sid != null && sid.isNotEmpty) ? 'seller_$sid' : 'seller_smartfitao_store';
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => ChatScreen(
                                          initialChatId: chatId,
                                          initialChatName: sName,
                                          initialChatType: 'Seller',
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
