import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/food_item.dart';

class FavoritesNotifier extends Notifier<List<FoodItem>> {
  @override
  List<FoodItem> build() {
    ref.watch(authStateProvider); // Rebuild when auth state changes
    _loadFromFirestore();
    return [];
  }

  Future<void> _loadFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('favorites_data')) {
        final raw = doc.data()!['favorites_data'] as String;
        final decoded = jsonDecode(raw) as List<dynamic>;
        state = decoded
            .map((e) => _foodItemFromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Handle error gracefully
    }
  }

  Future<void> _saveToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final encoded = jsonEncode(state.map((e) => _foodItemToJson(e)).toList());
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'favorites_data': encoded,
      }, SetOptions(merge: true));
    } catch (e) {
      // Handle error gracefully
    }
  }

  Map<String, dynamic> _foodItemToJson(FoodItem item) => {
    'id': item.id,
    'name': item.name,
    'price': item.price,
    'imageUrl': item.imageUrl,
    'category': item.category,
    'description': item.description,
    'isAvailable': item.isAvailable,
    'isPopular': item.isPopular,
    'rating': item.rating,
  };

  FoodItem _foodItemFromJson(Map<String, dynamic> itemData) => FoodItem(
    id: itemData['id'],
    name: itemData['name'],
    price: (itemData['price'] as num).toDouble(),
    imageUrl: itemData['imageUrl'],
    category: itemData['category'],
    description: itemData['description'] ?? '',
    isAvailable: itemData['isAvailable'] ?? true,
    isPopular: itemData['isPopular'] ?? false,
    rating: (itemData['rating'] as num?)?.toDouble() ?? 4.5,
  );

  void toggleFavorite(FoodItem item) {
    if (state.any((i) => i.id == item.id)) {
      state = state.where((i) => i.id != item.id).toList();
    } else {
      state = [...state, item];
    }
    _saveToFirestore();
  }

  bool isFavorite(String id) {
    return state.any((item) => item.id == id);
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<FoodItem>>(
  () {
    return FavoritesNotifier();
  },
);
