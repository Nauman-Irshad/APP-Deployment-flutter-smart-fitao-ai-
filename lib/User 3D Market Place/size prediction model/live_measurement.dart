import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Order-Tracking-System/services/app_backend.dart';
import '../../../Order-Tracking-System/tracking.dart' show OrderType;
import 'cloth_measurement_models.dart';
import 'cloth_measurement_wizard_panel.dart';
import 'cloth_studio_bridge.dart';
import 'studio_opener.dart';
import '../../../2d_try_on_app/try_on_screen.dart';
import '../../../2d_try_on_app/try_on_find_tailor_screen.dart';
import '../../../2d_try_on_app/try_on_order_session.dart';
import '../../../payments/demo_order_placement.dart';
import '../../../payments/stripe_payment_service.dart';
import '../../../payments/stripe_pending_checkout.dart';
import '../../../services/customer_fitting_store.dart';
import '../../../services/tailor_chat_service.dart';
import '../../../config/demo_accounts.dart';

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
  String? _capturedBodyImageUrl;
  int _capturedLandmarkCount = 0;
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
  bool _payingStripe = false;

  Future<List<AppUserProfile>> _loadTailorsOnce() {
    return _tailorsFuture ??= AppBackend.instance.fetchAvailableTailors();
  }

  final Map<String, TextEditingController> _measurementControllers = {};
  final TextEditingController _chatController = TextEditingController();

  String? get _activeChatId {
    final tailor = _selectedTailorProfile;
    final user = FirebaseAuth.instance.currentUser;
    if (tailor == null || user == null) return null;
    return TailorChatService.chatId(
      tailorId: tailor.uid,
      customerId: user.uid,
    );
  }

  Future<String> _customerDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return DemoAccounts.customerName;
    try {
      final p = await AppBackend.instance.getUserProfile(user.uid);
      if (p.name.trim().isNotEmpty) return p.name.trim();
    } catch (_) {}
    return user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : DemoAccounts.customerName;
  }

  @override
  void initState() {
    super.initState();
    CustomerFittingStore.saveSelectedProduct(widget.product);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillShippingAddress();
    });

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
      case 'input':
        return 0;
      case 'tryon':
      case 'measurements':
        return 1;
      case 'select_tailor':
        return 2;
      case 'chat':
        return 3;
      case 'checkout':
      case 'order_review':
        return 4;
      default:
        return 0;
    }
  }

  Widget _buildProgressSteps() {
    final stepLabels = ['Details', '2D Try-on', 'Tailor', 'Chat', 'Order'];
    final currentIndex = _getStepIndex();

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
          final isActive = index == currentIndex;
          final isCompleted = index < currentIndex;

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

  /// After AI Cloth wizard step 3 — fill profile + measurement grid from Flask `/predict` (values in cm).
  void _applyClothWizardToControllers(
    ClothWizardStep1Data step1,
    Map<String, double> mergedCm,
  ) {
    _ageController.text = step1.age;
    _heightController.text = step1.heightCm.toStringAsFixed(1);
    _weightController.text = step1.weightKg.toStringAsFixed(1);

    String inchQuote(double cm) {
      final inches = clothCmToInches(cm);
      final rounded = (inches * 10).round() / 10;
      return '$rounded"';
    }

    void mapCm(String measurementKey, String apiField) {
      final cm = mergedCm[apiField];
      if (cm != null &&
          !cm.isNaN &&
          _measurementControllers.containsKey(measurementKey)) {
        _measurementControllers[measurementKey]!.text = inchQuote(cm);
      }
    }

    mapCm('Chest', 'chest');
    mapCm('Waist', 'waist');
    mapCm('Hip', 'hip');
    mapCm('Shoulder', 'shoulder');
    mapCm('Collar', 'neck');
    mapCm('Sleeves', 'arm');
    mapCm('Kameez Length', 'kameezLength');
  }

  Map<String, double> _measurementsCmForStudio() {
    double? parseInches(String raw) {
      final s = raw.replaceAll('"', '').trim();
      final v = double.tryParse(s);
      return v != null ? clothInchesToCm(v) : null;
    }

    final out = <String, double>{};
    void map(String label, String apiField) {
      final c = _measurementControllers[label];
      if (c == null) return;
      final cm = parseInches(c.text);
      if (cm != null && !cm.isNaN) out[apiField] = cm;
    }

    map('Chest', 'chest');
    map('Waist', 'waist');
    map('Hip', 'hip');
    map('Shoulder', 'shoulder');
    map('Collar', 'neck');
    map('Sleeves', 'arm');
    return out;
  }

  Future<void> _open3dStudio() async {
    await StudioOpener.openFromMeasurements(
      context,
      measurementsCm: _measurementsCmForStudio(),
      fitPreference: 'Regular',
    );
  }

  Future<void> _persistMeasurementsForTryOn(
    Map<String, double> mergedCm,
    String fitPreference,
  ) async {
    TryOnOrderSession.instance.applyMeasurements(mergedCm);
    CustomerFittingStore.webPersistMeasurementsJson(jsonEncode(mergedCm));
    final payload = clothBuildStoredFitPayload(mergedCm, fitPreference);
    final fitJson = jsonEncode(payload);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(clothStorageKeyLastFit, fitJson);
    CustomerFittingStore.webPersistLastFitJson(fitJson);
    await CustomerFittingStore.applySavedSizeToSession();
  }

  Future<void> _continueToTryOn(
    ClothWizardStep1Data step1,
    Map<String, double> mergedCm,
    ClothWizardBodyPrefs prefs,
  ) async {
    _applyClothWizardToControllers(step1, mergedCm);
    await _persistMeasurementsForTryOn(mergedCm, prefs.fitPreference);
    if (!mounted) return;
    setState(() => _step = 'tryon');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open2dTryOnScreen();
    });
  }

  void _open2dTryOnScreen() {
    TryOn2dScreen.open(
      context,
      personImageUrl: _capturedBodyImageUrl,
      landmarkCount: _capturedLandmarkCount,
    );
  }

  void _openFindTailor() {
    TryOnFindTailorScreen.open(context);
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
    return ClothMeasurementWizardPanel(
      onContinueToTryOn: (step1, mergedCm, prefs) {
        unawaited(_continueToTryOn(step1, mergedCm, prefs));
      },
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _open3dStudio,
              icon: const Icon(Icons.view_in_ar_outlined),
              label: const Text('Open 3D Studio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 'input'), child: Text('Back'))),
              SizedBox(width: 12),
              Expanded(child: _buildContinueButton('2D Try-on', _open2dTryOnScreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTryOnStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TryOn2dPanel(
        personImageUrl: _capturedBodyImageUrl,
        landmarkCount: _capturedLandmarkCount,
        onBack: () => setState(() => _step = 'input'),
        onContinue: _openFindTailor,
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
                          onPressed: () {
                            setState(() {
                              _selectedTailorProfile = t;
                              _step = 'checkout';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF059669),
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Checkout'),
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
            child: _activeChatId == null
                ? const Center(
                    child: Text(
                      'Select a tailor to start chatting.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : StreamBuilder<List<TailorChatMessage>>(
                    stream: TailorChatService.watchMessages(_activeChatId!),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final messages = snap.data ?? [];
                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'Message your tailor about measurements or fabric.\nThey will see it in Messages.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg.sender == 'customer';
                          final text = msg.type == 'product' && msg.productTitle != null
                              ? msg.productTitle!
                              : msg.text;
                          return _buildChatMessage(
                            text,
                            isMe,
                            type: msg.type,
                          );
                        },
                      );
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
          child: OutlinedButton.icon(
            onPressed: (_placingOrder || _payingStripe) ? null : _placeDemoOrder,
            icon: _placingOrder
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_circle_outline),
            label: const Text(
              'Order Place Demo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFb45309),
              side: const BorderSide(color: Color(0xFFd97706), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_placingOrder || _payingStripe) ? null : _payWithStripe,
            icon: _payingStripe
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.lock),
            label: const Text(
              'Pay with Stripe',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: (_placingOrder || _payingStripe) ? null : () => setState(() => _step = 'checkout'),
            child: const Text('Back', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _liveOrderDetails() {
    final measurements = <String, String>{};
    _measurementControllers.forEach((key, controller) {
      measurements[key] = controller.text;
    });
    return <String, dynamic>{
      'clothSizeChart': measurements,
      'flow': 'live_measurement',
      ...Map<String, dynamic>.from(
        (widget.product['details'] is Map)
            ? Map<String, dynamic>.from(widget.product['details'] as Map)
            : {},
      ),
    };
  }

  Future<void> _placeDemoOrder() async {
    if (_placingOrder) return;
    final tailor = _selectedTailorProfile;
    if (tailor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a tailor first')),
      );
      return;
    }

    final unitPrice = double.tryParse(widget.product['price'].toString()) ?? 0.0;
    const quantity = 1;
    final tailorStitchingTotal = tailor.stitchingRate * quantity;
    final tailorProfitTotal = tailor.tailorProfitPerUnit * quantity;

    setState(() => _placingOrder = true);
    try {
      await DemoOrderPlacement.placeAndGoHome(
        context: context,
        product: widget.product,
        orderType: OrderType.custom,
        details: _liveOrderDetails(),
        quantity: quantity,
        unitPrice: unitPrice,
        tailor: tailor,
        deliveryAddress: _reviewDeliveryAddress,
        tailorStitchingTotal: tailorStitchingTotal,
        precomputedTailorProfitTotal: tailorProfitTotal,
      );
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  Future<void> _payWithStripe() async {
    if (_payingStripe) return;
    final tailor = _selectedTailorProfile;
    if (tailor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a tailor first')),
      );
      return;
    }

    final productPrice = double.tryParse(widget.product['price'].toString()) ?? 0.0;
    const quantity = 1;
    final tailorStitchingTotal = tailor.stitchingRate * quantity;
    final totalPkr = (productPrice + tailorStitchingTotal).round();
    if (totalPkr < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order total must be greater than zero')),
      );
      return;
    }

    final productTitle = widget.product['title']?.toString() ?? 'Product';
    final tailorLabel =
        tailor.shopName.isNotEmpty ? tailor.shopName : tailor.name;

    setState(() => _payingStripe = true);
    try {
      await StripePaymentService.startCheckout(
        amountPkr: totalPkr,
        productName: productTitle,
        description:
            'Live measurement · $productTitle · Tailor $tailorLabel · PKR $totalPkr',
        pending: StripePendingCheckout(
          userId: FirebaseAuth.instance.currentUser?.uid ??
              'live_${DateTime.now().millisecondsSinceEpoch}',
          productId: widget.product['firebaseProductId']?.toString() ??
              widget.product['id']?.toString() ??
              'live_product',
          productTitle: '$productTitle + $tailorLabel',
          quantity: quantity,
          unitPrice: productPrice,
          totalPkr: totalPkr,
          category: 'LiveMeasurement+Tailor',
          productImage: widget.product['imageUrl']?.toString() ?? '',
          address: _reviewDeliveryAddress,
          reducedPrice: totalPkr.toDouble(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete payment on Stripe checkout (test card 4242…)'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _payingStripe = false);
    }
  }

  Future<void> _sendMessage({String? text, String? type}) async {
    final content = text ?? _chatController.text.trim();
    if (content.isEmpty) return;

    final tailor = _selectedTailorProfile;
    final user = FirebaseAuth.instance.currentUser;
    if (tailor == null || user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in and select a tailor to chat')),
        );
      }
      return;
    }

    _chatController.clear();
    final customerName = await _customerDisplayName();
    final chatId = TailorChatService.chatId(
      tailorId: tailor.uid,
      customerId: user.uid,
    );
    final tailorName =
        tailor.shopName.isNotEmpty ? tailor.shopName : tailor.name;
    final msgType = type ?? 'text';
    final productTitle = widget.product['title']?.toString();
    final priceRaw = widget.product['price'];
    final productPrice = priceRaw is num ? priceRaw.toInt() : int.tryParse('$priceRaw');

    try {
      await TailorChatService.sendCustomerMessage(
        chatId: chatId,
        tailorId: tailor.uid,
        customerId: user.uid,
        customerName: customerName,
        tailorName: tailorName,
        type: msgType,
        text: content,
        productTitle: msgType == 'product' ? productTitle : null,
        productPricePkr: msgType == 'product' ? productPrice : null,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send message: $e')),
        );
      }
    }
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
                    
                    _sendMessage(
                      text: widget.product['title']?.toString() ?? 'Shared product',
                      type: 'product',
                    );
                    
                    
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.straighten,
                  label: "Size Chart",
                  color: Color(0xFF0284c7),
                  onTap: () {
                    Navigator.pop(context);
                    _sendMessage(text: 'Shared size chart from live measurement', type: 'size_chart');
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
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width < 360 ? 10.0 : (MediaQuery.sizeOf(context).width < 480 ? 14.0 : 16.0),
          16,
          MediaQuery.sizeOf(context).width < 360 ? 10.0 : (MediaQuery.sizeOf(context).width < 480 ? 14.0 : 16.0),
          16,
        ),
        child: Column(
          children: [
            if (_step != 'chat') _buildProgressSteps(),
            if (_step != 'chat') SizedBox(height: 24),
            if (_step == 'input') _buildInputStep(),
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
