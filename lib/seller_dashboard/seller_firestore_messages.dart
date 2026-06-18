import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Order-Tracking-System/services/app_backend.dart';
import '../services/seller_chat_service.dart';

/// Seller inbox — WhatsApp-style list with unread badges.
class SellerFirestoreMessagesScreen extends StatelessWidget {
  const SellerFirestoreMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in as seller to see customer messages.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<SellerChatInboxItem>>(
        stream: SellerChatService.watchSellerInbox(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No customer chats yet.\nWhen a user messages your store from the 3D app, it appears here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return _InboxTile(item: item, sellerId: uid);
            },
          );
        },
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.item, required this.sellerId});

  final SellerChatInboxItem item;
  final String sellerId;

  @override
  Widget build(BuildContext context) {
    final preview = item.lastMessage.isNotEmpty ? item.lastMessage : 'Tap to open chat';
    final whatsAppLine =
        item.lastMessage.isNotEmpty ? '${item.customerName}: $preview' : item.customerName;
    final hasUnread = item.unreadForSeller > 0;

    return GestureDetector(
      onTap: () async {
        await SellerChatService.markChatReadForSeller(item.chatId);
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => _SellerReplyScreen(
              chatId: item.chatId,
              sellerId: sellerId,
              customerId: item.customerId,
              customerName: item.customerName,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasUnread ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: hasUnread
              ? Border.all(color: const Color(0xFF059669).withValues(alpha: 0.35))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Text(
                item.customerName.isNotEmpty
                    ? item.customerName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.customerName,
                          style: TextStyle(
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            item.unreadForSeller > 9 ? '9+' : '${item.unreadForSeller}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    whatsAppLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasUnread ? Colors.black87 : Colors.grey[600],
                      fontSize: 14,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatTime(item.updatedAt),
              style: TextStyle(
                color: hasUnread ? const Color(0xFF059669) : Colors.grey[500],
                fontSize: 12,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${dt.day}/${dt.month}';
  }
}

class _SellerReplyScreen extends StatefulWidget {
  const _SellerReplyScreen({
    required this.chatId,
    required this.sellerId,
    required this.customerId,
    required this.customerName,
  });

  final String chatId;
  final String sellerId;
  final String customerId;
  final String customerName;

  @override
  State<_SellerReplyScreen> createState() => _SellerReplyScreenState();
}

class _SellerReplyScreenState extends State<_SellerReplyScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  String _sellerName = 'Seller';

  @override
  void initState() {
    super.initState();
    SellerChatService.markChatReadForSeller(widget.chatId);
    _loadSellerName();
  }

  Future<void> _loadSellerName() async {
    try {
      final p = await AppBackend.instance.getUserProfile(widget.sellerId);
      if (mounted) {
        setState(() {
          _sellerName = p.shopName.isNotEmpty ? p.shopName : p.name;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    _controller.clear();
    await SellerChatService.sendSellerMessage(
      chatId: widget.chatId,
      sellerId: widget.sellerId,
      customerId: widget.customerId,
      customerName: widget.customerName,
      sellerName: _sellerName,
      text: t,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<SellerChatMessage>>(
              stream: SellerChatService.watchMessages(widget.chatId),
              builder: (context, snap) {
                final messages = snap.data ?? [];
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final isSeller = m.sender == 'seller';
                    return Align(
                      alignment:
                          isSeller ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSeller
                              ? const Color(0xFF059669)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          m.text,
                          style: TextStyle(
                            color: isSeller ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Reply to customer…',
                        border: OutlineInputBorder(),
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
        ],
      ),
    );
  }
}
