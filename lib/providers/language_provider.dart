import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'prefs_provider.dart';
import '../l10n/app_translations.dart';

class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    return sharedPrefs.getString('language') ?? 'English';
  }

  Future<void> setLanguage(String lang) async {
    await sharedPrefs.setString('language', lang);
    state = lang;
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(() {
  return LanguageNotifier();
});

extension TranslationExtension on WidgetRef {
  String tr(String key) {
    final lang = watch(languageProvider);
    final langKey = lang == 'বাংলা' ? 'bn' : 'en';
    return appTranslations[langKey]?[key] ?? key;
  }
}
