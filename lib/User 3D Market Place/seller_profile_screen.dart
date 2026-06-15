import 'package:flutter/material.dart';

import '../Order-Tracking-System/services/app_backend.dart';
import 'category_products_page.dart';
import 'chat.dart';
import 'landing_page_products.dart';
import 'viewer_asset_src.dart';

class SellerProfileScreen extends StatelessWidget {
  final String sellerName;
  final String sellerAddress;
  final String? shopImagePath;
  final String? shopImageUrl;
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

  List<Map<String, dynamic>> _bundledProducts() {
    if (products.isNotEmpty) return products;
    return [
      for (final p in kLandingPageProducts)
        {
          ...Map<String, dynamic>.from(p),
          'sellerName': sellerName,
          'sellerAddress': sellerAddress,
        },
    ];
  }

  int _gridColumns(double w) {
    if (w > 1000) return 4;
    if (w > 600) return 2;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF059669), Color(0xFF10b981), Colors.white],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF059669)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.store,
                                        size: 48,
                                        color: Color(0xFF059669),
                                      ),
                                    )
                                  : shopImagePath != null
                                      ? Image.asset(
                                          shopImagePath!,
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.store,
                                            size: 48,
                                            color: Color(0xFF059669),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.store,
                                          size: 48,
                                          color: Color(0xFF059669),
                                        ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            sellerName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 18, color: Colors.white.withValues(alpha: 0.9)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  sellerAddress,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          MaterialButton(
                            onPressed: () {
                              final chatId = firebaseSellerId != null &&
                                      firebaseSellerId!.isNotEmpty
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
                            textColor: const Color(0xFF059669),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.message, size: 20),
                                SizedBox(width: 8),
                                Text('Message',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 15)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'All products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProductGrid(
                        firebaseSellerId: firebaseSellerId,
                        fallbackProducts: _bundledProducts(),
                        columnsForWidth: _gridColumns,
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
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.firebaseSellerId,
    required this.fallbackProducts,
    required this.columnsForWidth,
  });

  final String? firebaseSellerId;
  final List<Map<String, dynamic>> fallbackProducts;
  final int Function(double) columnsForWidth;

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(16),
              child: Text('Could not load products: ${snap.error}'),
            );
          }
          final items = (snap.data ?? []).map(backend.marketplaceProductMap).toList();
          if (items.isEmpty) {
            return _marketplaceGrid(context, fallbackProducts);
          }
          return _marketplaceGrid(context, items);
        },
      );
    }
    return _marketplaceGrid(context, fallbackProducts);
  }

  Widget _marketplaceGrid(BuildContext context, List<Map<String, dynamic>> items) {
    final w = MediaQuery.sizeOf(context).width - 32;
    final cols = columnsForWidth(w);
    final spacing = 14.0;
    final itemWidth = (w - spacing * (cols - 1)) / cols;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: items.map((product) {
        return SizedBox(
          width: itemWidth,
          child: CategoryProductCard(
            product: product,
            show3dPreview: productHasRemoteGlbUrl(product),
          ),
        );
      }).toList(),
    );
  }
}
