import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../Order-Tracking-System/services/app_backend.dart';
import '../../../Order-Tracking-System/tracking.dart' show OrderType;
import '../3d_marketplace.dart';

class LiveMeasurementScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onBack;

  const LiveMeasurementScreen({
    super.key,
    required this.product,
    required this.onBack,
  });

  @override
  _LiveMeasurementScreenState createState() => _LiveMeasurementScreenState();
}

class _LiveMeasurementScreenState extends State<LiveMeasurementScreen> {
  String _step = 'input';
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();


  final _addressController = TextEditingController();
  final _cardController = TextEditingController(text: '**** **** **** 4242');

  AppUserProfile? _selectedTailorProfile;
  Future<List<AppUserProfile>>? _tailorsFuture;

  /// Shipping address shown on the final review (typed field or profile fallback).
  String _reviewDeliveryAddress = '';
  bool _placingOrder = false;

  Future<List<AppUserProfile>> _loadTailorsOnce() {
    return _tailorsFuture ??= AppBackend.instance.fetchAvailableTailors();
  }

  final Map<String, TextEditingController> _measurementControllers = {};
  final TextEditingController _chatController = TextEditingController();
  
  List<Map<String, dynamic>> _chatMessages = [
    {'text': 'Hi! I saw your measurements. I can complete this in 4 days.', 'isMe': false, 'type': 'text'},
    {'text': 'The fee will be \$35.0. Is that okay?', 'isMe': false, 'type': 'text'},
    {'text': 'Yes, sounds perfect. Please use the measurements I shared.', 'isMe': true, 'type': 'text'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillShippingAddress());

    final defaultMeasurements = {
      'Kameez Length': '38"',
      'Shoulder': '18"',
      'Sleeves': '24"',
      'Collar': '16"',
      'Chest': '42"',
      'Waist': '40"',
      'Hip': '42"',
      'Daman': '22"',
      'Shalwar Length': '38"',
      'Paincha (Bottom)': '8"',
    };

    defaultMeasurements.forEach((key, value) {
      _measurementControllers[key] = TextEditingController(text: value);
    });
  }

  Future<void> _prefillShippingAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !mounted) return;
    try {
      final profile = await AppBackend.instance.getUserProfile(user.uid);
      if (!mounted) return;
      if (_addressController.text.trim().isEmpty) {
        setState(() => _addressController.text = profile.address);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _addressController.dispose();
    _cardController.dispose();
    _measurementControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  int _getStepIndex() {
    switch (_step) {
      case 'input': return 0;
      case 'camera': return 1;
      case 'measurements': return 2;
      case 'tryon': return 3;
      case 'select_tailor': return 4;
      case 'chat': return 5;
      case 'checkout':
      case 'order_review':
        return 6;
      default:
        return 0;
    }
  }

  Widget _buildProgressSteps() {
    final stepLabels = ['Details', 'Camera', 'Size', 'Try On', 'Tailor', 'Order'];
    final currentIndex = _getStepIndex();

    final visualIndex = currentIndex > 4 ? (currentIndex == 6 ? 5 : 4) : currentIndex;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(stepLabels.length, (index) {
          final isActive = index == visualIndex;
          final isCompleted = index < visualIndex;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive ? Color(0xFF059669) : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, color: Colors.white, size: 14)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey[500],
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                  ),
                ),
                if (index < stepLabels.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? Color(0xFF059669) : Colors.grey[200],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepHeader(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: Color(0xFFf0fdf4), shape: BoxShape.circle),
          child: Icon(icon, color: Color(0xFF059669), size: 28),
        ),
        SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildContinueButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF059669),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInputStep() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildStepHeader(Icons.person, 'Your Details', 'Enter information for AI measurement'),
          SizedBox(height: 32),
          _buildTextField('Age (years)', _ageController, Icons.calendar_today),
          SizedBox(height: 16),
          _buildTextField('Height (cm)', _heightController, Icons.height),
          SizedBox(height: 16),
          _buildTextField('Weight (kg)', _weightController, Icons.monitor_weight),
          SizedBox(height: 24),
          _buildContinueButton('Continue to Camera', () => setState(() => _step = 'camera')),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500, fontSize: 13)),
        SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(10)),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter your ${label.toLowerCase()}',
              prefixIcon: Icon(icon, color: Colors.grey[400], size: 18),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraStep() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildStepHeader(Icons.camera_alt, 'Landmark Detection', 'Position yourself in front of camera'),
          SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
              child: Center(child: Icon(Icons.person_outline, color: Colors.white24, size: 80)),
            ),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 'input'), child: Text('Back'))),
              SizedBox(width: 12),
              Expanded(child: _buildContinueButton('Capture', () => setState(() => _step = 'measurements'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsStep() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildStepHeader(Icons.straighten, 'Your Size', 'Check your AI-generated dimensions'),
          SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2,
            ),
            itemCount: _measurementControllers.length,
            itemBuilder: (context, index) {
              final entry = _measurementControllers.entries.toList()[index];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[100]!)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(entry.key, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    TextField(
                      controller: entry.value,
                      style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 14),
                      decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 'camera'), child: Text('Retake'))),
              SizedBox(width: 12),
              Expanded(child: _buildContinueButton('Visualize 3D', () => setState(() => _step = 'tryon'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTryOnStep() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildStepHeader(Icons.accessibility_new, 'Virtual Try-On', 'Visualizing your custom fit'),
          SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/1.webp', height: 350, fit: BoxFit.contain, errorBuilder: (c, e, s) => Container(height: 350, color: Colors.grey[100], child: Icon(Icons.image, color: Colors.grey))),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 'measurements'), child: Text('Edit Size'))),
              SizedBox(width: 12),
              Expanded(child: _buildContinueButton('Select Tailor', () => setState(() => _step = 'select_tailor'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectTailorStep() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: FutureBuilder<List<AppUserProfile>>(
        future: _loadTailorsOnce(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Could not load tailors: ${snap.error}'),
                SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => setState(() => _step = 'tryon'),
                  child: Text('Back'),
                ),
              ],
            );
          }
          final tailors = snap.data ?? [];
          if (tailors.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStepHeader(Icons.cut, 'Find a Tailor', 'No tailors are available yet'),
                SizedBox(height: 16),
                Text(
                  'Tailors must sign in and use Add rate on the tailor dashboard (rate PKR & available).',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => setState(() => _step = 'tryon'),
                  style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 44)),
                  child: Text('Back'),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(Icons.cut, 'Find a Tailor', 'Registered tailors with stitching rate (PKR)'),
              SizedBox(height: 24),
              ...tailors.map((t) {
                final label = t.shopName.isNotEmpty ? t.shopName : t.name;
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[100]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0xFFf0fdf4),
                            child: Icon(Icons.person, color: Color(0xFF059669)),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(
                                  '${t.name} · PKR ${t.stitchingRate.toStringAsFixed(0)} / unit',
                                  style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.chat_bubble_outline, color: Color(0xFF059669)),
                            onPressed: () {
                              setState(() {
                                _selectedTailorProfile = t;
                                _step = 'chat';
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            setState(() => _selectedTailorProfile = t);
                            await _placeCustomOrder();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF059669),
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Order'),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => setState(() => _step = 'tryon'),
                style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 44)),
                child: Text('Back'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatWithTailorStep() {
    return Container(
      height: 600,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [

          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[100]!), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(
              children: [
                IconButton(icon: Icon(Icons.arrow_back), onPressed: () => setState(() => _step = 'select_tailor')),
                CircleAvatar(radius: 16, backgroundColor: Color(0xFFf0fdf4), child: Icon(Icons.person, size: 20, color: Color(0xFF059669))),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedTailorProfile == null
                        ? 'Tailor'
                        : (_selectedTailorProfile!.shopName.isNotEmpty
                            ? _selectedTailorProfile!.shopName
                            : _selectedTailorProfile!.name),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _prefillShippingAddress();
                    if (mounted) setState(() => _step = 'checkout');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF059669), foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 16), textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  child: Text('Confirm'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index];
                return _buildChatMessage(msg['text'], msg['isMe'], type: msg['type'] ?? 'text');
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                    child: Icon(Icons.add, color: Color(0xFF059669)),
                  ),
                  onPressed: _showAttachmentOptions,
                ),
                Expanded(child: Container(padding: EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)), child: TextField(controller: _chatController, decoration: InputDecoration(hintText: 'Type a message...', border: InputBorder.none)))),
                SizedBox(width: 8),
                InkWell(
                  onTap: () => _sendMessage(),
                  child: CircleAvatar(backgroundColor: Color(0xFF059669), child: Icon(Icons.send, color: Colors.white, size: 18)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(String text, bool isMe, {String type = 'text'}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Color(0xFF059669) : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12), topRight: Radius.circular(12),
            bottomLeft: isMe ? Radius.circular(12) : Radius.circular(0),
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type == 'product')
              Container(padding: EdgeInsets.only(bottom: 6), child: Text("PRODUCT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isMe ? Colors.white70 : Colors.black54))),
            if (type == 'size_chart')
               Container(padding: EdgeInsets.only(bottom: 6), child: Row(children: [Icon(Icons.straighten, size: 14, color: isMe ? Colors.white : Colors.black54), SizedBox(width: 4), Text("SIZE CHART", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isMe ? Colors.white70 : Colors.black54))])),
            Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutStep() {
    final tailorFee = _selectedTailorProfile?.stitchingRate ?? 0.0;
    final productPrice = double.tryParse(widget.product['price'].toString()) ?? 0.0;
    final total = tailorFee + productPrice;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(Icons.shopping_bag, 'Order Summary', 'Check your custom order details'),
              SizedBox(height: 24),


              Text('Tailor Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Color(0xFFf0fdf4), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTailorProfile == null
                          ? 'Tailor fee'
                          : (_selectedTailorProfile!.shopName.isNotEmpty
                              ? _selectedTailorProfile!.shopName
                              : _selectedTailorProfile!.name),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'PKR ${tailorFee.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),


              Text('Product Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (widget.product['imageUrl'] != null && widget.product['imageUrl'].toString().isNotEmpty)
                          ? Image.network(
                              widget.product['imageUrl'].toString(),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: Colors.grey[200]),
                            )
                          : Image.network(
                              'https://via.placeholder.com/50',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: Colors.grey[200]),
                            ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.product['title']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Base: PKR ${productPrice.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('PKR ${productPrice.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              SizedBox(height: 24),
              Divider(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      'PKR ${total.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _addressController, decoration: InputDecoration(prefixIcon: Icon(Icons.location_on, size: 18), border: UnderlineInputBorder())),
              SizedBox(height: 20),
              Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _cardController, decoration: InputDecoration(prefixIcon: Icon(Icons.credit_card, size: 18), border: UnderlineInputBorder())),
              SizedBox(height: 24),
              _buildContinueButton('Checkout Now', _onProceedToOrderReview),
              SizedBox(height: 12),
              Center(child: TextButton(onPressed: () => setState(() => _step = 'chat'), child: Text('Back to Chat', style: TextStyle(color: Colors.grey))))
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onProceedToOrderReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to continue')),
        );
      }
      return;
    }
    if (_selectedTailorProfile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a tailor first')),
        );
      }
      return;
    }

    try {
      final profile = await AppBackend.instance.getUserProfile(user.uid);
      final typed = _addressController.text.trim();
      final delivery = typed.isNotEmpty ? typed : profile.address;
      if (delivery.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a shipping address')),
          );
        }
        return;
      }
      if (!mounted) return;
      setState(() {
        _reviewDeliveryAddress = delivery;
        _step = 'order_review';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load profile: $e')),
        );
      }
    }
  }

  Widget _buildOrderReviewStep() {
    final tailor = _selectedTailorProfile;
    final tailorFee = tailor?.stitchingRate ?? 0.0;
    final productPrice = double.tryParse(widget.product['price'].toString()) ?? 0.0;
    final total = tailorFee + productPrice;
    final tailorLabel = tailor == null
        ? '—'
        : (tailor.shopName.isNotEmpty ? tailor.shopName : tailor.name);
    final productTitle = widget.product['title']?.toString() ?? 'Product';

    Widget reviewRow(String label, String value, {bool emphasize = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: emphasize ? 16 : 14,
                  fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
                  color: emphasize ? const Color(0xFF059669) : Colors.grey[900],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(
                Icons.fact_check,
                'Order details',
                'Confirm everything below, then place your order',
              ),
              const SizedBox(height: 20),
              reviewRow('Product', productTitle),
              reviewRow('Tailor', tailorLabel),
              reviewRow('Tailoring fee', 'PKR ${tailorFee.toStringAsFixed(0)}'),
              reviewRow('Product price', 'PKR ${productPrice.toStringAsFixed(0)}'),
              const Divider(height: 24),
              reviewRow('Total', 'PKR ${total.toStringAsFixed(0)}', emphasize: true),
              const SizedBox(height: 8),
              reviewRow('Shipping address', _reviewDeliveryAddress),
              if (_cardController.text.trim().isNotEmpty)
                reviewRow('Payment note', _cardController.text.trim()),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _placingOrder ? null : _placeCustomOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _placingOrder
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _placingOrder ? null : () => setState(() => _step = 'checkout'),
            child: const Text('Back', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  void _sendMessage({String? text, String? type}) {
    final content = text ?? _chatController.text.trim();
    if (content.isEmpty) return;
    
    setState(() {
      _chatMessages.add({
        'text': content,
        'isMe': true,
        'type': type ?? 'text',
      });
    });
    
    _chatController.clear();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Share Item", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.inventory_2,
                  label: "Product",
                  color: Color(0xFF059669),
                  onTap: () {
                    Navigator.pop(context);
                    
                    _sendMessage(text: "Shared Product: Premium Suit", type: 'product');
                    
                    
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.straighten,
                  label: "Size Chart",
                  color: Color(0xFF0284c7),
                  onTap: () {
                    Navigator.pop(context);
                    _sendMessage(text: "Shared Size Chart: Custom Fit", type: 'size_chart');
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Future<void> _placeCustomOrder() async {
    if (_placingOrder) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to place a custom order')),
        );
      }
      return;
    }

    final tailor = _selectedTailorProfile;
    if (tailor == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a tailor first')),
        );
      }
      return;
    }

    final productId =
        widget.product['firebaseProductId']?.toString() ?? widget.product['id']?.toString() ?? '';
    final sellerId = widget.product['sellerId']?.toString() ?? '';
    if (productId.isEmpty || sellerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing product or seller — use marketplace items from a seller')),
        );
      }
      return;
    }

    if (widget.product['outOfStock'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This product is out of stock')),
        );
      }
      return;
    }

    final backend = AppBackend.instance;
    final profile = await backend.getUserProfile(user.uid);

    final productName = widget.product['title']?.toString() ?? 'Product';
    final unitPrice = double.tryParse(widget.product['price'].toString()) ?? 0.0;
    final tailorDisplayName =
        tailor.shopName.isNotEmpty ? '${tailor.shopName} (${tailor.name})' : tailor.name;
    const quantity = 1;
    final tailorStitchingTotal = tailor.stitchingRate * quantity;
    final tailorProfitTotal = tailor.tailorProfitPerUnit * quantity;

    final measurements = <String, String>{};
    _measurementControllers.forEach((key, controller) {
      measurements[key] = controller.text;
    });

    final details = <String, dynamic>{
      'clothSizeChart': measurements,
      'flow': 'live_measurement',
      ...Map<String, dynamic>.from(
        (widget.product['details'] is Map) ? Map<String, dynamic>.from(widget.product['details'] as Map) : {},
      ),
    };

    final typedAddr = _addressController.text.trim();
    final delivery = typedAddr.isNotEmpty ? typedAddr : profile.address;

    setState(() => _placingOrder = true);
    try {
      final orderId = await backend.createOrder(
        customerId: profile.uid,
        customerName: profile.name,
        productId: productId,
        productName: productName,
        totalAmount: unitPrice,
        quantity: quantity,
        type: OrderType.custom,
        details: details,
        sellerId: sellerId,
        sellerName: widget.product['sellerName']?.toString() ?? '',
        sellerAddress: widget.product['sellerAddress']?.toString() ?? '',
        tailorId: tailor.uid,
        tailorName: tailorDisplayName,
        tailorAddress: tailor.address,
        deliveryAddress: delivery,
        tailorStitchingTotal: tailorStitchingTotal,
        precomputedTailorProfitTotal: tailorProfitTotal,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed. ID: $orderId'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MarketPlace3D()),
        (route) => false,
      );
    } catch (e, st) {
      debugPrint('placeOrder: $e\n$st');
      if (mounted) {
        var msg = e is FirebaseException ? '${e.code}: ${e.message ?? e.toString()}' : e.toString();
        if (msg.contains('converted Future') || msg.contains('boxed error')) {
          msg =
              'Firestore error (often invalid data or security rules). Full: $msg';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $msg'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf9fafb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Color(0xFF059669)), onPressed: widget.onBack),
        title: Text('Custom Fitting', style: TextStyle(color: Color(0xFF059669), fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            if (_step != 'chat') _buildProgressSteps(),
            if (_step != 'chat') SizedBox(height: 24),
            if (_step == 'input') _buildInputStep(),
            if (_step == 'camera') _buildCameraStep(),
            if (_step == 'measurements') _buildMeasurementsStep(),
            if (_step == 'tryon') _buildTryOnStep(),
            if (_step == 'select_tailor') _buildSelectTailorStep(),
            if (_step == 'chat') _buildChatWithTailorStep(),
            if (_step == 'checkout') _buildCheckoutStep(),
            if (_step == 'order_review') _buildOrderReviewStep(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
