import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

export 'seller_tracking_order.dart';
export 'tailor_tracking_order.dart';
export 'user_tracking_order.dart';

import 'services/app_backend.dart';
import 'tracking.dart' show OrderType;

import 'tracking.dart' as tracking;
import 'user_tracking_order.dart';

class UserProductsPageFirebase extends StatefulWidget {
  const UserProductsPageFirebase({super.key});

  @override
  State<UserProductsPageFirebase> createState() => _UserProductsPageFirebaseState();
}

class _UserProductsPageFirebaseState extends State<UserProductsPageFirebase> {
  final AppBackend _backend = AppBackend.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppUserProfile? _customerProfile;
  final Map<String, int> _productQuantities = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final profile = await _backend.getUserProfile(uid);
    setState(() {
      _customerProfile = profile;
    });
  }

  /// Max quantity shown in the user bulk-buy list (capped at 5; respects real stock).
  int _maxOrderQty(ProductModel product) {
    if (!product.isPurchasable) return 0;
    if (product.stockQuantity >= 999999) return 5;
    return product.stockQuantity.clamp(0, 5);
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const tracking.RoleSelectionScreen()),
    );
  }

  Future<void> _placeStandardOrder({
    required ProductModel product,
    required int quantity,
  }) async {
    if (!product.isPurchasable) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This product is out of stock')),
      );
      return;
    }

    final profile = _customerProfile ?? await _backend.getUserProfile(AppBackend.instance.currentUid);

    final discount = product.discountPercent.clamp(0, 100);
    final unitPriceAfterDiscount = product.price * (1 - (discount / 100));

    final orderId = await _backend.createOrder(
      customerId: profile.uid,
      customerName: profile.name,
      productId: product.id,
      productName: product.name,
      totalAmount: unitPriceAfterDiscount,
      quantity: quantity,
      type: OrderType.standard,
      details: product.details,
      sellerId: product.sellerId,
      sellerName: product.sellerName,
      sellerAddress: product.sellerAddress,
      tailorId: null,
      tailorName: null,
      tailorAddress: '',
      deliveryAddress: profile.address,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order placed (Standard). id=$orderId')),
    );
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserOrdersPageFirebase()),
    );
  }

  Future<void> _placeCustomOrder({
    required ProductModel product,
    required int quantity,
  }) async {
    if (!product.isPurchasable) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This product is out of stock')),
      );
      return;
    }

    final profile = _customerProfile ?? await _backend.getUserProfile(AppBackend.instance.currentUid);

    final tailors = await _backend.fetchAvailableTailors();
    if (tailors.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No tailors available with a stitching rate. Tailors must tap “Add rates” after login.',
          ),
        ),
      );
      return;
    }

    final selectedTailor = await showDialog<AppUserProfile>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Tailor'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tailors.length,
            itemBuilder: (context, index) {
              final t = tailors[index];
              final label = t.shopName.isNotEmpty ? t.shopName : t.name;
              return ListTile(
                title: Text(label),
                subtitle: Text(
                  '${t.name} • Rate: PKR ${t.stitchingRate.toStringAsFixed(0)} / unit',
                ),
                onTap: () => Navigator.pop(context, t),
              );
            },
          ),
        ),
      ),
    );

    if (selectedTailor == null) return;

    final userCustomDetails = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final neck = TextEditingController();
        final shoulder = TextEditingController();
        final chest = TextEditingController();
        final waist = TextEditingController();
        final hip = TextEditingController();
        final armLength = TextEditingController();
        final bicep = TextEditingController();
        final forearm = TextEditingController();
        final wrist = TextEditingController();
        final thigh = TextEditingController();
        final calf = TextEditingController();
        final insideLeg = TextEditingController();

        final kurtaSize = TextEditingController();
        final pyjamaSize = TextEditingController();
        final pyjamaLength = TextEditingController();
        final sleeveLength = TextEditingController();
        final frontLength = TextEditingController();
        final paymentMethod = TextEditingController();

        return AlertDialog(
          title: const Text('Custom Order Details'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () {
                        // Static values for demo / testing (simulates "live measurement").
                        neck.text = '16';
                        shoulder.text = '18';
                        chest.text = '45';
                        waist.text = '40';
                        hip.text = '46';
                        armLength.text = '25';
                        bicep.text = '14';
                        forearm.text = '12';
                        wrist.text = '8';
                        thigh.text = '24';
                        calf.text = '16';
                        insideLeg.text = '32';
                        kurtaSize.text = 'L/40';
                        pyjamaSize.text = 'L/40';
                        pyjamaLength.text = '42';
                        sleeveLength.text = '25';
                        frontLength.text = '42';
                        paymentMethod.text = 'Credit Card';
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Live Measurement'),
                    ),
                  ),
                  TextField(controller: neck, decoration: const InputDecoration(labelText: 'Neck')),
                  TextField(controller: shoulder, decoration: const InputDecoration(labelText: 'Shoulder')),
                  TextField(controller: chest, decoration: const InputDecoration(labelText: 'Chest')),
                  TextField(controller: waist, decoration: const InputDecoration(labelText: 'Waist')),
                  TextField(controller: hip, decoration: const InputDecoration(labelText: 'Hip')),
                  TextField(controller: armLength, decoration: const InputDecoration(labelText: 'Arm Length')),
                  TextField(controller: bicep, decoration: const InputDecoration(labelText: 'Bicep')),
                  TextField(controller: forearm, decoration: const InputDecoration(labelText: 'Forearm')),
                  TextField(controller: wrist, decoration: const InputDecoration(labelText: 'Wrist')),
                  TextField(controller: thigh, decoration: const InputDecoration(labelText: 'Thigh')),
                  TextField(controller: calf, decoration: const InputDecoration(labelText: 'Calf')),
                  TextField(controller: insideLeg, decoration: const InputDecoration(labelText: 'Inside Leg')),
                  const SizedBox(height: 8),
                  TextField(controller: kurtaSize, decoration: const InputDecoration(labelText: 'Kurta Size')),
                  TextField(controller: pyjamaSize, decoration: const InputDecoration(labelText: 'Pyjama Size')),
                  TextField(controller: pyjamaLength, decoration: const InputDecoration(labelText: 'Pyjama Length')),
                  TextField(controller: sleeveLength, decoration: const InputDecoration(labelText: 'Sleeve Length')),
                  TextField(controller: frontLength, decoration: const InputDecoration(labelText: 'Front Length')),
                  TextField(controller: paymentMethod, decoration: const InputDecoration(labelText: 'Payment Method')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final details = <String, dynamic>{
                  'clothSizeChart': {
                    'Neck': neck.text.trim(),
                    'Shoulder': shoulder.text.trim(),
                    'Chest': chest.text.trim(),
                    'Waist': waist.text.trim(),
                    'Hip': hip.text.trim(),
                    'Arm Length': armLength.text.trim(),
                    'Bicep': bicep.text.trim(),
                    'Forearm': forearm.text.trim(),
                    'Wrist': wrist.text.trim(),
                    'Thigh': thigh.text.trim(),
                    'Calf': calf.text.trim(),
                    'Inside Leg': insideLeg.text.trim(),
                  },
                  'kurtaSize': kurtaSize.text.trim(),
                  'pyjamaSize': pyjamaSize.text.trim(),
                  'pyjamaLength': pyjamaLength.text.trim(),
                  'sleeveLength': sleeveLength.text.trim(),
                  'frontLength': frontLength.text.trim(),
                  'paymentMethod': paymentMethod.text.trim(),
                };

                // Merge seller suit info (color/length/fabric) into order details too.
                details.addAll(product.details);

                Navigator.pop(context, details);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (userCustomDetails == null) return;

    final discount = product.discountPercent.clamp(0, 100);
    final unitPriceAfterDiscount = product.price * (1 - (discount / 100));
    final tailorStitchingTotal = selectedTailor.stitchingRate * quantity;
    final tailorDisplayName = selectedTailor.shopName.isNotEmpty
        ? '${selectedTailor.shopName} (${selectedTailor.name})'
        : selectedTailor.name;

    final orderId = await _backend.createOrder(
      customerId: profile.uid,
      customerName: profile.name,
      productId: product.id,
      productName: product.name,
      totalAmount: unitPriceAfterDiscount,
      quantity: quantity,
      type: OrderType.custom,
      details: userCustomDetails,
      sellerId: product.sellerId,
      sellerName: product.sellerName,
      sellerAddress: product.sellerAddress,
      tailorId: selectedTailor.uid,
      tailorName: tailorDisplayName,
      tailorAddress: selectedTailor.address,
      deliveryAddress: profile.address,
      tailorStitchingTotal: tailorStitchingTotal,
      precomputedTailorProfitTotal: selectedTailor.tailorProfitPerUnit * quantity,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order placed (Custom). id=$orderId')),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserOrdersPageFirebase()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _customerProfile == null ? 'Products' : 'Hi, ${_customerProfile!.name}',
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserOrdersPageFirebase()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _backend.streamAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading products: ${snapshot.error}'));
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No products yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final maxQ = _maxOrderQty(product);
              var qty = _productQuantities[product.id] ?? 1;
              if (maxQ > 0 && qty > maxQ) qty = maxQ;
              if (maxQ > 0 && qty < 1) qty = 1;
              final canBuy = product.isPurchasable && maxQ > 0;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Seller: ${product.sellerName}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final discount = product.discountPercent.clamp(0, 100);
                          final finalUnitPrice =
                              product.price * (1 - (discount / 100));
                          if (discount <= 0) {
                            return Text(
                              'Price: PKR ${finalUnitPrice.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 16),
                            );
                          }
                          return Text(
                            'Price: PKR ${finalUnitPrice.toStringAsFixed(0)} (Save ${discount.toStringAsFixed(0)}%)',
                            style: const TextStyle(fontSize: 16),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      if (canBuy)
                        DropdownButton<int>(
                          value: qty,
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _productQuantities[product.id] = v;
                            });
                          },
                          items: List.generate(
                            maxQ,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text('Qty: ${i + 1}'),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Out of stock',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: canBuy
                                  ? () => _placeStandardOrder(
                                        product: product,
                                        quantity: qty,
                                      )
                                  : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                                minimumSize: const Size(0, 44),
                              ),
                              child: const Text('Standard'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: canBuy
                                  ? () => _placeCustomOrder(
                                        product: product,
                                        quantity: qty,
                                      )
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 44),
                              ),
                              child: const Text('Custom'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SellerProductsPageFirebase extends StatefulWidget {
  const SellerProductsPageFirebase({super.key});

  @override
  State<SellerProductsPageFirebase> createState() => _SellerProductsPageFirebaseState();
}

class _SellerProductsPageFirebaseState extends State<SellerProductsPageFirebase> {
  final backend = AppBackend.instance;
  final auth = FirebaseAuth.instance;

  AppUserProfile? _sellerProfile;
  bool _isSaving = false;

  // Common fields
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productDiscountController = TextEditingController();
  final TextEditingController _productStockController = TextEditingController(text: '1');
  final TextEditingController _productProfitController = TextEditingController(text: '0');
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _modelPathController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // Body chart (optional)
  final TextEditingController _cNeck = TextEditingController();
  final TextEditingController _cShoulder = TextEditingController();
  final TextEditingController _cChest = TextEditingController();
  final TextEditingController _cWaist = TextEditingController();
  final TextEditingController _cHip = TextEditingController();
  final TextEditingController _cArmLength = TextEditingController();
  final TextEditingController _cBicep = TextEditingController();
  final TextEditingController _cForearm = TextEditingController();
  final TextEditingController _cWrist = TextEditingController();
  final TextEditingController _cThigh = TextEditingController();
  final TextEditingController _cCalf = TextEditingController();
  final TextEditingController _cInsideLeg = TextEditingController();

  // Seller for custom (unstitched) products: only suit info.
  final TextEditingController _suitColorController = TextEditingController();
  final TextEditingController _suitLengthMetersController = TextEditingController();
  final TextEditingController _suitFabricController = TextEditingController();

  @override
  void dispose() {
    _productNameController.dispose();
    _productPriceController.dispose();
    _productDiscountController.dispose();
    _productStockController.dispose();
    _productProfitController.dispose();
    _imageUrlController.dispose();
    _modelPathController.dispose();
    _categoryController.dispose();
    _cNeck.dispose();
    _cShoulder.dispose();
    _cChest.dispose();
    _cWaist.dispose();
    _cHip.dispose();
    _cArmLength.dispose();
    _cBicep.dispose();
    _cForearm.dispose();
    _cWrist.dispose();
    _cThigh.dispose();
    _cCalf.dispose();
    _cInsideLeg.dispose();
    _suitColorController.dispose();
    _suitLengthMetersController.dispose();
    _suitFabricController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }

  Future<void> _loadSellerProfile() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    final profile = await backend.getUserProfile(uid);
    setState(() {
      _sellerProfile = profile;
    });
  }

  void _putDetail(Map<String, dynamic> m, String key, TextEditingController c) {
    final t = c.text.trim();
    if (t.isNotEmpty) m[key] = t;
  }

  Map<String, dynamic> _buildUnifiedProductDetails() {
    final m = <String, dynamic>{};
    _putDetail(m, 'suitColor', _suitColorController);
    _putDetail(m, 'suitLengthMeters', _suitLengthMetersController);
    _putDetail(m, 'suitFabric', _suitFabricController);
    _putDetail(m, 'imageUrl', _imageUrlController);
    _putDetail(m, 'modelPath', _modelPathController);
    _putDetail(m, 'category', _categoryController);

    final chart = <String, dynamic>{};
    _putDetail(chart, 'Neck', _cNeck);
    _putDetail(chart, 'Shoulder', _cShoulder);
    _putDetail(chart, 'Chest', _cChest);
    _putDetail(chart, 'Waist', _cWaist);
    _putDetail(chart, 'Hip', _cHip);
    _putDetail(chart, 'Arm Length', _cArmLength);
    _putDetail(chart, 'Bicep', _cBicep);
    _putDetail(chart, 'Forearm', _cForearm);
    _putDetail(chart, 'Wrist', _cWrist);
    _putDetail(chart, 'Thigh', _cThigh);
    _putDetail(chart, 'Calf', _cCalf);
    _putDetail(chart, 'Inside Leg', _cInsideLeg);
    if (chart.isNotEmpty) m['clothSizeChart'] = chart;

    return m;
  }

  Future<void> _saveProduct() async {
    final seller = _sellerProfile ?? await backend.getUserProfile(AppBackend.instance.currentUid);
    final name = _productNameController.text.trim();
    final price = double.tryParse(_productPriceController.text.trim()) ?? -1;
    final discountPercent =
        double.tryParse(_productDiscountController.text.trim()) ?? 0.0;
    final stockQty = int.tryParse(_productStockController.text.trim()) ?? -1;
    final profitPerUnit = double.tryParse(_productProfitController.text.trim()) ?? -1;

    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid product name and price')),
      );
      return;
    }

    if (discountPercent < 0 || discountPercent > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount must be between 0 and 100')),
      );
      return;
    }

    if (stockQty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid initial stock quantity (0 or more)')),
      );
      return;
    }

    if (profitPerUnit < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profit must be 0 or greater (PKR per unit)')),
      );
      return;
    }

    final details = _buildUnifiedProductDetails();
    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add image URL, 3D model path, category, suit/fabric, or a body chart field'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await backend.addProduct(
        sellerId: seller.uid,
        sellerName: seller.shopName.isNotEmpty ? seller.shopName : seller.name,
        sellerAddress: seller.address,
        name: name,
        price: price,
        discountPercent: discountPercent,
        details: details,
        stockQuantity: stockQty,
        profitPerUnit: profitPerUnit,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully')),
      );

      _productNameController.clear();
      _productPriceController.clear();
      _productDiscountController.clear();
      _productStockController.text = '1';
      _productProfitController.text = '0';
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerUid = AppBackend.instance.currentUid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _sellerProfile == null ? 'Seller: Products' : 'Hi, ${_sellerProfile!.name}',
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Product',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _productPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (PKR)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _productDiscountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Discount %',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _productStockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Initial stock quantity',
                  hintText: 'Units available to sell',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _productProfitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Profit (PKR per unit sold)',
                  helperText: 'For your dashboard only — not shown to buyers',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Marketplace display (3D / image)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Product image URL (shown in marketplace)',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _modelPathController,
                decoration: const InputDecoration(
                  labelText: '3D model path (web), optional',
                  hintText: 'models/product1/product1.glb',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (e.g. Shalwar Kameez)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              _buildAllSellerDetailFields(),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: _isSaving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Add Product'),
                ),
              ),

              const SizedBox(height: 28),
              const Text(
                'Your Products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              StreamBuilder<List<ProductModel>>(
                stream: backend.streamProductsForSeller(sellerUid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  final mine = snapshot.data ?? [];
                  if (mine.isEmpty) return const Text('No products added yet.');

                  return ListView.builder(
                    itemCount: mine.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final p = mine[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.name),
                        subtitle: Text(
                          p.discountPercent > 0 ? 'Discount: ${p.discountPercent}%' : 'Product listing',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('PKR ${p.price}'),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Delete product',
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete product?'),
                                    content: Text('This will remove "${p.name}" from users.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed != true) return;
                                await backend.deleteProduct(p.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Product deleted')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllSellerDetailFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Suit / fabric', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _field(_suitColorController, 'Suit Color'),
        _field(_suitLengthMetersController, 'Suit Length (meters)'),
        _field(_suitFabricController, 'Suit Fabric'),
        const SizedBox(height: 16),
        const Text('Body chart (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _field(_cNeck, 'Neck'),
        _field(_cShoulder, 'Shoulder'),
        _field(_cChest, 'Chest'),
        _field(_cWaist, 'Waist'),
        _field(_cHip, 'Hip'),
        _field(_cArmLength, 'Arm Length'),
        _field(_cBicep, 'Bicep'),
        _field(_cForearm, 'Forearm'),
        _field(_cWrist, 'Wrist'),
        _field(_cThigh, 'Thigh'),
        _field(_cCalf, 'Calf'),
        _field(_cInsideLeg, 'Inside Leg'),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
