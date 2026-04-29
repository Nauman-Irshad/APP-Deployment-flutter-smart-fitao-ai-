import 'package:cloud_firestore/cloud_firestore.dart';

class UserAppOrder {
  static Future<DocumentReference> create(Map<String, dynamic> orderData) async {
    final col = FirebaseFirestore.instance.collection('user_app_order');
    final docRef = col.doc();
    orderData['createdAt'] = FieldValue.serverTimestamp();
    orderData['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(orderData);
    return docRef;
  }
}
