import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/food_item.dart';

class CartItem {
  final FoodItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  Map<String, dynamic> toJson() => {
        'item': {
          'id': item.id,
          'name': item.name,
          'price': item.price,
          'imageUrl': item.imageUrl,
          'category': item.category,
          'description': item.description,
          'isAvailable': item.isAvailable,
          'isPopular': item.isPopular,
          'rating': item.rating,
        },
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final itemData = json['item'] as Map<String, dynamic>;
    return CartItem(
      item: FoodItem(
        id: itemData['id'],
        name: itemData['name'],
        price: (itemData['price'] as num).toDouble(),
        imageUrl: itemData['imageUrl'],
        category: itemData['category'],
        description: itemData['description'] ?? '',
        isAvailable: itemData['isAvailable'] ?? true,
        isPopular: itemData['isPopular'] ?? false,
        rating: (itemData['rating'] as num?)?.toDouble() ?? 4.5,
      ),
      quantity: json['quantity'] as int,
    );
  }
}

class CartNotifier extends Notifier<Map<String, CartItem>> {
  @override
  Map<String, CartItem> build() {
    ref.watch(authStateProvider); // Rebuild when auth state changes
    _loadFromFirestore();
    return {};
  }

  Future<void> _loadFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data()!.containsKey('cart_data')) {
        final raw = doc.data()!['cart_data'] as String;
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final loaded = decoded.map((k, v) => MapEntry(k, CartItem.fromJson(v as Map<String, dynamic>)));
        state = loaded;
      }
    } catch (e) {
      // Handle error gracefully
    }
  }

  Future<void> _saveToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final encoded = jsonEncode(state.map((k, v) => MapEntry(k, v.toJson())));
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'cart_data': encoded,
      }, SetOptions(merge: true));
    } catch (e) {
      // Handle error gracefully
    }
  }

  void addItem(FoodItem item) {
    final newState = Map<String, CartItem>.from(state);
    if (newState.containsKey(item.id)) {
      newState[item.id]!.quantity++;
    } else {
      newState[item.id] = CartItem(item: item);
    }
    state = newState;
    _saveToFirestore();
  }

  void addItemWithQuantity(FoodItem item, int quantity) {
    final newState = Map<String, CartItem>.from(state);
    if (newState.containsKey(item.id)) {
      newState[item.id]!.quantity += quantity;
    } else {
      newState[item.id] = CartItem(item: item, quantity: quantity);
    }
    state = newState;
    _saveToFirestore();
  }

  void removeItem(String id) {
    final newState = Map<String, CartItem>.from(state);
    newState.remove(id);
    state = newState;
    _saveToFirestore();
  }

  void incrementQuantity(String id) {
    final newState = Map<String, CartItem>.from(state);
    if (newState.containsKey(id)) {
      newState[id]!.quantity++;
      state = newState;
      _saveToFirestore();
    }
  }

  void decrementQuantity(String id) {
    final newState = Map<String, CartItem>.from(state);
    if (newState.containsKey(id)) {
      if (newState[id]!.quantity > 1) {
        newState[id]!.quantity--;
        state = newState;
        _saveToFirestore();
      } else {
        removeItem(id);
      }
    }
  }

  void clearCart() {
    state = {};
    _saveToFirestore();
  }

  double get totalPrice {
    return state.values.fold(0, (total, cartItem) => total + (cartItem.item.price * cartItem.quantity));
  }
}

final cartProvider = NotifierProvider<CartNotifier, Map<String, CartItem>>(() {
  return CartNotifier();
});
