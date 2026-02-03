#!/usr/bin/env node

/**
 * Script to create KDS and Captain users for tenant: ghar-jesa-khana
 * 
 * Usage: node scripts/create_kds_users.js
 * 
 * This will create:
 * 1. Kitchen Staff (KDS) user - for kitchen display operations
 * 2. Captain user - for floor management and serving
 */

const admin = require('firebase-admin');
const readline = require('readline');

// Initialize Firebase Admin
const serviceAccount = require('../service-account-key.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const auth = admin.auth();
const db = admin.firestore();

const TENANT_ID = 'ghar-jesa-khana';

const users = [
    {
        email: 'kitchen@ghar-jesa-khana.com',
        password: 'Kitchen@2026',
        displayName: 'Kitchen Staff',
        role: 'kitchen',
        kitchenStationId: 'hot_kitchen', // Default to hot kitchen
        description: 'Kitchen Display System User'
    },
    {
        email: 'captain@ghar-jesa-khana.com',
        password: 'Captain@2026',
        displayName: 'Floor Captain',
        role: 'captain',
        description: 'Floor Captain for serving and table management'
    }
];

async function createUser(userData) {
    try {
        console.log(`\n📝 Creating user: ${userData.email}`);

        // Create Firebase Auth user
        const userRecord = await auth.createUser({
            email: userData.email,
            password: userData.password,
            displayName: userData.displayName,
            emailVerified: true
        });

        console.log(`✅ Firebase Auth user created: ${userRecord.uid}`);

        // Create Firestore user profile
        const userProfile = {
            uid: userRecord.uid,
            email: userData.email,
            displayName: userData.displayName,
            role: userData.role,
            tenantId: TENANT_ID,
            isActive: true,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        // Add kitchen station ID if it's a kitchen user
        if (userData.kitchenStationId) {
            userProfile.kitchenStationId = userData.kitchenStationId;
        }

        await db.collection('users').doc(userRecord.uid).set(userProfile);
        console.log(`✅ Firestore profile created for ${userData.role}`);

        // Add to tenant's staff collection
        await db.collection('tenants').doc(TENANT_ID).collection('staff').doc(userRecord.uid).set({
            uid: userRecord.uid,
            email: userData.email,
            displayName: userData.displayName,
            role: userData.role,
            isActive: true,
            addedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`✅ Added to tenant staff collection`);

        console.log(`\n🎉 ${userData.description} created successfully!`);
        console.log(`   Email: ${userData.email}`);
        console.log(`   Password: ${userData.password}`);
        console.log(`   Role: ${userData.role}`);
        if (userData.kitchenStationId) {
            console.log(`   Station: ${userData.kitchenStationId}`);
        }

        return userRecord;
    } catch (error) {
        if (error.code === 'auth/email-already-exists') {
            console.log(`⚠️  User ${userData.email} already exists. Updating profile...`);

            // Get existing user
            const existingUser = await auth.getUserByEmail(userData.email);

            // Update Firestore profile
            const userProfile = {
                email: userData.email,
                displayName: userData.displayName,
                role: userData.role,
                tenantId: TENANT_ID,
                isActive: true,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            };

            if (userData.kitchenStationId) {
                userProfile.kitchenStationId = userData.kitchenStationId;
            }

            await db.collection('users').doc(existingUser.uid).set(userProfile, { merge: true });
            console.log(`✅ Profile updated for existing user`);

            return existingUser;
        } else {
            console.error(`❌ Error creating user ${userData.email}:`, error.message);
            throw error;
        }
    }
}

async function main() {
    console.log('🚀 Creating KDS and Captain users for tenant: ghar-jesa-khana\n');
    console.log('='.repeat(60));

    try {
        // Check if tenant exists
        const tenantDoc = await db.collection('tenants').doc(TENANT_ID).get();
        if (!tenantDoc.exists) {
            console.error(`❌ Tenant '${TENANT_ID}' not found in database!`);
            console.log('\nPlease ensure the tenant exists before creating users.');
            process.exit(1);
        }

        console.log(`✅ Tenant '${TENANT_ID}' found\n`);

        // Create all users
        for (const userData of users) {
            await createUser(userData);
        }

        console.log('\n' + '='.repeat(60));
        console.log('✨ All users created successfully!\n');
        console.log('📋 Login Credentials:');
        console.log('─'.repeat(60));
        users.forEach(user => {
            console.log(`\n${user.description}:`);
            console.log(`  Email: ${user.email}`);
            console.log(`  Password: ${user.password}`);
            console.log(`  Role: ${user.role}`);
        });
        console.log('\n' + '='.repeat(60));
        console.log('\n⚠️  IMPORTANT: Please save these credentials securely!');
        console.log('You can change passwords after first login.\n');

    } catch (error) {
        console.error('\n❌ Script failed:', error);
        process.exit(1);
    } finally {
        process.exit(0);
    }
}

main();
