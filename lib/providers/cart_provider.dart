import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';

class CartItem {
  final FoodItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});
}

class CartNotifier extends Notifier<Map<String, CartItem>> {
  @override
  Map<String, CartItem> build() {
    return {};
  }

  void addItem(FoodItem item) {
    final newState = Map<String, CartItem>.from(state);
    if (newState.containsKey(item.id)) {
      newState[item.id]!.quantity++;
    } else {
      newState[item.id] = CartItem(item: item);
    }
    state = newState;
  }

  void addItemWithQuantity(FoodItem item, int quantity) {
    final newState = Map<String, CartItem>.from(state);
    if (newState.containsKey(item.id)) {
      newState[item.id]!.quantity += quantity;
    } else {
      newState[item.id] = CartItem(item: item, quantity: quantity);
    }
    state = newState;
  }

  void removeItem(String id) {
    final newState = Map<String, CartItem>.from(state);
    newState.remove(id);
    state = newState;
  }

  void incrementQuantity(String id) {
    final newState = Map<String, CartItem>.from(state);
    if (newState.containsKey(id)) {
      newState[id]!.quantity++;
      state = newState;
    }
  }

  void decrementQuantity(String id) {
    final newState = Map<String, CartItem>.from(state);
    if (newState.containsKey(id)) {
      if (newState[id]!.quantity > 1) {
        newState[id]!.quantity--;
        state = newState;
      } else {
        removeItem(id);
      }
    }
  }

  void clearCart() {
    state = {};
  }

  double get totalPrice {
    return state.values.fold(
      0,
      (total, cartItem) => total + (cartItem.item.price * cartItem.quantity),
    );
  }
}

final cartProvider = NotifierProvider<CartNotifier, Map<String, CartItem>>(() {
  return CartNotifier();
});
