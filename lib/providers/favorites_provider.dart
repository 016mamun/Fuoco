import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';

class FavoritesNotifier extends Notifier<List<FoodItem>> {
  @override
  List<FoodItem> build() {
    return [];
  }

  void toggleFavorite(FoodItem item) {
    if (state.any((i) => i.id == item.id)) {
      state = state.where((i) => i.id != item.id).toList();
    } else {
      state = [...state, item];
    }
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
