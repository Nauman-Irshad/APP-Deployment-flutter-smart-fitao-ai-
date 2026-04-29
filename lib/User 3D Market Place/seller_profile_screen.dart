import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../Order-Tracking-System/services/app_backend.dart';
import 'product_viewer.dart';
import 'chat.dart';

class SellerProfileScreen extends StatelessWidget {
  final String sellerName;
  final String sellerAddress;
  final String? shopImagePath;
  final String? shopImageUrl;
  /// When set, product grid loads from Firestore for this seller.
  final String? firebaseSellerId;
  final List<Map<String, dynamic>> products;

  const SellerProfileScreen({
    super.key,
    required this.sellerName,
    required this.sellerAddress,
    this.shopImagePath,
    this.shopImageUrl,
    this.firebaseSellerId,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF059669),
              Color(0xFF10b981),
              Colors.white,
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar – white bar like marketplace
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Color(0xFF059669)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Seller profile',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Seller: circular profile pic, name, address – no black container
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: shopImageUrl != null && shopImageUrl!.isNotEmpty
                                  ? Image.network(
                                      shopImageUrl!,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(Icons.store, size: 48, color: Color(0xFF059669)),
                                    )
                                  : shopImagePath != null
                                      ? Image.asset(
                                          shopImagePath!,
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(Icons.store, size: 48, color: Color(0xFF059669)),
                                        )
                                      : Icon(Icons.store, size: 48, color: Color(0xFF059669)),
                            ),
                          ),
                          SizedBox(height: 14),
                          Text(
                            sellerName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on_outlined, size: 18, color: Colors.white.withOpacity(0.9)),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  sellerAddress,
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          MaterialButton(
                            onPressed: () {
                              final chatId = firebaseSellerId != null && firebaseSellerId!.isNotEmpty
                                  ? 'seller_$firebaseSellerId'
                                  : 'seller_${sellerName.replaceAll(' ', '_').toLowerCase()}';
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    initialChatId: chatId,
                                    initialChatName: sellerName,
                                    initialChatType: 'Seller',
                                  ),
                                ),
                              );
                            },
                            color: Colors.white,
                            textColor: Color(0xFF059669),
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.message, size: 20),
                                SizedBox(width: 8),
                                Text('Message', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              ],
                            ),
                          ),
                        ],
                      ),

            SizedBox(height: 24),

            Text(
              'All products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
            SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                if (firebaseSellerId != null && firebaseSellerId!.isNotEmpty) {
                  final backend = AppBackend.instance;
                  return StreamBuilder<List<ProductModel>>(
                    stream: backend.streamProductsForSeller(firebaseSellerId!),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snap.hasError) {
                        return Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Could not load products: ${snap.error}'),
                        );
                      }
                      final items = (snap.data ?? []).map(backend.marketplaceProductMap).toList();
                      if (items.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('This seller has no listings yet.'),
                        );
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) => _buildProductTile(context, items[index]),
                      );
                    },
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) => _buildProductTile(context, products[index]),
                );
              },
            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductTile(BuildContext context, Map<String, dynamic> p) {
    final price = p['price'] ?? 0;
    final priceNum = price is num ? price.toDouble() : double.tryParse(price.toString()) ?? 0;
    final origRaw = p['originalPrice'];
    final originalPrice = origRaw is num ? origRaw.toDouble() : (origRaw != null ? double.tryParse(origRaw.toString()) ?? 0 : 0.0);
    final imageUrl = p['imageUrl'] as String?;
    final modelPath = p['modelPath'] as String?;
    final outOfStock = p['outOfStock'] == true;

    void open() {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => ProductViewerScreen(product: p)),
      );
    }

    return GestureDetector(
      onTap: open,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      color: Colors.black,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.broken_image, size: 40, color: Colors.white38),
                              ),
                            )
                          : modelPath != null && modelPath.isNotEmpty
                              ? ModelViewer(
                                  src: kIsWeb ? '${Uri.base.origin}/$modelPath' : modelPath,
                                  alt: p['title']?.toString() ?? 'Product',
                                  autoRotate: true,
                                  cameraControls: true,
                                  backgroundColor: Colors.transparent,
                                )
                              : Center(child: Icon(Icons.threed_rotation, size: 40, color: Colors.white38)),
                    ),
                  ),
                  if (outOfStock)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['title']?.toString() ?? 'Product',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          p['category']?.toString() ?? '',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Rs $price',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: Color(0xFF059669),
                              ),
                            ),
                            if (originalPrice > priceNum) ...[
                              SizedBox(width: 4),
                              Text(
                                'Rs ${originalPrice.round()}',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                        ElevatedButton(
                          onPressed: outOfStock ? null : open,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: outOfStock ? Colors.grey : Color(0xFF059669),
                            disabledBackgroundColor: Colors.grey.shade400,
                            minimumSize: Size(72, 28),
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            outOfStock ? 'N/A' : 'Buy Now',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopPlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Color(0xFF022c22),
      child: Icon(Icons.store, size: 64, color: Color(0xFF22c55e).withOpacity(0.6)),
    );
  }
}
