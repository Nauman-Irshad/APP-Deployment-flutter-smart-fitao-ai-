import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../Order-Tracking-System/services/app_backend.dart';
import '../Order-Tracking-System/tracking.dart' show OrderType;

class OrderSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String kurtaSize;
  final String pyjamaSize;
  final Map<String, String> kurtaMeasurements;
  final String pyjamaLength;

  const OrderSummaryScreen({
    super.key,
    required this.product,
    required this.kurtaSize,
    required this.pyjamaSize,
    required this.kurtaMeasurements,
    required this.pyjamaLength,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String _paymentMethod = 'cod'; // cod, jazzcash, debitcard, mastercard
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromProfile());
  }

  Future<void> _prefillFromProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !mounted) return;
    try {
      final profile = await AppBackend.instance.getUserProfile(user.uid);
      if (!mounted) return;
      setState(() {
        if (_nameController.text.trim().isEmpty) {
          _nameController.text =
              profile.name.isNotEmpty ? profile.name : (user.displayName ?? '');
        }
        if (_addressController.text.trim().isEmpty) {
          _addressController.text = profile.address;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showSizeChart() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your size chart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Kurta (${widget.kurtaSize})', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w600)),
            ...widget.kurtaMeasurements.entries.map((e) => Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key), Text(e.value)]),
            )),
            SizedBox(height: 12),
            Text('Pyjama (${widget.pyjamaSize})', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w600)),
            Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Length'), Text(widget.pyjamaLength)]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPay() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to place an order')),
      );
      return;
    }

    final productName = widget.product['title']?.toString() ?? 'Product';
    final unitPrice = (widget.product['price'] is num)
        ? (widget.product['price'] as num).toDouble()
        : double.tryParse(widget.product['price']?.toString() ?? '0') ?? 0.0;
    final sellerName = widget.product['sellerName']?.toString() ?? 'Seller';
    final sellerId = widget.product['sellerId']?.toString() ?? '';
    final productId =
        widget.product['firebaseProductId']?.toString() ?? widget.product['id']?.toString() ?? '';

    if (sellerId.isEmpty || productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing seller or product data — open this item from the marketplace')),
      );
      return;
    }

    if (widget.product['outOfStock'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This product is out of stock')),
      );
      return;
    }

    final backend = AppBackend.instance;
    AppUserProfile profile;
    try {
      profile = await backend.getUserProfile(user.uid);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load your profile')),
      );
      return;
    }

    final customerName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : profile.name;
    final deliveryAddress = _addressController.text.trim().isNotEmpty
        ? _addressController.text.trim()
        : profile.address;
    if (customerName.isEmpty || deliveryAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your name and delivery address')),
      );
      return;
    }

    final details = Map<String, dynamic>.from(
      (widget.product['details'] is Map) ? Map<String, dynamic>.from(widget.product['details'] as Map) : {},
    );
    details['kurtaSize'] = widget.kurtaSize;
    details['pyjamaSize'] = widget.pyjamaSize;
    details['pyjamaLength'] = widget.pyjamaLength;
    details['kurtaMeasurements'] = Map<String, String>.from(widget.kurtaMeasurements);
    details['paymentMethod'] = _paymentMethod;
    final imageUrl = widget.product['imageUrl']?.toString();
    if (imageUrl != null && imageUrl.isNotEmpty) details['imageUrl'] = imageUrl;
    final modelPath = widget.product['modelPath']?.toString();
    if (modelPath != null && modelPath.isNotEmpty) details['modelPath'] = modelPath;

    try {
      await backend.createOrder(
        customerId: profile.uid,
        customerName: customerName,
        productId: productId,
        productName: productName,
        totalAmount: unitPrice,
        quantity: _quantity,
        type: OrderType.standard,
        details: details,
        sellerId: sellerId,
        sellerName: sellerName,
        sellerAddress: widget.product['sellerAddress']?.toString() ?? '',
        deliveryAddress: deliveryAddress,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order failed: $e')),
        );
      }
      return;
    }

    if (!mounted) return;
    final lineTotal = unitPrice * _quantity;
    final isCod = _paymentMethod == 'cod';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF059669), size: 28),
            SizedBox(width: 8),
            Text(isCod ? 'Order placed' : 'Payment successful'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isCod ? 'Your order is placed. Details below.' : 'Payment successful. Your order is confirmed.'),
              SizedBox(height: 16),
              _orderInfoRow('Product name', productName),
              _orderInfoRow('Seller', sellerName),
              _orderInfoRow('Quantity', '$_quantity'),
              _orderInfoRow('Customer name', customerName),
              _orderInfoRow('Delivery address', deliveryAddress),
              _orderInfoRow('Total amount', 'PKR ${lineTotal.toStringAsFixed(0)}'),
              SizedBox(height: 8),
              Text('Cloth size chart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              _orderInfoRow('Kurta size', widget.kurtaSize),
              _orderInfoRow('Pyjama size', widget.pyjamaSize),
              _orderInfoRow('Pyjama length', widget.pyjamaLength),
              ...widget.kurtaMeasurements.entries.map((e) => _orderInfoRow(e.key, e.value)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              int pops = 0;
              while (Navigator.canPop(context) && pops < 5) {
                Navigator.pop(context);
                pops++;
              }
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _orderInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unitPrice = (widget.product['price'] is num)
        ? (widget.product['price'] as num).toDouble()
        : double.tryParse(widget.product['price']?.toString() ?? '0') ?? 0.0;
    final lineTotal = unitPrice * _quantity;
    final modelPath = widget.product['modelPath'] as String?;
    final imageUrl = widget.product['imageUrl'] as String?;
    final sellerLabel = widget.product['sellerName']?.toString() ?? 'SmartFitao Store';

    return Scaffold(
      backgroundColor: Color(0xFFf9fafb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Color(0xFF059669)), onPressed: () => Navigator.pop(context)),
        title: Text('Order Summary', style: TextStyle(color: Colors.grey[800], fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product & Seller – the product user came from
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Product', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  SizedBox(height: 4),
                  Text(
                    widget.product['title'] ?? 'Product',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.store_outlined, size: 18, color: Color(0xFF059669)),
                      SizedBox(width: 6),
                      Text('Seller: ', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      Expanded(
                        child: Text(
                          sellerLabel,
                          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF059669), fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Color(0xFF0f172a),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => modelPath != null && modelPath.isNotEmpty
                            ? ModelViewer(
                                src: kIsWeb ? '${Uri.base.origin}/$modelPath' : modelPath,
                                alt: widget.product['title']?.toString() ?? 'Product',
                                autoRotate: true,
                                cameraControls: true,
                                backgroundColor: Colors.transparent,
                              )
                            : Center(child: Icon(Icons.image_not_supported, size: 64, color: Colors.white54)),
                      )
                    : (modelPath != null && modelPath.isNotEmpty
                        ? ModelViewer(
                            src: kIsWeb ? '${Uri.base.origin}/$modelPath' : modelPath,
                            alt: widget.product['title']?.toString() ?? 'Product',
                            autoRotate: true,
                            cameraControls: true,
                            backgroundColor: Colors.transparent,
                          )
                        : Center(child: Icon(Icons.threed_rotation, size: 64, color: Colors.white54))),
              ),
            ),
            SizedBox(height: 16),

            // Customer name
            Text('Customer name', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            SizedBox(height: 4),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'Your name',
              ),
            ),
            SizedBox(height: 12),

            // Address
            Text('Delivery address', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            SizedBox(height: 4),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'Full address',
              ),
            ),
            SizedBox(height: 16),

            // Size chart card (tappable)
            InkWell(
              onTap: _showSizeChart,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Icon(Icons.straighten, color: Color(0xFF059669), size: 28),
                    SizedBox(width: 12),
                    Expanded(child: Text('Cloth size chart', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                    Text('Kurta ${widget.kurtaSize} · Pyjama ${widget.pyjamaSize}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600)),
                  Spacer(),
                  IconButton(
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    icon: Icon(Icons.remove_circle_outline, color: Color(0xFF059669)),
                  ),
                  Text('$_quantity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: Icon(Icons.add_circle_outline, color: Color(0xFF059669)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Total
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Color(0xFF059669).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        'PKR ${unitPrice.toStringAsFixed(0)} × $_quantity',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  Text(
                    'PKR ${lineTotal.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Payment method
            Text('Payment method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _PaymentChip(label: 'Cash on Delivery (COD)', value: 'cod', group: _paymentMethod, onSelect: () => setState(() => _paymentMethod = 'cod')),
            _PaymentChip(label: 'JazzCash', value: 'jazzcash', group: _paymentMethod, onSelect: () => setState(() => _paymentMethod = 'jazzcash')),
            _PaymentChip(label: 'Debit Card', value: 'debitcard', group: _paymentMethod, onSelect: () => setState(() => _paymentMethod = 'debitcard')),
            _PaymentChip(label: 'Mastercard', value: 'mastercard', group: _paymentMethod, onSelect: () => setState(() => _paymentMethod = 'mastercard')),
            SizedBox(height: 24),

            // Pay button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Pay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final String value;
  final String group;
  final VoidCallback onSelect;

  const _PaymentChip({required this.label, required this.value, required this.group, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final selected = group == value;
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Color(0xFF059669).withOpacity(0.15) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? Color(0xFF059669) : Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? Color(0xFF059669) : Colors.grey, size: 22),
              SizedBox(width: 12),
              Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}
