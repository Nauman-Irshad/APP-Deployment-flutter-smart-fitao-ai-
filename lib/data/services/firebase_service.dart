import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String ordersCollection = 'orders';
  static const String productsCollection = 'products';
  static const String usersCollection = 'users';
  static const String sellersCollection = 'sellers';

  static Future<String> placeOrder({
    required String userId,
    required String productId,
    required String productTitle,
    required int quantity,
    required double price,
    required String category,
    required String productImage,
    String status = 'pending',
    String? userName,
    String? address,
    double? reducedPrice,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final data = <String, dynamic>{
        'userId': userId,
        'productId': productId,
        'productTitle': productTitle,
        'quantity': quantity,
        'unitPrice': price,
        'totalPrice': price * quantity,
        'category': category,
        'productImage': productImage,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (userName != null) data['userName'] = userName;
      if (address != null) data['address'] = address;
      if (reducedPrice != null) data['reducedPrice'] = reducedPrice;
      if (extraData != null) data.addAll(extraData);

      final docRef = await _firestore.collection(ordersCollection).add(data);
      try {
        await _firestore
            .collection('user_app')
            .doc(userId)
            .collection('order')
            .doc(docRef.id)
            .set(data);
      } catch (e) {}
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getUserOrders(String userId) {
    return _firestore
        .collection(ordersCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getAllOrders() {
    return _firestore
        .collection(ordersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _firestore.collection(ordersCollection).doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<DocumentSnapshot> getOrder(String orderId) async {
    return await _firestore.collection(ordersCollection).doc(orderId).get();
  }

  static Future<String> addProduct({
    required String title,
    required double price,
    required double originalPrice,
    required String category,
    required String image,
    required double rating,
    required int reviews,
  }) async {
    final docRef = await _firestore.collection(productsCollection).add({
      'title': title,
      'price': price,
      'originalPrice': originalPrice,
      'category': category,
      'image': image,
      'rating': rating,
      'reviews': reviews,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Future<int> uploadProductsFromList(
    List<Map<String, dynamic>> products,
  ) async {
    int uploadedCount = 0;
    for (var product in products) {
      await addProduct(
        title: product['title'] ?? 'Unknown',
        price: (product['price'] as num).toDouble(),
        originalPrice: (product['originalPrice'] as num).toDouble(),
        category: product['category'] ?? 'General',
        image: product['image'] ?? '',
        rating: (product['rating'] as num).toDouble(),
        reviews: product['reviews'] ?? 0,
      );
      uploadedCount++;
    }
    return uploadedCount;
  }

  static Stream<QuerySnapshot> getAllProducts() {
    return _firestore.collection(productsCollection).snapshots();
  }

  static Stream<QuerySnapshot> getProductsByCategory(String category) {
    return _firestore
        .collection(productsCollection)
        .where('category', isEqualTo: category)
        .snapshots();
  }

  static Future<DocumentSnapshot> getProduct(String productId) async {
    return await _firestore
        .collection(productsCollection)
        .doc(productId)
        .get();
  }

  static Stream<QuerySnapshot> searchProducts(String searchQuery) {
    return _firestore
        .collection(productsCollection)
        .where('title', isGreaterThanOrEqualTo: searchQuery)
        .where('title', isLessThan: searchQuery + 'z')
        .snapshots();
  }

  static Future<void> saveUserProfile({
    required String userId,
    required String name,
    required String email,
    required String profileImage,
  }) async {
    await _firestore.collection(usersCollection).doc(userId).set({
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<DocumentSnapshot> getUserProfile(String userId) async {
    return await _firestore.collection(usersCollection).doc(userId).get();
  }

  static Future<int> getSellerOrdersCount() async {
    try {
      final snapshot = await _firestore.collection(ordersCollection).get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  static Stream<QuerySnapshot> getRecentSellerOrders({int limit = 10}) {
    return _firestore
        .collection(ordersCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  static Future<double> getTotalSales() async {
    try {
      final snapshot = await _firestore.collection(ordersCollection).get();
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc['totalPrice'] as num).toDouble();
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  static Future<Map<String, int>> getOrderCountByStatus() async {
    try {
      final statusMap = {'pending': 0, 'shipped': 0, 'delivered': 0, 'cancelled': 0};
      for (var status in statusMap.keys) {
        final count = await _firestore
            .collection(ordersCollection)
            .where('status', isEqualTo: status)
            .count()
            .get();
        statusMap[status] = count.count ?? 0;
      }
      return statusMap;
    } catch (e) {
      return {};
    }
  }
}
