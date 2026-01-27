import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:uuid/uuid.dart';

/// Script to seed menu items for "Ghar jesa khana"
/// Run with: flutter run -d chrome -t lib/create_ghar_jesa_khana.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('🔥 Firebase initialized');

    final firestore = FirebaseFirestore.instance;
    const tenantId = 'ghar-jesa-khana';
    const uuid = Uuid();

    // Data Structure
    final categories = [
      {
        'name': 'Main Course',
        'subcategories': [
          {
            'name': 'Kofta Main Course',
            'items': [
              {'name': 'Kaju Kofta', 'variants': {'250GM': 199, '500GM': 389, '750GM': 579, '1KG': 759}, 'price': 199},
              {'name': 'Malai Kofta', 'variants': {'250GM': 179, '500GM': 349, '750GM': 529, '1KG': 699}, 'price': 179},
              {'name': 'Paneer Kofta', 'variants': {'250GM': 179, '500GM': 349, '750GM': 529, '1KG': 699}, 'price': 179},
              {'name': 'Veg Kofta', 'variants': {'250GM': 179, '500GM': 349, '750GM': 529, '1KG': 699}, 'price': 179},
              {'name': 'Cheese Anguri Kofta', 'variants': {'250GM': 199, '500GM': 389, '750GM': 579, '1KG': 759}, 'price': 199},
            ]
          },
          {
            'name': 'Kaju Main Course',
            'items': [
              {'name': 'Khoya Kaju (Sweet)', 'variants': {'250GM': 199, '500GM': 389, '750GM': 579, '1KG': 759}, 'price': 199},
              {'name': 'Kaju Curry', 'variants': {'250GM': 199, '500GM': 389, '750GM': 579, '1KG': 759}, 'price': 199},
              {'name': 'Kaju Butter Masala', 'variants': {'250GM': 199, '500GM': 389, '750GM': 579, '1KG': 759}, 'price': 199},
              {'name': 'Kaju Paneer Masala', 'variants': {'250GM': 199, '500GM': 389, '750GM': 579, '1KG': 759}, 'price': 199},
            ]
          },
          {
            'name': 'Vegetable Main Course',
            'items': [
              {'name': 'Veg Angara', 'variants': {'250GM': 149, '500GM': 289, '750GM': 429, '1KG': 579}, 'price': 149},
              {'name': 'Veg Toofani', 'variants': {'250GM': 149, '500GM': 289, '750GM': 429, '1KG': 579}, 'price': 149},
              {'name': 'Veg Tawa Masala', 'variants': {'250GM': 149, '500GM': 289, '750GM': 429, '1KG': 579}, 'price': 149},
              {'name': 'Veg Kadai', 'variants': {'250GM': 149, '500GM': 289, '750GM': 429, '1KG': 579}, 'price': 149},
              {'name': 'Veg Handi', 'variants': {'250GM': 149, '500GM': 289, '750GM': 429, '1KG': 579}, 'price': 149},
              {'name': 'Veg Jaipuri', 'variants': {'250GM': 149, '500GM': 289, '750GM': 429, '1KG': 579}, 'price': 149},
              {'name': 'Veg Hydrabadi', 'variants': {'250GM': 149, '500GM': 289, '750GM': 429, '1KG': 579}, 'price': 149},
              {'name': 'Veg Kolhapuri', 'variants': {'250GM': 149, '500GM': 289, '750GM': 429, '1KG': 579}, 'price': 149},
              {'name': 'Veg Makhanwala', 'variants': {'250GM': 149, '500GM': 289, '750GM': 429, '1KG': 579}, 'price': 149},
              {'name': 'Veg Shahi Korma', 'variants': {'250GM': 149, '500GM': 289, '750GM': 429, '1KG': 579}, 'price': 149},
              {'name': 'Veg Diwani Handi', 'variants': {'250GM': 149, '500GM': 289, '750GM': 429, '1KG': 579}, 'price': 149},
              {'name': 'Veg Chatpata', 'variants': {'250GM': 149, '500GM': 289, '750GM': 429, '1KG': 579}, 'price': 149},
              {'name': 'Mix Veg', 'variants': {'250GM': 110, '500GM': 209, '750GM': 319, '1KG': 429}, 'price': 110},
              {'name': 'Chana Masala', 'variants': {'250GM': 110, '500GM': 209, '750GM': 319, '1KG': 429}, 'price': 110},
              {'name': 'Sev Tomato', 'variants': {'250GM': 110, '500GM': 209, '750GM': 319, '1KG': 429}, 'price': 110},
              {'name': 'Lasaniya Bataka', 'variants': {'250GM': 110, '500GM': 209, '750GM': 319, '1KG': 429}, 'price': 110},
              {'name': 'Jeera Aloo / Sukhi Bhaji', 'variants': {'250GM': 110, '500GM': 209, '750GM': 319, '1KG': 429}, 'price': 110},
              {'name': 'Plain Palak', 'variants': {'250GM': 110, '500GM': 209, '750GM': 319, '1KG': 429}, 'price': 110},
              {'name': 'Aloo Palak / Mutter Palak', 'variants': {'250GM': 110, '500GM': 209, '750GM': 319, '1KG': 429}, 'price': 110},
              {'name': 'Dal Fry Tadka', 'variants': {'250GM': 110, '500GM': 209, '750GM': 310, '1KG': 429}, 'price': 110},
              {'name': 'Dal Fry Butter', 'variants': {'250GM': 110, '500GM': 209, '750GM': 310, '1KG': 429}, 'price': 110},
              {'name': 'Dal Fry', 'variants': {'250GM': 99, '500GM': 199, '750GM': 279, '1KG': 399}, 'price': 99},
            ]
          },
          {
            'name': 'Paneer Main Course',
            'items': [
              {'name': 'Paneer Tikka Masala', 'variants': {'250GM': 169, '500GM': 379, '750GM': 579, '1KG': 699}, 'price': 169},
              {'name': 'Paneer Butter Masala', 'variants': {'250GM': 169, '500GM': 379, '750GM': 579, '1KG': 699}, 'price': 169},
              {'name': 'Paneer Angara', 'variants': {'250GM': 169, '500GM': 379, '750GM': 579, '1KG': 699}, 'price': 169},
              {'name': 'Paneer Toofani', 'variants': {'250GM': 169, '500GM': 379, '750GM': 579, '1KG': 699}, 'price': 169},
              {'name': 'Paneer Tawa Masala', 'variants': {'250GM': 169, '500GM': 379, '750GM': 579, '1KG': 699}, 'price': 169},
              {'name': 'Paneer Handi', 'variants': {'250GM': 169, '500GM': 379, '750GM': 579, '1KG': 675}, 'price': 169},
              {'name': 'Paneer Kadai', 'variants': {'250GM': 169, '500GM': 379, '750GM': 579, '1KG': 675}, 'price': 169},
              {'name': 'Paneer Bhurji', 'variants': {'250GM': 169, '500GM': 379, '750GM': 579, '1KG': 675}, 'price': 169},
              {'name': 'Paneer Pasanda', 'variants': {'250GM': 169, '500GM': 379, '750GM': 579, '1KG': 675}, 'price': 169},
              {'name': 'Paneer Kolhapuri', 'variants': {'250GM': 169, '500GM': 379, '750GM': 579, '1KG': 675}, 'price': 169},
              {'name': 'Shahi Paneer', 'variants': {'250GM': 169, '500GM': 379, '750GM': 579, '1KG': 675}, 'price': 169},
              {'name': 'Paneer Lababdar', 'variants': {'250GM': 169, '500GM': 379, '750GM': 579, '1KG': 675}, 'price': 169},
              {'name': 'Paneer Pahadi', 'variants': {'250GM': 169, '500GM': 379, '750GM': 579, '1KG': 675}, 'price': 169},
              {'name': 'Paneer Chatpata', 'variants': {'250GM': 169, '500GM': 379, '750GM': 579, '1KG': 675}, 'price': 169},
              {'name': 'Paneer Hara Masala', 'variants': {'250GM': 169, '500GM': 379, '750GM': 579, '1KG': 675}, 'price': 169},
              {'name': 'Palak Paneer', 'variants': {'250GM': 159, '500GM': 379, '750GM': 579, '1KG': 650}, 'price': 159},
              {'name': 'Mutter Paneer', 'variants': {'250GM': 159, '500GM': 379, '750GM': 579, '1KG': 650}, 'price': 159},
              {'name': 'Chana Paneer', 'variants': {'250GM': 159, '500GM': 379, '750GM': 579, '1KG': 650}, 'price': 159},
            ]
          }
        ]
      },
      {
        'name': 'Breads',
        'subcategories': [
          {
            'name': null,
            'items': [
              {'name': 'Plain Tandoori Roti', 'price': 20},
              {'name': 'Butter Tandoori Roti', 'price': 25},
              {'name': 'Plain Tandoori Paratha', 'price': 35},
              {'name': 'Butter Tandoori Paratha', 'price': 40},
              {'name': 'Lachha Paratha', 'price': 48},
              {'name': 'Plain Naan', 'price': 48},
              {'name': 'Butter Naan', 'price': 55},
              {'name': 'Cheese Naan', 'price': 85},
              {'name': 'Stuff Naan', 'price': 85},
              {'name': 'Cheese Chilly Garlic Naan', 'price': 120},
              {'name': 'Plain Kulcha', 'price': 50},
              {'name': 'Butter Kulcha', 'price': 60},
              {'name': 'Plain Chapati', 'price': 12},
              {'name': 'Butter Chapati', 'price': 18},
              {'name': 'Chapati Paratha', 'price': 28},
              {'name': 'Butter Chapati Paratha', 'price': 35},
              {'name': 'Poori', 'price': 20},
            ]
          }
        ]
      },
      {
        'name': 'Rice',
        'subcategories': [
          {
            'name': null,
            'items': [
              {'name': 'Plain Rice', 'price': 90},
              {'name': 'Steam Rice', 'price': 100},
              {'name': 'Jeera Rice', 'price': 120},
              {'name': 'Veg Pulao', 'price': 179},
              {'name': 'Peas Pulao', 'price': 179},
              {'name': 'Kaju Pulao', 'price': 199},
              {'name': 'Veg Biryani with Raitu', 'price': 199},
              {'name': 'Kaju Paneer Pulao', 'price': 199},
              {'name': 'Hydrabadi Biryani with Raitu', 'price': 199},
            ]
          }
        ]
      },
      {
        'name': 'Thali',
        'subcategories': [
          {
            'name': null,
            'items': [
              {'name': 'Gujarati Thali', 'price': 149, 'description': '2 Sabji / Dal / Bhat / 4 Butter Chapati / Salad / Pickle'},
              {'name': 'Gujarati Thali Delux', 'price': 189, 'description': '2 Sabji / Dal / Bhat / 4 Butter Chapati / Salad / Pickle / Butter Milk / Sweet'},
              {'name': 'Punjabi Thali', 'price': 199, 'description': 'Sabji / Jeera Rice / Salad / Papad / (3 Butter Tandoori OR 5 Butter Chapati)'},
              {'name': 'Punjabi Delux', 'price': 249, 'description': 'Sp. Veg / Sp. Paneer / Jeera Rice / Dal Fry / Papad / Butter Milk / Salad / Sweet'},
            ]
          }
        ]
      },
      {
        'name': 'Extras',
        'subcategories': [
          {
            'name': null,
             'items': [
                {'name': 'Kathod Sabji', 'price': 30},
                {'name': 'Hari Sabji', 'price': 30},
                {'name': 'Dal', 'price': 25},
                {'name': 'Bhat', 'price': 30},
                {'name': 'Butter Milk', 'price': 20},
                {'name': 'Sweet', 'price': 30},
                {'name': 'Shrikhand', 'price': 30},
                {'name': 'Chapati', 'price': 10},
                {'name': 'Papad', 'price': 10},
                {'name': 'Veg Regular Sabji', 'price': 35},
                {'name': 'Sp. Veg Sabji', 'price': 45},
                {'name': 'Sp. Paneer Sabji', 'price': 50},
                {'name': 'Dal Fry', 'price': 40},
                {'name': 'Jeera Rice', 'price': 40},
             ]
          }
        ]
      },
    ];

    print('🚀 Starting seed for Tenant: $tenantId');
    int totalItems = 0;

    // Process Categories
    for (var catData in categories) {
      final categoryName = catData['name'] as String;
      final categoryId = categoryName.toLowerCase().replaceAll(' ', '_');

      // Create Category Document
      await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('categories')
          .doc(categoryId)
          .set({
        'id': categoryId,
        'name': categoryName,
        'menu_items': [], // Placeholder, items are sub-docs in logic but array in model?
        // NOTE: Tenant model expects items inside category map OR subcollection?
        // Let's stick to adding them to the subcollection as per Model usage:
        // Category.fromMap uses 'menu_items' array.
        // BUT MenuService queries collection 'menu_items'.
        // Let's assume we populate the top-level 'menu_items' collection for items,
        // AND maybe update the category document with a list if required.
        // Actually best practice here based on the app seems to be all items in one collection 
        // with 'category' field. The Category doc is just for metadata.
      });

      print('📂 Processing Category: $categoryName');

      final subcats = catData['subcategories'] as List;
      for (var subcat in subcats) {
        final subcatName = subcat['name'] as String?;
        final items = subcat['items'] as List;

        for (var item in items) {
          final itemId = uuid.v4();
          final hasVariants = item.containsKey('variants');
          
          List<Map<String, dynamic>> variantsList = [];
          if (hasVariants) {
            final vMap = item['variants'] as Map<String, int>;
            vMap.forEach((k, v) {
              variantsList.add({
                'name': k,
                'price': v.toDouble(),
                'isAvailable': true
              });
            });
          }

          final menuItem = {
            'id': itemId,
            'name': item['name'],
            'description': item['description'] ?? '',
            'price': (item['price'] as num).toDouble(),
            'image_url': null,
            'category': categoryName,
            'subcategory': subcatName,
            'itemType': 'veg',
            'stockCount': 0,
            'isTracked': false,
            'isManualAvailable': true,
            'inventoryTrackingType': 'none',
            'inventoryIngredients': {},
            'isBestseller': false,
            'hasVariants': hasVariants,
            'variants': variantsList,
          };

          // Add to 'menu_items' subcollection of tenant? Or global?
          // Looking at MenuService: tenantRef.collection('menu_items')
          await firestore
              .collection('tenants')
              .doc(tenantId)
              .collection('menu_items')
              .doc(itemId)
              .set(menuItem);

          // Also need to push to Category 'menu_items' array? 
          // TenantModel Category.fromMap reads 'menu_items'.
          // MenuService.fetchCategories fetches from 'categories' collection.
          // IF the app relies on 'categories' collection containing items array, we update it.
          await firestore
              .collection('tenants')
              .doc(tenantId)
              .collection('categories')
              .doc(categoryId)
              .update({
            'menu_items': FieldValue.arrayUnion([menuItem])
          });

          totalItems++;
          print('   - Added ${item['name']} [${hasVariants ? 'Variants: ${variantsList.length}' : 'Regular'}]');
        }
      }
    }

    print('\n✅ SEED COMPLETE: Inserted $totalItems items.');
    exitWidget();
  } catch (e) {
    print('❌ ERROR: $e');
  }
}

void exitWidget() {
  // Just to exit the flutter run process cleanly if possible, or user can Ctrl+C
  print('press "q" to quit in terminal');
}
