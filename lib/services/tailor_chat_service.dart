import 'package:cloud_firestore/cloud_firestore.dart';

class TailorChatInboxItem {
  const TailorChatInboxItem({
    required this.chatId,
    required this.customerId,
    required this.customerName,
    required this.lastMessage,
    this.updatedAt,
    this.unreadForTailor = 0,
  });

  final String chatId;
  final String customerId;
  final String customerName;
  final String lastMessage;
  final DateTime? updatedAt;
  final int unreadForTailor;

  static TailorChatInboxItem fromMap(Map<String, dynamic> data) {
    final updated = data['updatedAt'];
    DateTime? dt;
    if (updated is Timestamp) dt = updated.toDate();
    final unreadRaw = data['unreadForTailor'];
    final unread = unreadRaw is num ? unreadRaw.toInt() : 0;
    return TailorChatInboxItem(
      chatId: data['chatId']?.toString() ?? '',
      customerId: data['customerId']?.toString() ?? '',
      customerName: data['customerName']?.toString() ?? 'Customer',
      lastMessage: data['lastPreview']?.toString() ?? '',
      updatedAt: dt,
      unreadForTailor: unread,
    );
  }
}

class TailorChatMessage {
  const TailorChatMessage({
    required this.id,
    required this.sender,
    required this.type,
    required this.text,
    this.productTitle,
    this.productPrice,
    this.productSize,
    this.sizeChartTitle,
    this.sizeChartRows,
  });

  final String id;
  final String sender;
  final String type;
  final String text;
  final String? productTitle;
  final int? productPrice;
  final String? productSize;
  final String? sizeChartTitle;
  final List<Map<String, String>>? sizeChartRows;

  static TailorChatMessage fromMap(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? 'text';
    final text = data['text']?.toString() ?? '';
    List<Map<String, String>>? rows;
    final sizeRaw = data['sizeRows'];
    if (sizeRaw is Map) {
      rows = sizeRaw.entries
          .map((e) => {e.key.toString(): e.value?.toString() ?? ''})
          .toList();
    }
    final price = data['productPricePkr'];
    return TailorChatMessage(
      id: data['id']?.toString() ?? '',
      sender: data['sender']?.toString() ?? 'customer',
      type: type,
      text: text,
      productTitle: data['productTitle']?.toString(),
      productPrice: price is num ? price.toInt() : int.tryParse('$price'),
      productSize: _sizeFromProductText(text),
      sizeChartTitle: type == 'size_chart' ? text : null,
      sizeChartRows: rows,
    );
  }

  static String? _sizeFromProductText(String text) {
    final m = RegExp(r'Size\s+([^\s·]+)', caseSensitive: false).firstMatch(text);
    return m?.group(1);
  }
}

/// Customer ↔ tailor messages (Firestore). No auto-replies — tailor app reads same data.
class TailorChatService {
  TailorChatService._();

  static final _db = FirebaseFirestore.instance;

  static String chatId({
    required String tailorId,
    required String customerId,
  }) =>
      '${tailorId}__$customerId';

  static CollectionReference<Map<String, dynamic>> _messagesCol(String id) =>
      _db.collection('tailor_customer_chats').doc(id).collection('messages');

  static Future<void> ensureChat({
    required String chatId,
    required String tailorId,
    required String customerId,
    required String customerName,
    required String tailorName,
  }) async {
    await _db.collection('tailor_customer_chats').doc(chatId).set({
      'tailorId': tailorId,
      'customerId': customerId,
      'customerName': customerName,
      'tailorName': tailorName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> sendCustomerMessage({
    required String chatId,
    required String tailorId,
    required String customerId,
    required String customerName,
    required String tailorName,
    required String type,
    required String text,
    Map<String, String>? sizeRows,
    String? productTitle,
    String? productColor,
    int? productPricePkr,
    String? productImagePath,
  }) async {
    await ensureChat(
      chatId: chatId,
      tailorId: tailorId,
      customerId: customerId,
      customerName: customerName,
      tailorName: tailorName,
    );
    await _messagesCol(chatId).add({
      'sender': 'customer',
      'type': type,
      'text': text,
      'sizeRows': sizeRows ?? {},
      if (productTitle != null) 'productTitle': productTitle,
      if (productColor != null) 'productColor': productColor,
      if (productPricePkr != null) 'productPricePkr': productPricePkr,
      if (productImagePath != null) 'productImagePath': productImagePath,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('tailor_customer_chats').doc(chatId).set({
      'lastPreview': _previewForType(type, text),
      'lastSender': 'customer',
      'unreadForTailor': FieldValue.increment(1),
      'unreadForCustomer': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> sendTailorMessage({
    required String chatId,
    required String tailorId,
    required String customerId,
    required String customerName,
    required String tailorName,
    required String text,
  }) async {
    await ensureChat(
      chatId: chatId,
      tailorId: tailorId,
      customerId: customerId,
      customerName: customerName,
      tailorName: tailorName,
    );
    await _messagesCol(chatId).add({
      'sender': 'tailor',
      'type': 'text',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('tailor_customer_chats').doc(chatId).set({
      'lastPreview': text,
      'lastSender': 'tailor',
      'unreadForTailor': 0,
      'unreadForCustomer': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String _previewForType(String type, String text) {
    if (type == 'product') return '[Product] $text';
    if (type == 'size_chart') return '[Size chart] $text';
    return text;
  }

  static Stream<List<Map<String, dynamic>>> watchMessagesRaw(String chatId) {
    return _messagesCol(chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return <String, dynamic>{
                'id': d.id,
                ...data,
                'isCustomer': data['sender'] == 'customer',
              };
            }).toList());
  }

  static Stream<List<TailorChatMessage>> watchMessages(String chatId) {
    return watchMessagesRaw(chatId).map(
      (list) => list.map(TailorChatMessage.fromMap).toList(),
    );
  }

  static Stream<int> watchTailorUnreadTotal(String tailorId) {
    return watchTailorInbox(tailorId).map(
      (items) => items.fold<int>(0, (sum, i) => sum + i.unreadForTailor),
    );
  }

  static Stream<int> watchCustomerUnreadTotal(String customerId) {
    return _db
        .collection('tailor_customer_chats')
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
    await _db.collection('tailor_customer_chats').doc(chatId).set({
      'unreadForCustomer': 0,
    }, SetOptions(merge: true));
  }

  static Future<void> markAllReadForCustomer(String customerId) async {
    final snap = await _db
        .collection('tailor_customer_chats')
        .where('customerId', isEqualTo: customerId)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.set(doc.reference, {'unreadForCustomer': 0}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  static Future<void> markChatReadForTailor(String chatId) async {
    await _db.collection('tailor_customer_chats').doc(chatId).set({
      'unreadForTailor': 0,
    }, SetOptions(merge: true));
  }

  static Future<void> markAllReadForTailor(String tailorId) async {
    final snap = await _db
        .collection('tailor_customer_chats')
        .where('tailorId', isEqualTo: tailorId)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.set(doc.reference, {'unreadForTailor': 0}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  static Stream<List<TailorChatInboxItem>> watchTailorInbox(String tailorId) {
    // No orderBy — avoids Firestore composite index; sort client-side.
    return _db
        .collection('tailor_customer_chats')
        .where('tailorId', isEqualTo: tailorId)
        .snapshots()
        .map((snap) {
          final items = snap.docs.map((d) {
            final data = d.data();
            return TailorChatInboxItem.fromMap({
              'chatId': d.id,
              ...data,
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
