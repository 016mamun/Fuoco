import 'package:flutter_riverpod/flutter_riverpod.dart';

// Dummy user model for bypass
class DummyUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  
  DummyUser({required this.uid, required this.email, required this.displayName, this.photoURL});

  Future<void> updateDisplayName(String name) async {
    // Dummy update
  }

  Future<void> reload() async {
    // Dummy reload
  }
}

class AuthService extends Notifier<DummyUser?> {
  @override
  DummyUser? build() {
    return null; // Starts as not logged in
  }

  Future<void> signUp(String email, String password, String name) async {
    // Dummy signup
    await Future.delayed(const Duration(milliseconds: 500));
    state = DummyUser(uid: 'dummy-uid', email: email, displayName: name);
  }

  Future<void> signIn(String email, String password) async {
    // Dummy sign in
    await Future.delayed(const Duration(milliseconds: 500));
    state = DummyUser(uid: 'dummy-uid', email: email, displayName: 'Dummy User');
  }

  Future<void> signOut() async {
    state = null;
  }

  Future<void> signInWithGoogle() async {
    // Dummy google sign in
    await Future.delayed(const Duration(milliseconds: 500));
    state = DummyUser(uid: 'dummy-uid', email: 'google@example.com', displayName: 'Google User');
  }
}

final authServiceProvider = NotifierProvider<AuthService, DummyUser?>(() {
  return AuthService();
});

// We simulate auth state by watching the notifier state
final authStateProvider = StreamProvider<DummyUser?>((ref) {
  final user = ref.watch(authServiceProvider);
  return Stream.value(user);
});
