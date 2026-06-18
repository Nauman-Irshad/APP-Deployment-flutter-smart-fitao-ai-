import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../payments/demo_order_placement.dart';
import '../../payments/stripe_pending_checkout.dart';
import '../../payments/stripe_payment_service.dart';
import '../../Order-Tracking-System/tracking.dart' show OrderType;
import '../marketplace_bottom_nav.dart';
import '../shopping_cart.dart';
import '../viewer_asset_src.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic>? product;
  final List<CartItem>? cartItems;
  final int? subtotal;
  final int? deliveryFee;
  final int? total;
  final String? userName;
  final String? address;
  final double? reducedPrice;

  const CheckoutPage({
    this.product,
    this.cartItems,
    this.subtotal,
    this.deliveryFee,
    this.total,
    this.userName,
    this.address,
    this.reducedPrice,
    super.key,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _quantity = 1;
  bool _isLoading = false;
  bool _isDemoPlacing = false;

  List<CartItem> get _items =>
      widget.cartItems ?? ShoppingCart.instance.items;

  bool get _fromCart => widget.cartItems != null || _items.isNotEmpty;

  int get _subtotal =>
      widget.subtotal ?? _singleSubtotal;

  int get _delivery =>
      widget.deliveryFee ??
      (_subtotal >= 5000 ? 0 : 1500);

  int get _total =>
      widget.total ?? (_subtotal + _delivery);

  int get _singleSubtotal {
    final p = widget.product;
    if (p == null) return 0;
    final price = (p['price'] as num?)?.toInt() ?? 0;
    return price * _quantity;
  }

  String _rs(int n) =>
      'PKR ${n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('Order Summary'),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_fromCart && _items.isNotEmpty)
                    ..._items.map(_buildCartLine)
                  else if (widget.product != null)
                    _buildSingleProductRow(widget.product!),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!_fromCart && widget.product != null) ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: const Icon(Icons.remove_circle),
                          color: const Color(0xFF059669),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _quantity < 10
                              ? () => setState(() => _quantity++)
                              : null,
                          icon: const Icon(Icons.add_circle),
                          color: const Color(0xFF059669),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPriceRow('Subtotal', _rs(_subtotal)),
                  const Divider(),
                  _buildPriceRow(
                    'Shipping',
                    _delivery == 0 ? 'Free' : _rs(_delivery),
                    isShipping: true,
                  ),
                  const Divider(),
                  _buildPriceRow('Total', _rs(_total), isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: (_isLoading || _isDemoPlacing) ? null : _placeDemoOrder,
                      icon: _isDemoPlacing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_circle_outline),
                      label: const Text('Order Place Demo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFb45309),
                        side: const BorderSide(color: Color(0xFFd97706), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _isDemoPlacing) ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Pay & Place Order',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Secure checkout via Stripe',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          MarketplaceBottomNav(
            selectedIndex: 3,
            onTap: (i) => MarketplaceBottomNav.goToTab(context, i),
          ),
        ],
      ),
    );
  }

  Widget _buildCartLine(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _productImage(
              item.imagePath,
              width: 80,
              height: 80,
              isFabric: item.isFabric,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _productDetails(item)),
        ],
      ),
    );
  }

  Widget _buildSingleProductRow(Map<String, dynamic> p) {
    final imagePath =
        p['imagePath']?.toString() ?? p['image']?.toString();
    final isFabric = p['category'] == 'Fabric' || p['section'] == 'Fabric';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _productImage(imagePath, width: 80, height: 80, isFabric: isFabric),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p['brandName'] != null)
                Text(
                  '${p['brandName']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              Text(
                p['title']?.toString() ?? 'Product',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              if (p['size'] != null)
                Text('Size: ${p['size']}', style: _detailStyle),
              if (p['color'] != null)
                Text('Color: ${p['color']}', style: _detailStyle),
              if (p['material'] != null)
                Text('Material: ${p['material']}', style: _detailStyle),
              const SizedBox(height: 6),
              Text(
                _rs((p['price'] as num?)?.toInt() ?? 0),
                style: const TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _productDetails(CartItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.brandName,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: item.isFabric ? const Color(0xFFF0FDF4) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            item.isFabric ? 'Fabric · ${item.variantLabel}' : item.variantLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: item.isFabric ? const Color(0xFF059669) : Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('Size: ${item.size}', style: _detailStyle),
        Text('Color: ${item.color}', style: _detailStyle),
        Text('Material: ${item.material}', style: _detailStyle),
        Text('Qty: ${item.quantity}', style: _detailStyle),
        const SizedBox(height: 6),
        Text(
          _rs(item.lineTotal),
          style: const TextStyle(
            color: Color(0xFF059669),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  TextStyle get _detailStyle =>
      TextStyle(fontSize: 12, color: Colors.grey.shade700);

  Widget _productImage(
    String? path, {
    required double width,
    required double height,
    required bool isFabric,
  }) {
    if (path != null &&
        path.isNotEmpty &&
        path.contains('landing page product')) {
      return SizedBox(
        width: width,
        height: height,
        child: buildLandingProductImage(
          path,
          fallback: _imageFallback(width, height, isFabric),
        ),
      );
    }
    if (path != null && path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(width, height, isFabric),
      );
    }
    return _imageFallback(width, height, isFabric);
  }

  Widget _imageFallback(double w, double h, bool isFabric) {
    return Container(
      width: w,
      height: h,
      color: Colors.grey.shade200,
      child: Icon(
        isFabric ? Icons.texture : Icons.checkroom,
        color: Colors.grey.shade500,
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isShipping = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isShipping && value == 'Free'
                ? Colors.green
                : (isTotal ? const Color(0xFF111827) : Colors.black),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _checkoutProduct() {
    if (widget.product != null) {
      return Map<String, dynamic>.from(widget.product!);
    }
    final first = _items.isNotEmpty ? _items.first : null;
    if (first == null) return {};
    return {
      'id': first.id,
      'title': first.title,
      'price': first.price,
      'size': first.size,
      'color': first.color,
      'material': first.material,
      'category': first.isFabric ? 'Fabric' : first.material,
      'imagePath': first.imagePath,
    };
  }

  Future<void> _placeDemoOrder() async {
    final product = _checkoutProduct();
    if (product.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No product in cart')),
      );
      return;
    }

    setState(() => _isDemoPlacing = true);
    try {
      final first = _items.isNotEmpty ? _items.first : null;
      final qty = first?.quantity ?? _quantity;
      final unitPrice = first?.price.toDouble() ??
          (widget.product?['price'] as num?)?.toDouble() ??
          0;
      final details = <String, dynamic>{
        'flow': 'standard_size',
        'size': first?.size ?? widget.product?['size']?.toString() ?? '',
        'color': first?.color ?? widget.product?['color']?.toString() ?? '',
        'material': first?.material ?? widget.product?['material']?.toString() ?? '',
        'quantity': qty,
        'shippingPkr': _delivery,
        'orderTotalPkr': _total,
      };

      await DemoOrderPlacement.placeAndGoHome(
        context: context,
        product: product,
        orderType: OrderType.standard,
        details: details,
        quantity: qty,
        unitPrice: unitPrice,
        deliveryAddress: widget.address,
        customerName: widget.userName,
        clearCart: true,
      );
    } finally {
      if (mounted) setState(() => _isDemoPlacing = false);
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in to pay with Stripe')),
          );
        }
        return;
      }
      final userId = user.uid;
      final first = _items.isNotEmpty ? _items.first : null;
      final title = first?.title ??
          widget.product?['title']?.toString() ??
          'Order';
      final productId =
          first?.id ?? widget.product?['id']?.toString() ?? 'unknown';
      final category = first?.isFabric == true
          ? 'Fabric'
          : (widget.product?['category']?.toString() ?? 'General');
      final imagePath = first?.imagePath ??
          widget.product?['imagePath']?.toString() ??
          widget.product?['image']?.toString() ??
          '';
      final qty = first?.quantity ?? _quantity;
      final unitPrice = first?.price.toDouble() ??
          (widget.product?['price'] as num?)?.toDouble() ??
          0;

      final description = _fromCart && _items.length > 1
          ? '${_items.length} items · ${_rs(_total)}'
          : 'Qty $qty · ${_rs(_total)}';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening Stripe secure checkout...'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }

      await StripePaymentService.startCheckout(
        amountPkr: _total,
        productName: title,
        description: description,
        pending: StripePendingCheckout(
          userId: userId,
          productId: productId,
          productTitle: title,
          quantity: qty,
          unitPrice: unitPrice,
          totalPkr: _total,
          category: category,
          productImage: imagePath,
          userName: widget.userName,
          address: widget.address,
          reducedPrice: widget.reducedPrice ?? _total.toDouble(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment could not start: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
