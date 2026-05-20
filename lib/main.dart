import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'screens/branch_selection_screen.dart';
import 'providers/theme_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'providers/prefs_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPrefs = await SharedPreferences.getInstance();
  


  if (!kIsWeb) {
    Stripe.publishableKey = "pk_test_your_key_here";
  }
  
  runApp(const ProviderScope(child: FuocoApp()));
}

class FuocoApp extends ConsumerWidget {
  const FuocoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return MaterialApp(
      title: 'Fuoco',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFED145B),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        cardColor: Colors.white,
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFED145B),
          primary: const Color(0xFFED145B),
          secondary: const Color(0xFF272264),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFED145B),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFED145B),
          primary: const Color(0xFFED145B),
          secondary: const Color(0xFF272264),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
          onSurface: Colors.white,
        ),
      ),
      home: const BranchSelectionScreen(),
    );
  }
}
