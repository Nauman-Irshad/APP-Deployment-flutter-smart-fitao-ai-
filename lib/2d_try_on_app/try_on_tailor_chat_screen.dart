import 'package:flutter/material.dart';

import '../Order-Tracking-System/services/app_backend.dart';
import '../services/customer_fitting_store.dart';
import '../services/tailor_chat_service.dart';
import 'try_on_final_cart_screen.dart';
import 'try_on_order_session.dart';
import 'try_on_theme.dart';

/// Customer ↔ tailor chat. Messages saved to Firestore for tailor app (no auto-reply).
class TryOnTailorChatScreen extends StatefulWidget {
  const TryOnTailorChatScreen({super.key, required this.tailor});

  final AppUserProfile tailor;

  @override
  State<TryOnTailorChatScreen> createState() => _TryOnTailorChatScreenState();
}

class _TryOnTailorChatScreenState extends State<TryOnTailorChatScreen> {
  final _session = TryOnOrderSession.instance;
  final _chatController = TextEditingController();
  String? _chatId;
  String? _customerId;
  String _customerName = 'Customer';
  bool _ready = false;
  Map<String, dynamic> _marketplaceProduct = {};

  @override
  void initState() {
    super.initState();
    _session.selectTailor(widget.tailor);
    _initChat();
  }

  Future<void> _initChat() async {
    await CustomerFittingStore.syncSessionFromLocal();
    _marketplaceProduct = await CustomerFittingStore.resolvedProductForChat();
    _customerId = await CustomerFittingStore.guestOrUserId();
    _customerName = await CustomerFittingStore.customerDisplayName();
    _chatId = TailorChatService.chatId(
      tailorId: widget.tailor.uid,
      customerId: _customerId!,
    );
    if (mounted) setState(() => _ready = true);
  }

  String get _savedProductLabel {
    final title = _marketplaceProduct['title']?.toString() ?? '';
    final color = _marketplaceProduct['colorName']?.toString() ?? '';
    if (title.isEmpty) return 'Open a kurta in 3D shop first';
    return color.isNotEmpty ? '$title · $color' : title;
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  String get _tailorLabel =>
      widget.tailor.shopName.isNotEmpty ? widget.tailor.shopName : widget.tailor.name;

  String get _tailorName => widget.tailor.name;

  Future<void> _reportChatError(Object e) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message not saved: $e'),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Future<void> _sendText() async {
    final t = _chatController.text.trim();
    if (t.isEmpty || _chatId == null || _customerId == null) return;
    _chatController.clear();
    try {
      await TailorChatService.sendCustomerMessage(
        chatId: _chatId!,
        tailorId: widget.tailor.uid,
        customerId: _customerId!,
        customerName: _customerName,
        tailorName: _tailorName,
        type: 'text',
        text: t,
      );
    } catch (e) {
      await _reportChatError(e);
    }
  }

  Future<void> _sendProductToTailor() async {
    if (_chatId == null || _customerId == null) return;
    final product = await CustomerFittingStore.resolvedProductForChat();
    final s = _session;
    final title = product['title']?.toString().trim() ?? '';
    if (title.isEmpty ||
        CustomerFittingStore.looksLikeTryOnFileName(title)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Open your kurta in the 3D shop first (e.g. Black kurta), then Live measurement.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    final color = product['colorName']?.toString() ?? s.marketplaceColorName;
    final price = (product['price'] as num?)?.toInt() ?? s.productPricePkr;
    final text = CustomerFittingStore.productLineForChat(product);
    try {
      await TailorChatService.sendCustomerMessage(
        chatId: _chatId!,
        tailorId: widget.tailor.uid,
        customerId: _customerId!,
        customerName: _customerName,
        tailorName: _tailorName,
        type: 'product',
        text: text,
        productTitle: color.isNotEmpty ? '$title · $color' : title,
        productColor: color,
        productPricePkr: price,
        productImagePath: product['imagePath']?.toString() ?? s.productImagePath,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product sent to tailor'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      await _reportChatError(e);
    }
  }

  Future<void> _sendSizeChartToTailor() async {
    if (_chatId == null || _customerId == null) return;
    final rows = <String, String>{
      'Brand size': _session.predictedSizeLabel,
      ..._session.measurementsInches,
    };
    if (rows.length <= 1) {
      rows['Chest'] = '45"';
      rows['Waist'] = '40"';
      rows['Kurta length'] = '42"';
      rows['Note'] = 'Saved from size prediction step';
    }
    try {
      await TailorChatService.sendCustomerMessage(
        chatId: _chatId!,
        tailorId: widget.tailor.uid,
        customerId: _customerId!,
        customerName: _customerName,
        tailorName: _tailorName,
        type: 'size_chart',
        text: 'Size chart — ${_session.predictedSizeLabel}',
        sizeRows: rows,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Size chart sent to tailor'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      await _reportChatError(e);
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Send to tailor', style: TryOnTheme.heading(size: 17)),
            const SizedBox(height: 8),
            Text(
              'Uses your 3D marketplace pick + saved size',
              style: TryOnTheme.body(size: 12, color: TryOnTheme.brownMuted),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachOption(
                  icon: Icons.checkroom,
                  label: 'Product',
                  color: const Color(0xFF059669),
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendProductToTailor();
                  },
                ),
                _attachOption(
                  icon: Icons.straighten,
                  label: 'Size chart',
                  color: const Color(0xFF0284c7),
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendSizeChartToTailor();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _attachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TryOnTheme.body(size: 13, weight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _chatId == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TryOnTheme.white,
      appBar: AppBar(
        backgroundColor: TryOnTheme.white,
        foregroundColor: TryOnTheme.brown,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tailorLabel, style: TryOnTheme.body(size: 16, weight: FontWeight.w700)),
            Text(
              'PKR ${widget.tailor.stitchingRate.toStringAsFixed(0)} / stitch',
              style: TryOnTheme.body(size: 12, color: const Color(0xFF059669)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => TryOnFinalCartScreen.open(context),
            child: Text(
              'Final cart',
              style: TryOnTheme.body(size: 13, weight: FontWeight.w700,
                  color: const Color(0xFF059669)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFf0fdf4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
            ),
            child: Text(
              _session.sizeSummary,
              style: TryOnTheme.body(size: 12, weight: FontWeight.w600),
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TryOnTheme.gray,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TryOnTheme.brown.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.checkroom, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your 3D product',
                        style: TryOnTheme.body(
                          size: 10,
                          weight: FontWeight.w700,
                          color: TryOnTheme.brownMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _savedProductLabel,
                        style: TryOnTheme.body(size: 14, weight: FontWeight.w700),
                      ),
                      if (_marketplaceProduct['price'] != null)
                        Text(
                          'PKR ${_marketplaceProduct['price']} · Size ${_session.predictedSizeLabel}',
                          style: TryOnTheme.body(
                            size: 12,
                            weight: FontWeight.w600,
                            color: const Color(0xFF059669),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: TailorChatService.watchMessagesRaw(_chatId!),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF059669)),
                  );
                }
                final messages = snap.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Tap + to send your Black kurta (from 3D shop) and saved size to the tailor.',
                        textAlign: TextAlign.center,
                        style: TryOnTheme.body(size: 14, color: TryOnTheme.brownMuted),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    return _MessageBubble(
                      message: m,
                      isMe: m['isCustomer'] == true,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: _showAttachmentOptions,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Color(0xFF059669)),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      filled: true,
                      fillColor: TryOnTheme.gray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF059669),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => TryOnFinalCartScreen.open(context),
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text(
                'Final cart · ${_session.totalPkr} PKR total',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TryOnTheme.brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final Map<String, dynamic> message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final type = message['type'] as String? ?? 'text';
    final text = message['text'] as String? ?? '';
    final sizeRowsRaw = message['sizeRows'];
    Map<String, String>? sizeRows;
    if (sizeRowsRaw is Map) {
      sizeRows = sizeRowsRaw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF059669) : TryOnTheme.gray,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type == 'product') ...[
              _label('PRODUCT', isMe),
              const SizedBox(height: 6),
              Text(
                message['productTitle']?.toString().isNotEmpty == true
                    ? message['productTitle'].toString()
                    : text,
                style: TryOnTheme.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: isMe ? TryOnTheme.white : Colors.black87,
                ),
              ),
              if (message['productColor'] != null &&
                  '${message['productColor']}'.isNotEmpty)
                Text(
                  'Color: ${message['productColor']}',
                  style: TryOnTheme.body(
                    size: 12,
                    color: isMe ? Colors.white70 : TryOnTheme.brownMuted,
                  ),
                ),
              if (message['productPricePkr'] != null)
                Text(
                  'PKR ${message['productPricePkr']}',
                  style: TryOnTheme.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: isMe ? Colors.white70 : const Color(0xFF059669),
                  ),
                ),
            ] else if (type == 'size_chart') ...[
              _label('SIZE CHART', isMe),
              const SizedBox(height: 6),
              Text(
                text,
                style: TryOnTheme.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: isMe ? TryOnTheme.white : Colors.black87,
                ),
              ),
              if (sizeRows != null)
                ...sizeRows.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key,
                            style: TryOnTheme.body(
                                size: 12,
                                color: isMe ? Colors.white70 : Colors.black54)),
                        Text(e.value,
                            style: TryOnTheme.body(
                                size: 12,
                                weight: FontWeight.w600,
                                color: isMe ? TryOnTheme.white : Colors.black87)),
                      ],
                    ),
                  ),
                ),
            ] else
              Text(
                text,
                style: TryOnTheme.body(
                  size: 13,
                  color: isMe ? TryOnTheme.white : Colors.black87,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t, bool isMe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        t,
        style: TryOnTheme.body(
          size: 10,
          weight: FontWeight.w700,
          color: isMe ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }
}
