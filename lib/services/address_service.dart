import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final addressServiceProvider = Provider((ref) => AddressService());

class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addAddress(Map<String, dynamic> addressData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .add({
      ...addressData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getAddresses() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList());
  }

  Future<void> deleteAddress(String addressId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }
}
