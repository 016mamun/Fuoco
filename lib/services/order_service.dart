import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';

final orderServiceProvider = Provider((ref) => OrderService());

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String address,
    required String paymentMethod,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final orderData = {
      'userId': user.uid,
      'items': items.map((item) => {
        'name': item.item.name,
        'quantity': item.quantity,
        'price': item.item.price,
        'imageUrl': item.item.imageUrl,
      }).toList(),
      'totalAmount': totalAmount,
      'address': address,
      'paymentMethod': paymentMethod,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('orders').add(orderData);
  }

  Stream<List<Map<String, dynamic>>> getUserOrders() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      docs.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return -1; // Pending timestamps (local writes) appear first
        if (bTime == null) return 1;
        return bTime.compareTo(aTime);
      });
      return docs;
    });
  }
}
