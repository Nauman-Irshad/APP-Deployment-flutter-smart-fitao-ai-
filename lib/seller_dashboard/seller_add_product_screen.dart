import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../Order-Tracking-System/services/app_backend.dart';
import '../services/marketplace_badge_service.dart';
import 'seller_3d_upload_service.dart';

/// Add product — same fields as React dashboard (`SellerAddProduct` / `sellerProducts.js`).
/// Saves to Firestore `products` → appears on user 3D landing when `showOnLanding` is true.
class SellerAddProductScreen extends StatefulWidget {
  const SellerAddProductScreen({super.key});

  @override
  State<SellerAddProductScreen> createState() => _SellerAddProductScreenState();
}

class _SellerAddProductScreenState extends State<SellerAddProductScreen> {
  static const _green = Color(0xFF059669);

  final _backend = AppBackend.instance;
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _discount = TextEditingController(text: '0');
  final _stock = TextEditingController(text: '10');
  final _profit = TextEditingController(text: '0');
  final _colorName = TextEditingController();
  final _imageUrl = TextEditingController();
  final _modelUrl = TextEditingController();

  String _category = 'Kurta Shalwar';
  String _section = 'Kurta Shalwar';
  bool _showOnLanding = true;
  bool _saving = false;
  String? _pickedImageName;
  List<PlatformFile> _picked3dFiles = [];
  String? _uploadStatus;

  static const _categories = [
    'Kurta Shalwar',
    'Shalwar Kameez',
    'Fabric',
  ];

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _discount.dispose();
    _stock.dispose();
    _profit.dispose();
    _colorName.dispose();
    _imageUrl.dispose();
    _modelUrl.dispose();
    super.dispose();
  }

  Future<void> _pickGlbFiles() async {
    try {
      final files = await Seller3dUploadService.pickModelFiles();
      if (!mounted) return;
      if (files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No .glb selected. In the dialog choose "All files" or pick your .glb directly.',
            ),
          ),
        );
        return;
      }
      setState(() {
        _picked3dFiles = files;
        _uploadStatus = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected ${files.length} file(s) for 3D upload')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file picker: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickGlbFolder() async {
    try {
      final files = await Seller3dUploadService.pickModelFolder();
      if (!mounted) return;
      if (files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No .glb in folder. Select the folder that contains model.glb (or use Pick .glb files).',
            ),
          ),
        );
        return;
      }
      setState(() {
        _picked3dFiles = files;
        _uploadStatus = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb
                ? 'Loaded ${files.length} file(s) from folder'
                : 'Loaded ${files.length} file(s) from folder',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open folder: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _pickedImageName = picked.name);
    if (_imageUrl.text.trim().isEmpty && picked.path.isNotEmpty) {
      _imageUrl.text = picked.path;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Image selected: ${picked.name}. Paste a public image URL above for the 3D shop (recommended).',
        ),
      ),
    );
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in as seller first')),
      );
      return;
    }

    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim()) ?? -1;
    final discount = double.tryParse(_discount.text.trim()) ?? 0;
    final stock = int.tryParse(_stock.text.trim()) ?? -1;
    final profit = double.tryParse(_profit.text.trim()) ?? 0;
    var imageUrl = _imageUrl.text.trim();
    var modelPath = _modelUrl.text.trim();

    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter product name and price (PKR)')),
      );
      return;
    }
    if (stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid stock quantity')),
      );
      return;
    }
    if (imageUrl.isEmpty && modelPath.isEmpty && _picked3dFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pick a .glb file (or folder) above, or paste image / model URLs',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _uploadStatus = null;
    });
    try {
      if (_picked3dFiles.isNotEmpty) {
        setState(() => _uploadStatus = 'Uploading 3D model…');
        final uploaded = await Seller3dUploadService.uploadModelFiles(
          files: _picked3dFiles,
          sellerId: uid,
          onProgress: (m) {
            if (mounted) setState(() => _uploadStatus = m);
          },
        );
        if (uploaded != null) {
          modelPath = uploaded.modelUrl;
          _modelUrl.text = modelPath;
          if (imageUrl.isEmpty && uploaded.imageUrl != null) {
            imageUrl = uploaded.imageUrl!;
            _imageUrl.text = imageUrl;
          }
        }
      }

      if (imageUrl.isEmpty && modelPath.isEmpty) {
        throw StateError('3D upload did not return a model URL');
      }

      final seller = await _backend.getUserProfile(uid);
      final color = _colorName.text.trim();
      setState(() => _uploadStatus = 'Saving to Firestore…');
      final productId = await _backend.addProduct(
        sellerId: seller.uid,
        sellerName: seller.shopName.isNotEmpty ? seller.shopName : seller.name,
        sellerAddress: seller.address,
        name: name,
        price: price,
        discountPercent: discount,
        stockQuantity: stock,
        profitPerUnit: profit,
        category: _category,
        section: _section,
        colorName: color,
        imageUrl: imageUrl,
        modelPath: modelPath,
        showOnLanding: _showOnLanding,
      );

      if (modelPath.isNotEmpty) {
        try {
          await Seller3dUploadService.saveProductToLocalCatalog({
            'id': productId,
            'productKey': productId,
            'name': name,
            'price': price,
            'category': _category,
            'section': _section,
            'colorName': color,
            'imageUrl': imageUrl,
            'modelPath': modelPath,
            'modelDirectUrl': modelPath,
            'sellerId': seller.uid,
            'sellerName':
                seller.shopName.isNotEmpty ? seller.shopName : seller.name,
            'showOnLanding': _showOnLanding,
            'status': 'Active',
          });
        } catch (_) {
          // Firestore is primary; local JSON is optional for website dev
        }
      }

      await MarketplaceBadgeService.instance.bumpNewProduct();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added to 3D marketplace — customers see a new item notification'),
          backgroundColor: _green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload, color: _green),
            label: Text(
              _saving ? 'Saving…' : 'Upload',
              style: const TextStyle(
                color: _green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _heroUploadCard(),
            const SizedBox(height: 16),
            _sectionTitle('Product details'),
            _field(_name, 'Product name', Icons.checkroom),
            _field(_price, 'Price (PKR)', Icons.payments_outlined,
                keyboard: TextInputType.number),
            _field(_discount, 'Discount %', Icons.percent,
                keyboard: TextInputType.number),
            _field(_stock, 'Stock quantity', Icons.inventory_2_outlined,
                keyboard: TextInputType.number),
            _field(_profit, 'Your profit per unit (PKR)', Icons.trending_up,
                keyboard: TextInputType.number,
                helper: 'Shown on seller dashboard only'),
            const SizedBox(height: 12),
            _sectionTitle('Category & color'),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: _inputDecoration('Category (3D landing section)'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _category = v;
                  _section = v;
                });
              },
            ),
            const SizedBox(height: 10),
            _field(_colorName, 'Color name (e.g. Black)', Icons.palette_outlined),
            const SizedBox(height: 16),
            _sectionTitle('3D marketplace display'),
            SwitchListTile(
              value: _showOnLanding,
              activeThumbColor: _green,
              title: const Text(
                'Show on user 3D landing page',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'When on, customers see this product in SmartFitao 3D shop',
              ),
              onChanged: (v) => setState(() => _showOnLanding = v),
            ),
            if (_picked3dFiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: _green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${_picked3dFiles.length} 3D file(s) ready — URLs below fill automatically on Upload.',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            _field(
              _imageUrl,
              'Product image URL (optional)',
              Icons.image_outlined,
              helper: 'Auto-filled after 3D upload, or paste https:// thumbnail',
            ),
            _field(
              _modelUrl,
              '3D model URL (optional)',
              Icons.view_in_ar,
              helper: 'Auto-filled after you pick .glb above — manual URL not required',
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  _saving ? 'Uploading to 3D shop…' : 'Upload to 3D landing page',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroUploadCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.view_in_ar, size: 40, color: _green),
          ),
          const SizedBox(height: 12),
          const Text(
            'Upload Product',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Same flow as seller dashboard — product appears on the user 3D marketplace and orders show in tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          if (_pickedImageName != null) ...[
            const SizedBox(height: 8),
            Text('Photo: $_pickedImageName', style: const TextStyle(fontSize: 12)),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Pick product photo'),
          ),
          const SizedBox(height: 10),
          const Text(
            '3D model (.glb) — use these buttons (not the URL boxes below)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            kIsWeb
                ? 'Edge: "Pick folder" opens your GLB folder. Or "Pick .glb files" → bottom-right choose All files (*.*).'
                : 'Select your .glb file or the whole model folder.',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _pickGlbFiles,
                  icon: const Icon(Icons.insert_drive_file_outlined),
                  label: const Text('Pick .glb files'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _pickGlbFolder,
                  icon: const Icon(Icons.folder_open),
                  label: Text(kIsWeb ? 'Pick all in folder' : 'Pick folder'),
                ),
              ),
            ],
          ),
          if (_picked3dFiles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_picked3dFiles.length} file(s): ${_picked3dFiles.take(4).map((f) => f.name.split('/').last).join(', ')}${_picked3dFiles.length > 4 ? '…' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ),
          ],
          if (_uploadStatus != null) ...[
            const SizedBox(height: 6),
            Text(_uploadStatus!, style: const TextStyle(fontSize: 12, color: _green)),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        t,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        decoration: _inputDecoration(label, icon: icon, helper: helper),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon, String? helper}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: icon != null ? Icon(icon, color: _green, size: 22) : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
