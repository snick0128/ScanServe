import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  bool _isAdmin = false;
  User? _user;
  String? _tenantId;
  String? _tenantName;

  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  User? get user => _user;
  String? get tenantId => _tenantId;
  String? get tenantName => _tenantName;

  AdminAuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _checkAdminStatus();
      } else {
        _isAdmin = false;
        _tenantId = null;
        _tenantName = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> _checkAdminStatus() async {
    if (_user == null) return false;
    
    try {
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        _isAdmin = userDoc['role'] == 'admin';
        _tenantId = userDoc['tenantId'];
        _tenantName = userDoc['tenantName'];
        return _isAdmin;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check for demo credentials FIRST
      if (email == 'demoadmin@scanserve.com' && password == '123456') {
        _isAdmin = true;
        _tenantId = 'demo_tenant'; // Changed from 'demo_restaurant' to match seed_demo_data.dart
        _tenantName = 'Demo Restaurant';
        // We don't have a Firebase user, but we set the state to allow access
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // First try to sign in
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Then check admin status and tenant info
      await _checkAdminStatus();
      
      if (!_isAdmin) {
        await _auth.signOut();
        throw Exception('Access denied. Admin privileges required.');
      }
      
    } catch (e) {
      _isLoading = false;
      _isAdmin = false;
      _tenantId = null;
      _tenantName = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _isAdmin = false;
    _tenantId = null;
    _tenantName = null;
    notifyListeners();
  }
}
