import 'package:flutter/material.dart';

import '../services/customer_fitting_store.dart';
import '../services/seller_chat_service.dart';
import '../services/tailor_chat_service.dart';

/// Live Firestore chat — customer talking to one tailor or one seller.
class CustomerPeerChatScreen extends StatefulWidget {
  const CustomerPeerChatScreen({
    super.key,
    required this.peerType,
    required this.peerId,
    required this.peerName,
    this.peerShopName = '',
  });

  final String peerType; // tailor | seller
  final String peerId;
  final String peerName;
  final String peerShopName;

  @override
  State<CustomerPeerChatScreen> createState() => _CustomerPeerChatScreenState();
}

class _CustomerPeerChatScreenState extends State<CustomerPeerChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  String? _chatId;
  String? _customerId;
  String _customerName = 'Ali';
  bool _ready = false;

  bool get _isTailor => widget.peerType == 'tailor';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _customerId = await CustomerFittingStore.guestOrUserId();
    _customerName = await CustomerFittingStore.customerDisplayName();
    _chatId = _isTailor
        ? TailorChatService.chatId(
            tailorId: widget.peerId,
            customerId: _customerId!,
          )
        : SellerChatService.chatId(
            sellerId: widget.peerId,
            customerId: _customerId!,
          );
    if (_isTailor) {
      await TailorChatService.ensureChat(
        chatId: _chatId!,
        tailorId: widget.peerId,
        customerId: _customerId!,
        customerName: _customerName,
        tailorName: widget.peerName,
      );
    } else {
      await SellerChatService.ensureChat(
        chatId: _chatId!,
        sellerId: widget.peerId,
        customerId: _customerId!,
        customerName: _customerName,
        sellerName: widget.peerShopName.isNotEmpty
            ? widget.peerShopName
            : widget.peerName,
      );
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _controller.text.trim();
    if (t.isEmpty || _chatId == null || _customerId == null) return;
    _controller.clear();
    try {
      if (_isTailor) {
        await TailorChatService.sendCustomerMessage(
          chatId: _chatId!,
          tailorId: widget.peerId,
          customerId: _customerId!,
          customerName: _customerName,
          tailorName: widget.peerName,
          type: 'text',
          text: t,
        );
      } else {
        await SellerChatService.sendCustomerMessage(
          chatId: _chatId!,
          sellerId: widget.peerId,
          customerId: _customerId!,
          customerName: _customerName,
          sellerName: widget.peerShopName.isNotEmpty
              ? widget.peerShopName
              : widget.peerName,
          type: 'text',
          text: t,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.peerShopName.isNotEmpty
        ? widget.peerShopName
        : widget.peerName;
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              _isTailor ? 'Tailor · You: $_customerName' : 'Seller',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      body: !_ready || _chatId == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _isTailor
                        ? TailorChatService.watchMessagesRaw(_chatId!)
                        : SellerChatService.watchMessages(_chatId!).map(
                            (list) => list
                                .map(
                                  (m) => <String, dynamic>{
                                    'id': m.id,
                                    'text': m.text,
                                    'type': m.type,
                                    'isCustomer': m.isCustomer,
                                  },
                                )
                                .toList(),
                          ),
                    builder: (context, snap) {
                      final messages = snap.data ?? [];
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scroll.hasClients && messages.isNotEmpty) {
                          _scroll.jumpTo(_scroll.position.maxScrollExtent);
                        }
                      });
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'Say hello — ${_isTailor ? 'tailor' : 'seller'} replies from their dashboard.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[i];
                          final isMe = m['isCustomer'] == true;
                          return Align(
                            alignment:
                                isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFF059669)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                m['text']?.toString() ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Material(
                  color: Colors.white,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: 'Message as $_customerName…',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF059669)),
                            onPressed: _send,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
