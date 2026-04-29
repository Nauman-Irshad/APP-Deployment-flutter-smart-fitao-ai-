import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('All', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Select', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),


            Column(
              children: [
                _MessageTile(
                  sender: 'Farhan Butt',
                  message: '[Order card]',
                  date: '17/08',
                  isOfficial: false,
                  unreadCount: 0,
                ),
                _MessageTile(
                  sender: 'malikiqraa951',
                  message: 'asa bn jayega?',
                  date: '13/08',
                  isOfficial: false,
                  unreadCount: 1,
                ),
                _MessageTile(
                  sender: 'sadia naveed',
                  message: '???',
                  date: '12/08',
                  isOfficial: false,
                  unreadCount: 3,
                ),
                _MessageTile(
                  sender: 'uzmariaz341',
                  message: '[Product card]',
                  date: '11/08',
                  isOfficial: false,
                  unreadCount: 1,
                ),
                _MessageTile(
                  sender: 'Umme Rubab',
                  message: 'abhi tk to ship pe hi hai',
                  date: '11/08',
                  isOfficial: false,
                  unreadCount: 0,
                ),
                _MessageTile(
                  sender: 'Taliyah Saleem',
                  message: 'can i please have it on the 12th',
                  date: '09/08',
                  isOfficial: false,
                  unreadCount: 1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _MessageTile extends StatefulWidget {
  final String sender;
  final String message;
  final String date;
  final bool isOfficial;
  final int unreadCount;

  const _MessageTile({
    required this.sender,
    required this.message,
    required this.date,
    required this.isOfficial,
    required this.unreadCount,
  });

  @override
  State<_MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<_MessageTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Card(
          elevation: _isHovered ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _isHovered
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: _isHovered ? 3 : 2,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(senderName: widget.sender),
                  ),
                );
              },
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: _isHovered
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                child: Text(
                  widget.sender[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                widget.sender,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                widget.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (widget.unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.unreadCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class ChatDetailScreen extends StatefulWidget {
  final String senderName;

  const ChatDetailScreen({super.key, required this.senderName});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello, I would like to order a custom Shalwar Kameez',
      'isTailor': false,
      'time': '10:30 AM',
    },
    {
      'text': 'Sure! I can help you with that. What size and color would you prefer?',
      'isTailor': true,
      'time': '10:32 AM',
    },
    {
      'text': 'I need size Medium in white color',
      'isTailor': false,
      'time': '10:35 AM',
    },
    {
      'text': 'Perfect! Medium white Shalwar Kameez. It will be ready in 3-4 days. Is that okay?',
      'isTailor': true,
      'time': '10:36 AM',
    },
    {
      'text': 'Yes, that works for me. What will be the price?',
      'isTailor': false,
      'time': '10:40 AM',
    },
    {
      'text': 'The price is Rs 2,500. You can pay when you collect the order.',
      'isTailor': true,
      'time': '10:42 AM',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': _messageController.text.trim(),
        'isTailor': true,
        'time': DateTime.now().toString().substring(11, 16),
      });
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withOpacity(0.3),
              child: Text(
                widget.senderName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.senderName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'online',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.white,
            itemBuilder: (context) => [
              const PopupMenuItem(child: Text('View contact')),
              const PopupMenuItem(child: Text('Media, links, and docs')),
              const PopupMenuItem(child: Text('Search')),
              const PopupMenuItem(child: Text('Mute notifications')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [

          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFECE5DD),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final prevMessage = index > 0 ? _messages[index - 1] : null;
                  final showTime = prevMessage == null ||
                      (prevMessage['time'] as String) != (message['time'] as String);

                  return Column(
                    children: [
                      if (showTime)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            message['time'] as String,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      _ChatBubble(
                        text: message['text'],
                        isTailor: message['isTailor'],
                        time: message['time'],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey.shade600, size: 26),
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 15),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.attach_file, color: Colors.grey.shade600, size: 24),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.grey.shade600, size: 24),
                  onPressed: () {},
                ),
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF075E54),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isTailor;
  final String time;

  const _ChatBubble({
    required this.text,
    required this.isTailor,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isTailor ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 4,
          top: 2,
          left: isTailor ? 50 : 0,
          right: isTailor ? 0 : 50,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isTailor
              ? const Color(0xFFDCF8C6)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: Radius.circular(isTailor ? 8 : 0),
            bottomRight: Radius.circular(isTailor ? 0 : 8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                height: 1.3,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (isTailor) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: Colors.blue.shade700,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}