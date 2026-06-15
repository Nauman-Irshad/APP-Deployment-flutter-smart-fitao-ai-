import 'package:flutter/material.dart';

import '../config/demo_accounts.dart';
import '../services/demo_accounts_service.dart';
import '../widgets/customer_peer_chat_screen.dart';
import 'ai_chatbot_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.initialChatId,
    this.initialChatName,
    this.initialChatType,
    this.initialPeerId,
  });

  final String? initialChatId;
  final String? initialChatName;
  final String? initialChatType;
  /// Firebase UID when opening seller chat from product page.
  final String? initialPeerId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatListEntry {
  _ChatListEntry({
    required this.id,
    required this.name,
    required this.type,
    this.peerId,
    this.lastMessage = '',
    this.time = '',
  });

  final String id;
  final String name;
  final String type;
  final String? peerId;
  String lastMessage;
  String time;
}

class _ChatScreenState extends State<ChatScreen> {
  bool _loading = true;
  String? _loadHint;

  final List<_ChatListEntry> _entries = [
    _ChatListEntry(
      id: 'ai_chat_bot',
      name: 'AI Chat Bot',
      type: 'Bot',
      lastMessage: 'SmartFitao AI — products, delivery, try-on',
      time: 'Now',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialChatId == 'ai_chat_bot') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openAi();
      });
      return;
    }
    _loadPeers().then((_) {
      if (!mounted) return;
      _maybeOpenInitial();
    });
  }

  void _maybeOpenInitial() {
    final peerId = widget.initialPeerId?.trim();
    if (peerId != null && peerId.isNotEmpty) {
      _ChatListEntry? match;
      for (final e in _entries) {
        if (e.peerId == peerId) {
          match = e;
          break;
        }
      }
      if (match != null) {
        _pushPeerChat(match);
        return;
      }
      _pushPeerChat(
        _ChatListEntry(
          id: 'seller_peer_$peerId',
          name: widget.initialChatName ?? 'Seller',
          type: 'Seller',
          peerId: peerId,
        ),
      );
      return;
    }
    final id = widget.initialChatId;
    if (id == null) return;
    for (final e in _entries) {
      if (e.id == id) {
        _openEntry(e);
        break;
      }
    }
  }

  Future<void> _loadPeers() async {
    setState(() {
      _loading = true;
      _loadHint = null;
    });
    try {
      await DemoAccountsService.instance.preload();
      final tailor = DemoAccountsService.instance.cachedTailor;
      final seller = DemoAccountsService.instance.cachedSeller;

      _entries.removeWhere((e) => e.id.startsWith('tailor_') || e.id.startsWith('seller_'));

      if (tailor != null) {
        _entries.add(
          _ChatListEntry(
            id: 'tailor_${tailor.uid}',
            name: tailor.shopName.isNotEmpty ? tailor.shopName : tailor.name,
            type: 'Tailor',
            peerId: tailor.uid,
            lastMessage: 'Live chat — ${DemoAccounts.tailorEmail}',
            time: '',
          ),
        );
      } else {
        _loadHint =
            'Register tailor: ${DemoAccounts.tailorEmail} / ${DemoAccounts.tailorPassword}';
      }

      if (seller != null) {
        _entries.add(
          _ChatListEntry(
            id: 'seller_${seller.uid}',
            name: seller.shopName.isNotEmpty ? seller.shopName : seller.name,
            type: 'Seller',
            peerId: seller.uid,
            lastMessage: 'Live chat — ${DemoAccounts.sellerEmail}',
            time: '',
          ),
        );
      } else {
        _loadHint = (_loadHint ?? '') +
            (_loadHint == null ? '' : '\n') +
            'Register seller: ${DemoAccounts.sellerEmail} / ${DemoAccounts.sellerPassword}';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openAi() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const AiChatbotScreen()),
    );
  }

  void _pushPeerChat(_ChatListEntry e) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CustomerPeerChatScreen(
          peerType: e.type == 'Tailor' ? 'tailor' : 'seller',
          peerId: e.peerId!,
          peerName: e.name,
          peerShopName: e.name,
        ),
      ),
    );
  }

  void _openEntry(_ChatListEntry e) {
    if (e.id == 'ai_chat_bot') {
      _openAi();
      return;
    }
    if (e.peerId == null || e.peerId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Register demo tailor/seller in Firebase first.')),
      );
      return;
    }
    _pushPeerChat(e);
  }

  Widget _buildList() {
    return Scaffold(
      backgroundColor: const Color(0xFFf3f4f6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_loadHint != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_loadHint!, style: const TextStyle(fontSize: 12)),
                  ),
                ..._entries.map((e) {
                  final isTailor = e.type == 'Tailor';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: e.id == 'ai_chat_bot'
                              ? const Color(0xFF059669)
                              : (isTailor
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFE0F2FE)),
                          child: Icon(
                            e.id == 'ai_chat_bot'
                                ? Icons.smart_toy
                                : (isTailor ? Icons.cut : Icons.store),
                            color: e.id == 'ai_chat_bot'
                                ? Colors.white
                                : const Color(0xFF059669),
                          ),
                        ),
                        title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${e.type} · ${e.lastMessage}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openEntry(e),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildList();
}
