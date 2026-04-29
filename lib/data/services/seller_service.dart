import 'package:cloud_firestore/cloud_firestore.dart';

class SellerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<QuerySnapshot> getSellerOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getPendingOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getShippedOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'shipped')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getDeliveredOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'delivered')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<double> getTotalRevenue() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc['totalPrice'] as num).toDouble();
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> getTodaysSalesCount() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final snapshot = await _firestore
          .collection('orders')
          .where('createdAt',
              isGreaterThanOrEqualTo: startOfDay,
              isLessThan: startOfDay.add(Duration(days: 1)))
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final totalCount = await _firestore.collection('orders').count().get();
      final pendingCount = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      final shippedCount = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'shipped')
          .count()
          .get();
      final deliveredCount = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'delivered')
          .count()
          .get();
      return {
        'total': totalCount.count,
        'pending': pendingCount.count,
        'shipped': shippedCount.count,
        'delivered': deliveredCount.count,
      };
    } catch (e) {
      return {'total': 0, 'pending': 0, 'shipped': 0, 'delivered': 0};
    }
  }
}
