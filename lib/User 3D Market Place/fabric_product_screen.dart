import 'package:flutter/material.dart';

import 'marketplace_bottom_nav.dart';
import 'shopping_cart.dart';
import 'viewer_asset_src.dart';

/// Fabric product detail — no size prediction; standard e-commerce buy flow.
class FabricProductScreen extends StatefulWidget {
  const FabricProductScreen({super.key, required this.product});

  final Map<String, dynamic> product;

  @override
  State<FabricProductScreen> createState() => _FabricProductScreenState();
}

class _FabricProductScreenState extends State<FabricProductScreen> {
  late String _selectedSize;
  late String _selectedMaterial;
  late String _selectedColor;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _selectedSize = p['defaultSize']?.toString() ?? '4.5M';
    _selectedMaterial = p['material']?.toString() ?? 'Cotton';
    final colors = _colorList;
    _selectedColor = colors.isNotEmpty ? colors.first : 'Off White';
  }

  List<String> get _sizes => (widget.product['sizes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      ['4.5M', '5M', '6M'];

  List<String> get _materials =>
      (widget.product['materials'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      [widget.product['material']?.toString() ?? 'Cotton'];

  List<String> get _colorList =>
      (widget.product['colorOptions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      [widget.product['colorName']?.toString() ?? 'Off White'];

  int get _price => widget.product['price'] is int
      ? widget.product['price'] as int
      : int.tryParse('${widget.product['price']}') ?? 7000;

  CartItem _buildCartItem() {
    final p = widget.product;
    return cartItemFromProduct(
      p,
      size: _selectedSize,
      color: _selectedColor,
      material: _selectedMaterial,
      quantity: _quantity,
    );
  }

  void _addToCart() {
    ShoppingCart.instance.addItem(_buildCartItem());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product['title']} added to cart'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _buyNow() {
    ShoppingCart.instance.addAndOpenCart(_buildCartItem());
    MarketplaceBottomNav.goToTab(context, 3);
  }

  Widget _productImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.texture, size: 64),
      );
    }
    final src = imageSrcForProduct({'imagePath': imagePath});
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.texture, size: 64),
        ),
      );
    }
    return Image.asset(
      src,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.texture, size: 64),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final brand = p['brandName']?.toString() ?? 'Cotton King';
    final title = p['title']?.toString() ?? 'Premium Fabric';
    final imagePath = p['imagePath']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _addToCart,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF111827)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Add to cart',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _buyNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Buy now',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          MarketplaceBottomNav(
            selectedIndex: 0,
            onTap: (i) => MarketplaceBottomNav.goToTab(context, i),
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        title: const Text('Fabric', style: TextStyle(fontSize: 16)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imagePath.isNotEmpty)
              AspectRatio(
                aspectRatio: 1,
                child: _productImage(imagePath),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Material: $_selectedMaterial   Size: $_selectedSize',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rs. ${_price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    'Regular price',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  Text(
                    'PKR $_price',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _label('Size'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _sizes.map((s) => _chip(s, s == _selectedSize, () {
                      setState(() => _selectedSize = s);
                    })).toList(),
                  ),
                  const SizedBox(height: 20),
                  _label('Material'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        _materials.map((m) => _chip(m, m == _selectedMaterial, () {
                      setState(() => _selectedMaterial = m);
                    })).toList(),
                  ),
                  const SizedBox(height: 20),
                  _label('Color'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        _colorList.map((c) => _chip(c, c == _selectedColor, () {
                      setState(() => _selectedColor = c);
                    })).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _label('Quantity'),
                      const Spacer(),
                      IconButton(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_shipping_outlined,
                                color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Free nationwide shipping on orders over Rs. 5,000',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Delivers in 3–7 working days',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text(
                      'Shipping & Return',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          p['shippingReturn']?.toString() ??
                              'Unstitched fabric can be returned within 7 days if unused and in original packaging. '
                                  'Shipping is free on orders above Rs. 5,000 nationwide. '
                                  'Standard delivery 3–7 working days.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF374151),
        ),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? const Color(0xFF111827) : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}
