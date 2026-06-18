import 'package:cloud_firestore/cloud_firestore.dart';

class SellerChatInboxItem {
  const SellerChatInboxItem({
    required this.chatId,
    required this.customerId,
    required this.customerName,
    required this.lastMessage,
    this.updatedAt,
    this.unreadForSeller = 0,
  });

  final String chatId;
  final String customerId;
  final String customerName;
  final String lastMessage;
  final DateTime? updatedAt;
  final int unreadForSeller;

  static SellerChatInboxItem fromMap(Map<String, dynamic> data) {
    final updated = data['updatedAt'];
    DateTime? dt;
    if (updated is Timestamp) dt = updated.toDate();
    final unreadRaw = data['unreadForSeller'];
    final unread = unreadRaw is num ? unreadRaw.toInt() : 0;
    return SellerChatInboxItem(
      chatId: data['chatId']?.toString() ?? '',
      customerId: data['customerId']?.toString() ?? '',
      customerName: data['customerName']?.toString() ?? 'Customer',
      lastMessage: data['lastPreview']?.toString() ?? '',
      updatedAt: dt,
      unreadForSeller: unread,
    );
  }
}

class SellerChatMessage {
  const SellerChatMessage({
    required this.id,
    required this.sender,
    required this.type,
    required this.text,
    this.isCustomer = false,
  });

  final String id;
  final String sender;
  final String type;
  final String text;
  final bool isCustomer;

  static SellerChatMessage fromMap(Map<String, dynamic> data) {
    return SellerChatMessage(
      id: data['id']?.toString() ?? '',
      sender: data['sender']?.toString() ?? 'customer',
      type: data['type']?.toString() ?? 'text',
      text: data['text']?.toString() ?? '',
      isCustomer: data['sender'] == 'customer',
    );
  }
}

/// Customer ↔ seller messages (same pattern as [TailorChatService]).
class SellerChatService {
  SellerChatService._();

  static final _db = FirebaseFirestore.instance;

  static String chatId({
    required String sellerId,
    required String customerId,
  }) =>
      '${sellerId}__$customerId';

  static CollectionReference<Map<String, dynamic>> _messagesCol(String id) =>
      _db.collection('seller_customer_chats').doc(id).collection('messages');

  static Future<void> ensureChat({
    required String chatId,
    required String sellerId,
    required String customerId,
    required String customerName,
    required String sellerName,
  }) async {
    await _db.collection('seller_customer_chats').doc(chatId).set({
      'sellerId': sellerId,
      'customerId': customerId,
      'customerName': customerName,
      'sellerName': sellerName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> sendCustomerMessage({
    required String chatId,
    required String sellerId,
    required String customerId,
    required String customerName,
    required String sellerName,
    required String type,
    required String text,
  }) async {
    await ensureChat(
      chatId: chatId,
      sellerId: sellerId,
      customerId: customerId,
      customerName: customerName,
      sellerName: sellerName,
    );
    await _messagesCol(chatId).add({
      'sender': 'customer',
      'type': type,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('seller_customer_chats').doc(chatId).set({
      'lastPreview': text,
      'lastSender': 'customer',
      'unreadForSeller': FieldValue.increment(1),
      'unreadForCustomer': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> sendSellerMessage({
    required String chatId,
    required String sellerId,
    required String customerId,
    required String customerName,
    required String sellerName,
    required String text,
  }) async {
    await ensureChat(
      chatId: chatId,
      sellerId: sellerId,
      customerId: customerId,
      customerName: customerName,
      sellerName: sellerName,
    );
    await _messagesCol(chatId).add({
      'sender': 'seller',
      'type': 'text',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('seller_customer_chats').doc(chatId).set({
      'lastPreview': text,
      'lastSender': 'seller',
      'unreadForSeller': 0,
      'unreadForCustomer': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> markChatReadForSeller(String chatId) async {
    await _db.collection('seller_customer_chats').doc(chatId).set({
      'unreadForSeller': 0,
    }, SetOptions(merge: true));
  }

  static Future<void> markAllReadForSeller(String sellerId) async {
    final snap = await _db
        .collection('seller_customer_chats')
        .where('sellerId', isEqualTo: sellerId)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.set(doc.reference, {'unreadForSeller': 0}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  static Stream<int> watchSellerUnreadTotal(String sellerId) {
    return watchSellerInbox(sellerId).map(
      (items) => items.fold<int>(0, (sum, i) => sum + i.unreadForSeller),
    );
  }

  static Stream<int> watchCustomerUnreadTotal(String customerId) {
    return _db
        .collection('seller_customer_chats')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snap) {
          var total = 0;
          for (final d in snap.docs) {
            final n = d.data()['unreadForCustomer'];
            if (n is num) total += n.toInt();
          }
          return total;
        });
  }

  static Future<void> markChatReadForCustomer(String chatId) async {
    await _db.collection('seller_customer_chats').doc(chatId).set({
      'unreadForCustomer': 0,
    }, SetOptions(merge: true));
  }

  static Future<void> markAllReadForCustomer(String customerId) async {
    final snap = await _db
        .collection('seller_customer_chats')
        .where('customerId', isEqualTo: customerId)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.set(doc.reference, {'unreadForCustomer': 0}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  static Stream<List<SellerChatMessage>> watchMessages(String chatId) {
    return _messagesCol(chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => SellerChatMessage.fromMap({'id': d.id, ...d.data()}))
              .toList(),
        );
  }

  static Stream<List<SellerChatInboxItem>> watchSellerInbox(String sellerId) {
    return _db
        .collection('seller_customer_chats')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snap) {
          final items = snap.docs.map((d) {
            return SellerChatInboxItem.fromMap({
              'chatId': d.id,
              ...d.data(),
            });
          }).toList();
          items.sort((a, b) {
            final at = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bt = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bt.compareTo(at);
          });
          return items;
        });
  }
}
