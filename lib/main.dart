import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'screens/branch_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  


  if (!kIsWeb) {
    Stripe.publishableKey = "pk_test_your_key_here";
  }
  
  runApp(const ProviderScope(child: FuocoApp()));
}

class FuocoApp extends ConsumerWidget {
  const FuocoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {


    return MaterialApp(
      title: 'Fuoco',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFED145B),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFED145B),
          primary: const Color(0xFFED145B),
          secondary: const Color(0xFF272264),
          brightness: Brightness.light,
        ),
      ),
      home: BranchSelectionScreen(),
    );
  }
}
