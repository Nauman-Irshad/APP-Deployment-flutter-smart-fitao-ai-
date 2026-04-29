import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'tailor_portfolio.dart';

class ChatScreen extends StatefulWidget {
  final String? initialChatId;
  final String? initialChatName;
  /// When opening a chat from product/seller profile, pass 'Seller' so the chat shows as seller and uses store icon.
  final String? initialChatType;

  const ChatScreen({super.key, this.initialChatId, this.initialChatName, this.initialChatType});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? _selectedChatId;
  final TextEditingController _messageController = TextEditingController();

  // Mock list of chats
  final List<Map<String, dynamic>> _chatList = [
    {
      'id': 'ai_chat_bot',
      'name': 'AI Chat Bot',
      'type': 'Bot',
      'image': 'assets/profile.jpg',
      'lastMessage': '24 hour chat bot how may i help u',
      'time': 'Now',
      'unread': 1,
    },
    {
      'id': 'tailor_ahmed',
      'name': 'Master Tailor Ahmed',
      'type': 'Tailor',
      'image': 'assets/1.webp',
      'lastMessage': 'Hello! How can I help you?',
      'time': '10:30 AM',
      'unread': 2,
    },
    {
      'id': 'tailor_fatima',
      'name': 'Expert Seamstress Fatima',
      'type': 'Tailor',
      'image': 'assets/2.webp',
      'lastMessage': 'Your order is ready!',
      'time': '9:15 AM',
      'unread': 0,
    },
    {
      'id': 'seller_premium',
      'name': 'Fashion Store Premium',
      'type': 'Seller',
      'image': 'assets/4.webp',
      'lastMessage': 'New collection available!',
      'time': '11:45 AM',
      'unread': 3,
    },
  ];

  // Mock local message storage
  final Map<String, List<Map<String, dynamic>>> _mockMessages = {
    'ai_chat_bot': [
      {
        'text': '24 hour chat bot how may i help u',
        'type': 'text',
        'senderId': 'bot',
        'timestamp': DateTime.now(),
        'isMe': false,
      }
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialChatId != null) {
      _selectedChatId = widget.initialChatId;
      
      final exists = _chatList.any((c) => c['id'] == _selectedChatId);
      if (!exists && widget.initialChatName != null) {
        _chatList.add({
          'id': _selectedChatId,
          'name': widget.initialChatName,
          'type': widget.initialChatType ?? 'Seller',
          'image': 'assets/profile.jpg',
          'lastMessage': 'Hello',
          'time': 'Now',
          'unread': 0,
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(String chatId, {String? type, String? content}) {
    String text = _messageController.text.trim();
    if (text.isEmpty && type == null) return;

    final newMessage = {
      'text': type != null ? content : text,
      'type': type ?? 'text', 
      'senderId': 'guest_user_123',
      'senderEmail': 'guest@example.com',
      'timestamp': DateTime.now(),
      'isMe': true,
    };

    setState(() {
      if (!_mockMessages.containsKey(chatId)) {
        _mockMessages[chatId] = [];
      }
      _mockMessages[chatId]!.insert(0, newMessage);
      _messageController.clear();
      
      // Update last message in chat list
      final chatIndex = _chatList.indexWhere((c) => c['id'] == chatId);
      if (chatIndex != -1) {
        _chatList[chatIndex]['lastMessage'] = newMessage['text'];
        _chatList[chatIndex]['time'] = 'Just now';
      }
    });

    // Simple mock bot response
    if (chatId == 'ai_chat_bot') {
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _mockMessages[chatId]!.insert(0, {
              'text': 'I am a mock bot. I received: ${newMessage['text']}',
              'type': 'text',
              'senderId': 'bot',
              'timestamp': DateTime.now(),
              'isMe': false,
            });
          });
        }
      });
    }
  }

  void _showAttachmentOptions(String chatId) {
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
            Text(
              "Share with Tailor/Seller",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
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
                    _showProductPicker(chatId);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.straighten,
                  label: "Size Chart",
                  color: Color(0xFF0284c7),
                  onTap: () {
                    Navigator.pop(context);
                    
                    _sendMessage(chatId, type: 'size_chart', content: 'Male Shalwar Kameez (Pakistan Culture)');
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
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
        ],
      ),
    );
  }

  void _showProductPicker(String chatId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Product to Share", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            Expanded(
              child: ListView(
                children: [
                  _buildProductItem(chatId, "Grey Casual Kameez Shalwar", "PKR 8,490.00"),
                  _buildProductItem(chatId, "Black Premium Fabric", "PKR 5,000.00"),
                  _buildProductItem(chatId, "White Cotton Latha", "PKR 3,500.00"),
                  _buildProductItem(chatId, "Blue Embroidered Kurta", "PKR 4,200.00"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(String chatId, String name, String price) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.checkroom, color: Colors.grey[500]),
      ),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Price: $price", style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF059669), foregroundColor: Colors.white),
        onPressed: () {
          Navigator.pop(context);
          _sendMessage(chatId, type: 'product', content: "$name - $price");
        },
        child: Text("Share"),
      ),
    );
  }

  Widget _buildChatList() {
    return Scaffold(
      backgroundColor: Color(0xFFf3f4f6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: _chatList.length,
        separatorBuilder: (ctx, i) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final chat = _chatList[index];
          final isTailor = chat['type'] == 'Tailor';
          return GestureDetector(
            onTap: () => setState(() => _selectedChatId = chat['id']),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                   BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      chat['id'] == 'ai_chat_bot'
                          ? CircleAvatar(
                              radius: 30,
                              backgroundColor: Color(0xFF059669),
                              child: Icon(Icons.smart_toy, color: Colors.white, size: 30),
                            )
                          : (chat['type'] == 'Seller'
                              ? CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Color(0xFF059669).withOpacity(0.2),
                                  child: Icon(Icons.store, color: Color(0xFF059669), size: 30),
                                )
                              : CircleAvatar(
                                  radius: 30,
                                  backgroundImage: AssetImage(chat['image'] as String),
                                  backgroundColor: Colors.grey[200],
                                )),
                      if(chat['unread'] > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          child: Text("${chat['unread']}", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(chat['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                            Text(chat['time'], style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isTailor ? Color(0xFFDCFCE7) : Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(chat['type'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isTailor ? Color(0xFF166534) : Color(0xFF0369A1))),
                            ),
                            SizedBox(width: 8),
                            Expanded(child: Text(chat['lastMessage'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[500], fontSize: 13))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatInterface(String chatId) {
    final chat = _chatList.firstWhere((c) => c['id'] == chatId);
    final messages = _mockMessages[chatId] ?? [];

    return Scaffold(
      backgroundColor: Color(0xFFE5E7EB), 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => setState(() => _selectedChatId = null),
        ),
        title: GestureDetector(
          onTap: () {
            if (chat['type'] == 'Tailor') {
               Navigator.push(context, MaterialPageRoute(builder: (_) => TailorPortfolioScreen(
                 tailor: {
                   'name': chat['name'],
                   'image': chat['image'],
                   'rating': 4.5,
                   'about': 'Expert tailor specializing in traditional wear.',
                 }
               )));
            }
          },
          child: Row(
            children: [
              chat['id'] == 'ai_chat_bot'
                  ? CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFF059669),
                      child: Icon(Icons.smart_toy, size: 20, color: Colors.white),
                    )
                  : (chat['type'] == 'Seller'
                      ? CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFF059669).withOpacity(0.2),
                          child: Icon(Icons.store, color: Color(0xFF059669), size: 20),
                        )
                      : CircleAvatar(radius: 18, backgroundImage: AssetImage(chat['image'] as String))),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chat['name'], style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(chat['type'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['isMe'] == true;
                final type = msg['type'] ?? 'text';
                
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? Color(0xFF059669) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: isMe ? Radius.circular(16) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : Radius.circular(16),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (type == 'text')
                          Text(msg['text'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
                        if (type == 'product')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                                child: Text("PRODUCT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isMe ? Colors.white70 : Colors.black54)),
                              ),
                              SizedBox(height: 5),
                              Text(msg['text'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        if (type == 'size_chart')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                                child: Text("SIZE CHART", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isMe ? Colors.white70 : Colors.black54)),
                              ),
                              SizedBox(height: 5),
                              Icon(Icons.straighten, color: isMe ? Colors.white : Colors.black87, size: 40),
                              Text("Shared Size Chart", style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                   icon: Container(
                     padding: EdgeInsets.all(8),
                     decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                     child: Icon(Icons.add, color: Color(0xFF059669)),
                   ),
                   onPressed: () => _showAttachmentOptions(chatId),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) => _sendMessage(chatId),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Color(0xFF059669)),
                  onPressed: () => _sendMessage(chatId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedChatId != null) {
      return _buildChatInterface(_selectedChatId!);
    }
    return _buildChatList();
  }
}
