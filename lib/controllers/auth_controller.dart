import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthController extends ChangeNotifier {
  final _auth = FirebaseService.auth;

  Stream<User?> get currentUser => _auth.authStateChanges().map((user) {
    if (user == null) return null;
    return User(id: user.uid, email: user.email ?? '');
  });

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
