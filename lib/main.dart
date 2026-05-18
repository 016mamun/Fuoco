import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  if (!kIsWeb) {
    Stripe.publishableKey = "pk_test_your_key_here";
  }
  
  runApp(const ProviderScope(child: FuocoApp()));
}

class FuocoApp extends ConsumerWidget {
  const FuocoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Fuoco',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFFFA500),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFA500),
          primary: const Color(0xFFFFA500),
          secondary: const Color(0xFFFFCCBC),
          brightness: Brightness.light,
        ),
      ),
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, stack) => Scaffold(
          body: Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
