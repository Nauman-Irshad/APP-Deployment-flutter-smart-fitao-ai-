import 'package:flutter/material.dart';
import '../User 3D Market Place/chat.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: null,
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [

          SizedBox(width: 10),
        ],
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
                  Text(
                    'Select',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),

            Column(
              children: const [

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

class _MessageTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.blue,
          child: Text(
            sender[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(sender, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(message),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
        tileColor: isOfficial
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : null,
        onTap: () {
          
          final chatId = sender.toLowerCase().replaceAll(' ', '_');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                initialChatId: chatId,
                initialChatName: sender,
              ),
            ),
          );
        },
      ),
    );
  }
}


