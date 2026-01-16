import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/tenant_model.dart';

class SuperAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all restaurants/tenants
  Stream<List<Map<String, dynamic>>> getTenants() {
    return _firestore.collection('tenants').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Create a new tenant and its initial admin user doc
  // Note: Creating actual Firebase Auth credentials for OTHERS is restricted on client-side.
  // We will create the metadata, and they can be invited or use a specific flow.
  // For this demo, we can assume the Super Admin creates the User document which links them.
  Future<void> createTenant({
    required String name,
    required String slug,
    required String adminEmail,
    required String tempPassword,
    required String plan, // e.g. 'basic', 'premium'
    required DateTime expiryDate,
  }) async {
    final tenantId = slug.toLowerCase().replaceAll(' ', '-');
    
    // 1. Create Tenant Document
    await _firestore.collection('tenants').doc(tenantId).set({
      'name': name,
      'slug': slug,
      'createdAt': FieldValue.serverTimestamp(),
      'plan': plan,
      'subscriptionExpiry': Timestamp.fromDate(expiryDate),
      'isActive': true,
      'settings': {
        'currency': 'INR',
        'taxPercentage': 5.0,
      }
    });

    // 2. Create the User Document (Metadata)
    // We cannot create the Auth User from the client SDK (requires Admin SDK).
    // So we create the Firestore record so it's ready for them.
    // We'll use the email as the ID for now, or you can use a placeholder.
    // When they eventually sign up, we can link it or you can manually create the user in Firebase Console with this UID.
    
    // Ideally, you'd use a Cloud Function to create the user in Firebase Auth.
    // For this manual flow, we'll store a "pending_setup" record.
    
    await _firestore.collection('users').add({
      'email': adminEmail,
      'role': 'admin',
      'tenantId': tenantId,
      'tenantName': name,
      'createdAt': FieldValue.serverTimestamp(),
      'tempPassword': tempPassword, // NOTE: Insecure, only for manual handover reference
      'requiresSetup': true,
    });

    print('🔥 SuperAdmin: Tenant $tenantId created. User metadata added for $adminEmail.');
  }

  Future<void> updateSubscription(String tenantId, String plan, DateTime expiryDate) async {
    await _firestore.collection('tenants').doc(tenantId).update({
      'plan': plan,
      'subscriptionExpiry': Timestamp.fromDate(expiryDate),
    });
  }

  Future<void> deleteTenant(String tenantId) async {
    // Should use cloud functions to clean up subcollections
    await _firestore.collection('tenants').doc(tenantId).delete();
  }
}
