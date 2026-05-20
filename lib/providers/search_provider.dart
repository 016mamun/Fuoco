import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchBarVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void toggle() {
    state = !state;
  }

  void show() {
    state = true;
  }
}

final searchBarVisibilityProvider = NotifierProvider<SearchBarVisibilityNotifier, bool>(() {
  return SearchBarVisibilityNotifier();
});
