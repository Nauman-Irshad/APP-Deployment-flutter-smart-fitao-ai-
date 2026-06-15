import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/seller_chat_service.dart';

/// Seller inbox — real Firestore chats with customers (e.g. Ali).
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
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
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
                  'No customer chats yet.\nWhen Ali (or any user) messages your store from the 3D app, it appears here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final item = items[i];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF059669),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  item.customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(item.lastMessage),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => _SellerReplyScreen(
                        chatId: item.chatId,
                        sellerId: uid,
                        customerId: item.customerId,
                        customerName: item.customerName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
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
      sellerName: 'Fashion Store Premium',
      text: t,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat · ${widget.customerName}'),
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
