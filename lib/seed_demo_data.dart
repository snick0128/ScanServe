import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'firebase_options.dart';

/// Demo data seeding script for ScanServe Flutter Web customer app
/// Run with: flutter run -t lib/seed_demo_data.dart
///
/// WARNING: This script is for development/testing purposes only.
/// Do not use in production environments.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('🔥 Firebase initialized successfully');

    // Seed demo data
    await seedDemoData();

    print('✅ Demo data seeded successfully!');
    print('🎉 You can now test the ScanServe app with:');
    print('   - Tenant ID: demo_tenant');
    print('   - Tables: Table 1, Table 2, Table 3, Table 4, Table 5');
    print('   - Categories: Breakfast, Lunch, Dinner');
    print('   - Subcategories: Veg, Non-Veg, Beverages');

  } catch (e) {
    print('❌ Error seeding demo data: $e');
  }
}

Future<void> seedDemoData() async {
  final firestore = FirebaseFirestore.instance;
  const tenantId = 'demo_tenant';
  const uuid = Uuid();

  // 1. Create demo tenant
  await firestore.collection('tenants').doc(tenantId).set({
    'name': 'Demo Restaurant',
    'description': 'A demo restaurant for testing ScanServe features',
    'taxRate': 0.18, // 18% tax
    'avgPrepTime': 25, // 25 minutes average preparation time
    'createdAt': FieldValue.serverTimestamp(),
    'isActive': true,
    'isVegOnly': false, // Restaurant serves both veg and non-veg
  });

  print('🏪 Created demo tenant: $tenantId');

  // 2. Create categories and menu items
  final categories = [
    {
      'id': 'breakfast',
      'name': 'Breakfast',
      'subcategories': [
        {
          'id': 'breakfast_veg',
          'name': 'Veg',
          'items': [
            {
              'id': 'idli_sambar',
              'name': 'Idli Sambar',
              'description': 'Steamed rice cakes served with sambar and chutney',
              'price': 80.0,
              'image_url': 'https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?w=400&h=300&fit=crop',
            },
            {
              'id': 'dosa',
              'name': 'Masala Dosa',
              'description': 'Crispy crepe filled with spiced potatoes',
              'price': 120.0,
              'image_url': 'https://images.unsplash.com/photo-1668236543090-82e9d82c93c?w=400&h=300&fit=crop',
            },
            {
              'id': 'poha',
              'name': 'Poha',
              'description': 'Flattened rice cooked with onions, peanuts, and spices',
              'price': 60.0,
              'image_url': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400&h=300&fit=crop',
            },
          ],
        },
        {
          'id': 'breakfast_nonveg',
          'name': 'Non-Veg',
          'items': [
            {
              'id': 'chicken_sandwich',
              'name': 'Chicken Sandwich',
              'description': 'Grilled chicken with lettuce, tomato, and mayo',
              'price': 150.0,
              'image_url': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400&h=300&fit=crop',
            },
            {
              'id': 'omelette',
              'name': 'Cheese Omelette',
              'description': 'Fluffy omelette with cheese and herbs',
              'price': 90.0,
              'image_url': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&h=300&fit=crop',
            },
          ],
        },
        {
          'id': 'breakfast_beverages',
          'name': 'Beverages',
          'items': [
            {
              'id': 'filter_coffee',
              'name': 'Filter Coffee',
              'description': 'Traditional South Indian filter coffee',
              'price': 40.0,
              'image_url': 'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=400&h=300&fit=crop',
            },
            {
              'id': 'fresh_juice',
              'name': 'Orange Juice',
              'description': 'Freshly squeezed orange juice',
              'price': 60.0,
              'image_url': 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400&h=300&fit=crop',
            },
          ],
        },
      ],
    },
    {
      'id': 'meals',
      'name': 'Meals', // Combined Lunch and Dinner
      'subcategories': [
        // Lunch items
        {
          'id': 'lunch_veg',
          'name': 'Veg',
          'items': [
            {
              'id': 'veg_biryani',
              'name': 'Vegetable Biryani',
              'description': 'Aromatic rice with mixed vegetables and spices',
              'price': 180.0,
              'image_url': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400&h=300&fit=crop',
            },
            {
              'id': 'paneer_butter_masala',
              'name': 'Paneer Butter Masala',
              'description': 'Cottage cheese in rich tomato gravy',
              'price': 220.0,
              'image_url': 'https://images.unsplash.com/photo-1632778149955-e80f8ceca2e?w=400&h=300&fit=crop',
            },
            {
              'id': 'dal_tadka',
              'name': 'Dal Tadka',
              'description': 'Yellow lentils tempered with spices',
              'price': 140.0,
              'image_url': 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400&h=300&fit=crop',
            },
          ],
        },
        {
          'id': 'lunch_nonveg',
          'name': 'Non-Veg',
          'items': [
            {
              'id': 'chicken_biryani',
              'name': 'Chicken Biryani',
              'description': 'Fragrant rice with tender chicken pieces',
              'price': 250.0,
              'image_url': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&h=300&fit=crop',
            },
            {
              'id': 'fish_curry',
              'name': 'Fish Curry',
              'description': 'Fresh fish in coconut curry',
              'price': 280.0,
              'image_url': 'https://images.unsplash.com/photo-1559847844-5315695dadae?w=400&h=300&fit=crop',
            },
          ],
        },
        {
          'id': 'lunch_beverages',
          'name': 'Beverages',
          'items': [
            {
              'id': 'lassi',
              'name': 'Sweet Lassi',
              'description': 'Refreshing yogurt-based drink',
              'price': 50.0,
              'image_url': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=300&fit=crop',
            },
            {
              'id': 'masala_tea',
              'name': 'Masala Tea',
              'description': 'Spiced Indian tea with milk',
              'price': 35.0,
              'image_url': 'https://images.unsplash.com/photo-1544787214519-6655c7ecec8e?w=400&h=300&fit=crop',
            },
          ],
        },
        // Dinner items
        {
          'id': 'dinner_veg',
          'name': 'Veg',
          'items': [
            {
              'id': 'malai_kofta',
              'name': 'Malai Kofta',
              'description': 'Vegetable dumplings in creamy gravy',
              'price': 200.0,
              'image_url': 'https://images.unsplash.com/photo-1626776877761-72e2b1e27e8c?w=400&h=300&fit=crop',
            },
            {
              'id': 'veg_korma',
              'name': 'Vegetable Korma',
              'description': 'Mixed vegetables in mild cashew gravy',
              'price': 190.0,
              'image_url': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop',
            },
            {
              'id': 'palak_paneer',
              'name': 'Palak Paneer',
              'description': 'Spinach and cottage cheese curry',
              'price': 210.0,
              'image_url': 'https://images.unsplash.com/photo-1600628875733-8388985ca7b5?w=400&h=300&fit=crop',
            },
          ],
        },
        {
          'id': 'dinner_nonveg',
          'name': 'Non-Veg',
          'items': [
            {
              'id': 'butter_chicken',
              'name': 'Butter Chicken',
              'description': 'Chicken in rich tomato and cream sauce',
              'price': 320.0,
              'image_url': 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=400&h=300&fit=crop',
            },
            {
              'id': 'mutton_rogan_josh',
              'name': 'Mutton Rogan Josh',
              'description': 'Kashmiri-style mutton curry',
              'price': 350.0,
              'image_url': 'https://images.unsplash.com/photo-1574484284002-952d92456975?w=400&h=300&fit=crop',
            },
          ],
        },
        {
          'id': 'dinner_beverages',
          'name': 'Beverages',
          'items': [
            {
              'id': 'mineral_water',
              'name': 'Mineral Water',
              'description': 'Chilled mineral water',
              'price': 20.0,
              'image_url': 'https://images.unsplash.com/photo-1544148103-0773bf10d330?w=400&h=300&fit=crop',
            },
            {
              'id': 'soft_drink',
              'name': 'Soft Drink',
              'description': 'Assorted soft drinks',
              'price': 40.0,
              'image_url': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
            },
          ],
        },
      ],
    },
  ];

  // Create categories and menu items
  for (final categoryData in categories) {
    final categoryId = categoryData['id'] as String;
    final categoryName = categoryData['name'] as String;
    final subcategories = categoryData['subcategories'] as List;

    final menuItems = <Map<String, dynamic>>[];

    for (final subcategoryData in subcategories) {
      final subcategoryId = subcategoryData['id'] as String;
      final subcategoryName = subcategoryData['name'] as String;
      final items = subcategoryData['items'] as List;

      for (final itemData in items) {
        // Determine itemType based on subcategory
        String itemType = 'veg'; // default
        if (subcategoryName.toLowerCase() == 'non-veg') {
          itemType = 'nonveg';
        }

        menuItems.add({
          'id': itemData['id'],
          'name': itemData['name'],
          'description': itemData['description'],
          'price': itemData['price'],
          'image_url': itemData['image_url'],
          'subcategory': subcategoryName,
          'category': categoryName, // Add category field
          'itemType': itemType, // Add itemType field (veg/nonveg)
          'available': true,
        });
      }
    }

    // Save category to Firestore
    await firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('categories')
        .doc(categoryId)
        .set({
      'id': categoryId,
      'name': categoryName,
      'menu_items': menuItems,
    });
  }

  print('📋 Created categories with menu items');

  // 3. Create tables
  for (int i = 1; i <= 5; i++) {
    await firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('tables')
        .doc('table_$i')
        .set({
      'id': 'table_$i',
      'name': 'Table $i',
      'capacity': 4,
      'isAvailable': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  print('🪑 Created 5 tables (Table 1-5)');

  // 4. Create a demo guest session
  final guestId = uuid.v4();
  await firestore.collection('guest_sessions').doc(guestId).set({
    'guestId': guestId,
    'tenantId': tenantId,
    'createdAt': FieldValue.serverTimestamp(),
    'isActive': true,
  });

  print('👤 Created demo guest session: $guestId');

  // 5. Create some demo orders for testing
  await _createDemoOrders(firestore, tenantId, guestId);

  print('📋 Created demo orders for testing');
}

// Helper function to create demo orders
Future<void> _createDemoOrders(
    FirebaseFirestore firestore, String tenantId, String guestId) async {
  final now = DateTime.now();

  // Create a pending dine-in order
  await firestore
      .collection('tenants')
      .doc(tenantId)
      .collection('orders')
      .doc('demo_order_1')
      .set({
    'orderId': 'demo_order_1',
    'guestId': guestId,
    'tenantId': tenantId,
    'tableId': 'table_1',
    'type': 'dineIn',
    'status': 'pending',
    'items': [
      {
        'id': 'idli_sambar',
        'name': 'Idli Sambar',
        'price': 80.0,
        'quantity': 2,
      },
      {
        'id': 'filter_coffee',
        'name': 'Filter Coffee',
        'price': 40.0,
        'quantity': 1,
      },
    ],
    'timestamp': Timestamp.fromDate(now.subtract(const Duration(minutes: 10))),
    'estimatedWaitTime': 15,
    'subtotal': 200.0,
    'tax': 36.0,
    'total': 236.0,
  });

  // Create a preparing parcel order
  await firestore
      .collection('tenants')
      .doc(tenantId)
      .collection('orders')
      .doc('demo_order_2')
      .set({
    'orderId': 'demo_order_2',
    'guestId': guestId,
    'tenantId': tenantId,
    'type': 'parcel',
    'status': 'preparing',
    'items': [
      {
        'id': 'chicken_biryani',
        'name': 'Chicken Biryani',
        'price': 250.0,
        'quantity': 1,
      },
    ],
    'timestamp': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
    'estimatedWaitTime': 20,
    'subtotal': 250.0,
    'tax': 45.0,
    'total': 295.0,
  });

  print('📦 Created demo orders for testing');
}

/// Cleanup function to delete demo data
/// Uncomment and run this function to clean up demo data
Future<void> deleteDemoData() async {
  try {
    final firestore = FirebaseFirestore.instance;
    const tenantId = 'demo_tenant';

    // Delete all orders
    final ordersSnapshot = await firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('orders')
        .get();

    for (final doc in ordersSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete all categories
    final categoriesSnapshot = await firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('categories')
        .get();

    for (final doc in categoriesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete all tables
    final tablesSnapshot = await firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('tables')
        .get();

    for (final doc in tablesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete tenant
    await firestore.collection('tenants').doc(tenantId).delete();

    print('🗑️ Demo data deleted successfully');
  } catch (e) {
    print('❌ Error deleting demo data: $e');
  }
}
