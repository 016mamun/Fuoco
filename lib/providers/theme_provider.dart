import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'prefs_provider.dart';

class ThemeModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return sharedPrefs.getBool('is_dark_mode') ?? false;
  }

  void setTheme(bool isDark) {
    state = isDark;
  }
}

final isDarkModeProvider = NotifierProvider<ThemeModeNotifier, bool>(() {
  return ThemeModeNotifier();
});
