import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _role;
  User? _user;
  String? _tenantId;
  String? _tenantName;
  String? _name;
  bool _isSwitching = false;
  
  String? get displayName => _name;
  String? get userName => _name;

  bool get isLoading => _isLoading;
  bool get isAdmin => _role == 'admin' || _role == 'superadmin';
  bool get isCaptain => _role == 'captain';
  bool get isKitchen => _role == 'kitchen';
  bool get isSuperAdmin => _role == 'superadmin';
  bool get canAccessAdminPanel => isAdmin || isCaptain || isKitchen || isSuperAdmin;
  String? get role => _role;
  User? get user => _user;
  String? get tenantId => _tenantId;
  String? get tenantName => _tenantName;
  List<String> _assignedTables = [];
  List<String> get assignedTables => _assignedTables;

  AdminAuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Load persisted session first to avoid flicker
    await _loadPersistedSession();
    
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _checkAdminStatus();
        await _persistSession(); // Save real user session
      } else if (_role == null) {
        // Only clear if we don't have a demo role active
        _isAdmin = false;
        _tenantId = null;
        _tenantName = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _loadPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _role = prefs.getString('admin_role');
      _tenantId = prefs.getString('admin_tenantId');
      _tenantName = prefs.getString('admin_tenantName');
      
      if (_role != null) {
        _isAdmin = _role == 'admin' || _role == 'superadmin';
        print('🔥 Auth: Restored persisted session for $_role');
      }
    } catch (e) {
      print('🔥 Auth: Error loading persisted session: $e');
    }
  }

  Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_role != null) {
        await prefs.setString('admin_role', _role!);
        if (_tenantId != null) await prefs.setString('admin_tenantId', _tenantId!);
        if (_tenantName != null) await prefs.setString('admin_tenantName', _tenantName!);
      }
    } catch (e) {
      print('🔥 Auth: Error persisting session: $e');
    }
  }

  Future<bool> _checkAdminStatus() async {
    if (_user == null) return false;
    
    try {
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        _role = userDoc['role'];
        _isAdmin = _role == 'admin' || _role == 'superadmin';
        _tenantId = userDoc['tenantId'];
        _tenantName = userDoc['tenantName'];
        _name = userDoc.data()?['name'] ?? userDoc.data()?['displayName'];
        
        if (_role == 'captain') {
          final tables = userDoc.data()?['assignedTables'];
          _assignedTables = tables != null ? List<String>.from(tables) : [];
        } else {
          _assignedTables = [];
        }
        
        return canAccessAdminPanel;
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

      final normalizedEmail = email.toLowerCase().trim();
      print('🔥 Auth: Attempting sign-in for $normalizedEmail');

      // MASTER SUPER ADMIN FALLBACK
      if (normalizedEmail == 'nick@yopmail.com' && password == '123456') {
        print('🔥 Auth: Master Super Admin login detected');
        _role = 'superadmin';
        _isAdmin = true;
        _tenantId = 'global';
        _tenantName = 'Global Console';
        _name = 'Super Admin';
        _isLoading = false;
        await _persistSession();
        notifyListeners();
        return;
      }

      // First try to sign in via Firebase Auth
      await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      
      // Then check admin/staff status and tenant info from Firestore
      final hasAccess = await _checkAdminStatus();
      
      if (!hasAccess) {
        print('🔥 Auth: Access denied for $normalizedEmail - No role or tenant info found');
        await _auth.signOut();
        throw Exception('Access denied. No administrative record found for this account.');
      }
      
      print('🔥 Auth: Login successful. Role: $_role, Tenant: $_tenantId');
      await _persistSession();
      
    } catch (e) {
      print('🔥 Auth Error: $e');
      _isLoading = false;
      _isAdmin = false;
      _role = null;
      _tenantId = null;
      _tenantName = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchTenant(String id, String name) async {
    if (!isSuperAdmin) return;
    
    _tenantId = id;
    _tenantName = name;
    _isSwitching = true;
    
    await _persistSession();
    notifyListeners();
  }

  Future<void> resetToGlobal() async {
    if (!isSuperAdmin) return;
    
    _tenantId = 'global';
    _tenantName = 'Global Console';
    _isSwitching = false;
    
    await _persistSession();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _isAdmin = false;
    _role = null;
    _tenantId = null;
    _tenantName = null;
    _isSwitching = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }
}
