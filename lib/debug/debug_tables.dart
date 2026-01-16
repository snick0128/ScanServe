import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Debug utility to check tables in Firestore
Future<void> debugTables(String tenantId) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    final firestore = FirebaseFirestore.instance;
    
    print('🔍 Checking tables for tenant: $tenantId');
    
    // Try to get tables without orderBy first
    final snapshot = await firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('tables')
        .get();
    
    print('📊 Found ${snapshot.docs.length} tables');
    
    for (final doc in snapshot.docs) {
      print('  - Table ID: ${doc.id}');
      print('    Data: ${doc.data()}');
    }
    
    // Now try with orderBy
    try {
      final orderedSnapshot = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('tables')
          .orderBy('orderIndex')
          .get();
      
      print('✅ OrderBy query successful: ${orderedSnapshot.docs.length} tables');
    } catch (e) {
      print('❌ OrderBy query failed: $e');
      print('   This means you need to create a Firestore index for orderIndex');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
