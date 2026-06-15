import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/tailor_chat_service.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Sign in as tailor to see customer messages.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<TailorChatInboxItem>>(
        stream: TailorChatService.watchTailorInbox(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load inbox:\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No customer chats yet.\nWhen a customer messages you from Find tailor, it appears here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _InboxTile(item: item, tailorId: uid);
            },
          );
        },
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.item, required this.tailorId});

  final TailorChatInboxItem item;
  final String tailorId;

  @override
  Widget build(BuildContext context) {
    final preview = item.lastMessage.isNotEmpty
        ? item.lastMessage
        : 'Open chat';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              chatId: item.chatId,
              tailorId: tailorId,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            Text(
              _formatTime(item.updatedAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
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

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.tailorId,
    required this.customerId,
    required this.customerName,
  });

  final String chatId;
  final String tailorId;
  final String customerId;
  final String customerName;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await TailorChatService.sendTailorMessage(
      chatId: widget.chatId,
      tailorId: widget.tailorId,
      customerId: widget.customerId,
      customerName: widget.customerName,
      tailorName: 'Tailor',
      text: text,
    );
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.customerName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<TailorChatMessage>>(
              stream: TailorChatService.watchMessages(widget.chatId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snap.data ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients && messages.isNotEmpty) {
                    _scroll.jumpTo(_scroll.position.maxScrollExtent);
                  }
                });
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Customer messages will appear here.\nNo auto-replies — only what they send.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final isTailor = m.sender == 'tailor';
                    return Align(
                      alignment: isTailor
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
                        ),
                        child: _TailorMessageBubble(message: m, isTailor: isTailor),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Reply to customer...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendText,
                  icon: const Icon(Icons.send, color: Color(0xFF059669)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TailorMessageBubble extends StatelessWidget {
  const _TailorMessageBubble({
    required this.message,
    required this.isTailor,
  });

  final TailorChatMessage message;
  final bool isTailor;

  @override
  Widget build(BuildContext context) {
    final bg = isTailor ? const Color(0xFF059669) : Colors.white;
    final fg = isTailor ? Colors.white : Colors.black87;

    if (message.type == 'product') {
      return _cardBubble(
        bg: bg,
        fg: fg,
        label: 'PRODUCT',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.productTitle ?? message.text,
              style: TextStyle(fontWeight: FontWeight.bold, color: fg, fontSize: 15),
            ),
            if (message.productPrice != null)
              Text('PKR ${message.productPrice}', style: TextStyle(color: fg)),
            if (message.productSize != null && message.productSize!.isNotEmpty)
              Text('Size ${message.productSize}', style: TextStyle(color: fg)),
            if (message.text.isNotEmpty && message.text != message.productTitle)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(message.text, style: TextStyle(fontSize: 12, color: fg)),
              ),
          ],
        ),
      );
    }

    if (message.type == 'size_chart') {
      return _cardBubble(
        bg: bg,
        fg: fg,
        label: 'SIZE CHART',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.sizeChartTitle ?? 'Size chart',
              style: TextStyle(fontWeight: FontWeight.bold, color: fg),
            ),
            if (message.sizeChartRows != null)
              ...message.sizeChartRows!.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    row.entries.map((e) => '${e.key}: ${e.value}').join(' · '),
                    style: TextStyle(fontSize: 12, color: fg),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isTailor
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
      ),
      child: Text(message.text, style: TextStyle(color: fg)),
    );
  }

  Widget _cardBubble({
    required Color bg,
    required Color fg,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: isTailor ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isTailor ? Colors.white70 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
