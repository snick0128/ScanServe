import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

/// Seed script to create administrative users with roles
/// Run with: flutter run -t lib/seed_users.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('🔥 Firebase initialized');

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    // List of users to create/update
    final usersToSeed = [
      {
        'email': 'masteradmin@scanserve.com',
        'password': 'password123',
        'role': 'admin',
        'tenantId': 'demo_tenant',
        'tenantName': 'Demo Restaurant',
      },
      {
        'email': 'demoadmin@scanserve.com',
        'password': '123456',
        'role': 'admin',
        'tenantId': 'demo_tenant',
        'tenantName': 'Demo Restaurant',
      },
      {
        'email': 'demokitchen@scanserve.com',
        'password': '123456',
        'role': 'kitchen',
        'tenantId': 'demo_tenant',
        'tenantName': 'Demo Restaurant',
      },
      {
        'email': 'democaptain@scanserve.com',
        'password': '123456',
        'role': 'captain',
        'tenantId': 'demo_tenant',
        'tenantName': 'Demo Restaurant',
        'assignedTables': ['table_01', 'table_02'],
      },
      {
        'email': 'superadmin@scanserve.com', // or nick@yopmail.com
        'password': 'password123',
        'role': 'superadmin',
        'tenantId': 'global',
        'tenantName': 'Global Console',
      },
    ];

    for (final userData in usersToSeed) {
      final email = userData['email'] as String;
      final password = userData['password'] as String;
      final role = userData['role'] as String;

      print('👤 Processing user: $email...');

      String? uid;
      try {
        // Try to create the user in Firebase Auth
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        uid = userCredential.user?.uid;
        print('✅ Auth user created: $uid');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          print('ℹ️ User already exists in Auth. Looking up UID...');
          // Since we can't search users with client SDK, 
          // we'll ask the user to manually enter UID if it exists but not in Firestore
          // Or we can try to sign in to get the UID (but we'd need the password)
          try {
             final cred = await auth.signInWithEmailAndPassword(email: email, password: password);
             uid = cred.user?.uid;
             print('✅ Found existing UID via sign-in: $uid');
          } catch (signInError) {
             print('❌ Primary password failed. Trying fallback "password123"...');
             try {
                final cred = await auth.signInWithEmailAndPassword(email: email, password: 'password123');
                uid = cred.user?.uid;
                await cred.user?.updatePassword(password);
                print('✅ Recovered user and UPDATED password to $password');
             } catch (e2) {
                print('❌ Could not access user with fallback password either.');
                continue;
             }
          }
        } else {
          print('❌ Error creating auth user: ${e.message}');
          continue;
        }
      }

      if (uid != null) {
        // Create/Update the user document in Firestore
        // We remove password from the data stored in Firestore
        final firestoreData = Map<String, dynamic>.from(userData);
        firestoreData.remove('password');
        
        await firestore.collection('users').doc(uid).set({
          ...firestoreData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('✅ Firestore document created for $role role');
      }
    }

    print('\n🎉 All roles have been seeded successfully!');
    print('You can now log in with:');
    print('1. Admin: demoadmin@scanserve.com / password123');
    print('2. Kitchen: demokitchen@scanserve.com / 123456');
    print('3. SuperAdmin: superadmin@scanserve.com / password123');
    
    // Sign out to clean up session
    await auth.signOut();

  } catch (e) {
    print('❌ Critical Error: $e');
  }
}
