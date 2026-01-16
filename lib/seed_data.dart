import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'models/tenant_model.dart';
import 'models/order.dart' as order_model;

/// Seed demo data for testing
class DataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String tenantId;
  
  DataSeeder(this.tenantId);

  Future<void> seedAll() async {
    print('🌱 Starting data seeding for tenant: $tenantId');
    
    await seedTables();
    await seedMenuItems();
    await seedOrders();
    
    print('✅ Data seeding completed!');
  }

  Future<void> seedTables() async {
    print('📊 Seeding tables...');
    
    final tables = [
      RestaurantTable(
        id: 'table_01',
        name: 'Table 1',
        section: 'Indoor',
        capacity: 4,
        isAvailable: true,
        status: 'available',
        orderIndex: 0,
      ),
      RestaurantTable(
        id: 'table_02',
        name: 'Table 2',
        section: 'Indoor',
        capacity: 2,
        isAvailable: true,
        status: 'available',
        orderIndex: 1,
      ),
      RestaurantTable(
        id: 'table_03',
        name: 'Table 3',
        section: 'Indoor',
        capacity: 6,
        isAvailable: true,
        status: 'available',
        orderIndex: 2,
      ),
      RestaurantTable(
        id: 'table_04',
        name: 'Table 4',
        section: 'Outdoor',
        capacity: 4,
        isAvailable: true,
        status: 'available',
        orderIndex: 3,
      ),
      RestaurantTable(
        id: 'table_05',
        name: 'Table 5',
        section: 'Outdoor',
        capacity: 4,
        isAvailable: true,
        status: 'available',
        orderIndex: 4,
      ),
      RestaurantTable(
        id: 'table_06',
        name: 'Table 6',
        section: 'Rooftop',
        capacity: 8,
        isAvailable: true,
        status: 'available',
        orderIndex: 5,
      ),
      RestaurantTable(
        id: 'table_07',
        name: 'Table 7',
        section: 'Rooftop',
        capacity: 4,
        isAvailable: false,
        status: 'occupied',
        isOccupied: true,
        occupiedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        orderIndex: 6,
      ),
      RestaurantTable(
        id: 'table_08',
        name: 'Table 8',
        section: 'VIP',
        capacity: 10,
        isAvailable: true,
        status: 'available',
        orderIndex: 7,
      ),
    ];

    final batch = _firestore.batch();
    for (final table in tables) {
      final ref = _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('tables')
          .doc(table.id);
      batch.set(ref, table.toMap());
    }
    await batch.commit();
    
    print('✅ Seeded ${tables.length} tables');
  }

  Future<void> seedMenuItems() async {
    print('🍽️ Seeding menu items...');
    
    final menuItems = [
      {
        'id': 'item_001',
        'name': 'Margherita Pizza',
        'description': 'Classic pizza with tomato sauce, mozzarella, and basil',
        'price': 299.0,
        'category': 'Main Course',
        'isAvailable': true,
        'imageUrl': 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002',
        'prepTime': 20,
        'isVeg': true,
      },
      {
        'id': 'item_002',
        'name': 'Chicken Biryani',
        'description': 'Aromatic basmati rice with tender chicken pieces',
        'price': 349.0,
        'category': 'Main Course',
        'isAvailable': true,
        'imageUrl': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8',
        'prepTime': 25,
        'isVeg': false,
      },
      {
        'id': 'item_003',
        'name': 'Caesar Salad',
        'description': 'Fresh romaine lettuce with Caesar dressing and croutons',
        'price': 199.0,
        'category': 'Starters',
        'isAvailable': true,
        'imageUrl': 'https://images.unsplash.com/photo-1546793665-c74683f339c1',
        'prepTime': 10,
        'isVeg': true,
      },
      {
        'id': 'item_004',
        'name': 'Butter Chicken',
        'description': 'Creamy tomato-based curry with tender chicken',
        'price': 399.0,
        'category': 'Main Course',
        'isAvailable': true,
        'imageUrl': 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398',
        'prepTime': 20,
        'isVeg': false,
      },
      {
        'id': 'item_005',
        'name': 'Paneer Tikka',
        'description': 'Grilled cottage cheese with Indian spices',
        'price': 249.0,
        'category': 'Starters',
        'isAvailable': true,
        'imageUrl': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8',
        'prepTime': 15,
        'isVeg': true,
      },
      {
        'id': 'item_006',
        'name': 'Chocolate Brownie',
        'description': 'Warm chocolate brownie with vanilla ice cream',
        'price': 149.0,
        'category': 'Desserts',
        'isAvailable': true,
        'imageUrl': 'https://images.unsplash.com/photo-1607920591413-4ec007e70023',
        'prepTime': 5,
        'isVeg': true,
      },
      {
        'id': 'item_007',
        'name': 'Fresh Lime Soda',
        'description': 'Refreshing lime soda with mint',
        'price': 79.0,
        'category': 'Beverages',
        'isAvailable': true,
        'imageUrl': 'https://images.unsplash.com/photo-1556679343-c7306c1976bc',
        'prepTime': 5,
        'isVeg': true,
      },
      {
        'id': 'item_008',
        'name': 'Masala Dosa',
        'description': 'Crispy rice crepe with spiced potato filling',
        'price': 129.0,
        'category': 'Main Course',
        'isAvailable': true,
        'imageUrl': 'https://images.unsplash.com/photo-1630383249896-424e482df921',
        'prepTime': 15,
        'isVeg': true,
      },
    ];

    final batch = _firestore.batch();
    for (final item in menuItems) {
      final ref = _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('menuItems')
          .doc(item['id'] as String);
      batch.set(ref, item);
    }
    await batch.commit();
    
    print('✅ Seeded ${menuItems.length} menu items');
  }

  Future<void> seedOrders() async {
    print('📦 Seeding orders...');
    
    final now = DateTime.now();
    const uuid = Uuid();
    
    // Order 1: Active order for Table 7 (Occupied)
    final order1 = order_model.Order(
      id: uuid.v4(),
      tenantId: tenantId,
      tableId: 'table_07',
      tableName: 'Table 7',
      items: [
        order_model.OrderItem(
          id: uuid.v4(),
          menuItemId: 'item_002',
          name: 'Chicken Biryani',
          price: 349.0,
          quantity: 2,
          status: order_model.OrderItemStatus.preparing,
        ),
        order_model.OrderItem(
          id: uuid.v4(),
          menuItemId: 'item_005',
          name: 'Paneer Tikka',
          price: 249.0,
          quantity: 1,
          status: order_model.OrderItemStatus.preparing,
        ),
        order_model.OrderItem(
          id: uuid.v4(),
          menuItemId: 'item_007',
          name: 'Fresh Lime Soda',
          price: 79.0,
          quantity: 2,
          status: order_model.OrderItemStatus.served,
          servedAt: now.subtract(const Duration(minutes: 10)),
        ),
      ],
      subtotal: 1026.0,
      tax: 51.3,
      total: 1077.3,
      status: order_model.OrderStatus.preparing,
      paymentStatus: order_model.PaymentStatus.pending,
      createdAt: now.subtract(const Duration(minutes: 45)),
      estimatedWaitTime: 25,
    );

    // Order 2: Pending order for Table 3
    final order2 = order_model.Order(
      id: uuid.v4(),
      tenantId: tenantId,
      tableId: 'table_03',
      tableName: 'Table 3',
      items: [
        order_model.OrderItem(
          id: uuid.v4(),
          menuItemId: 'item_001',
          name: 'Margherita Pizza',
          price: 299.0,
          quantity: 1,
          status: order_model.OrderItemStatus.pending,
        ),
        order_model.OrderItem(
          id: uuid.v4(),
          menuItemId: 'item_003',
          name: 'Caesar Salad',
          price: 199.0,
          quantity: 2,
          status: order_model.OrderItemStatus.pending,
        ),
      ],
      subtotal: 697.0,
      tax: 34.85,
      total: 731.85,
      status: order_model.OrderStatus.pending,
      paymentStatus: order_model.PaymentStatus.pending,
      createdAt: now.subtract(const Duration(minutes: 5)),
      estimatedWaitTime: 20,
    );

    // Order 3: Ready order for Table 4
    final order3 = order_model.Order(
      id: uuid.v4(),
      tenantId: tenantId,
      tableId: 'table_04',
      tableName: 'Table 4',
      items: [
        order_model.OrderItem(
          id: uuid.v4(),
          menuItemId: 'item_004',
          name: 'Butter Chicken',
          price: 399.0,
          quantity: 2,
          status: order_model.OrderItemStatus.ready,
        ),
        order_model.OrderItem(
          id: uuid.v4(),
          menuItemId: 'item_008',
          name: 'Masala Dosa',
          price: 129.0,
          quantity: 1,
          status: order_model.OrderItemStatus.ready,
        ),
      ],
      subtotal: 927.0,
      tax: 46.35,
      total: 973.35,
      status: order_model.OrderStatus.ready,
      paymentStatus: order_model.PaymentStatus.pending,
      createdAt: now.subtract(const Duration(minutes: 30)),
      estimatedWaitTime: 20,
    );

    // Order 4: Completed order from earlier today
    final order4 = order_model.Order(
      id: uuid.v4(),
      tenantId: tenantId,
      tableId: 'table_01',
      tableName: 'Table 1',
      items: [
        order_model.OrderItem(
          id: uuid.v4(),
          menuItemId: 'item_001',
          name: 'Margherita Pizza',
          price: 299.0,
          quantity: 2,
          status: order_model.OrderItemStatus.served,
          servedAt: now.subtract(const Duration(hours: 2)),
        ),
        order_model.OrderItem(
          id: uuid.v4(),
          menuItemId: 'item_006',
          name: 'Chocolate Brownie',
          price: 149.0,
          quantity: 2,
          status: order_model.OrderItemStatus.served,
          servedAt: now.subtract(const Duration(hours: 2)),
        ),
      ],
      subtotal: 896.0,
      tax: 44.8,
      total: 940.8,
      status: order_model.OrderStatus.completed,
      paymentStatus: order_model.PaymentStatus.paid,
      createdAt: now.subtract(const Duration(hours: 3)),
      closedAt: now.subtract(const Duration(hours: 2)),
      estimatedWaitTime: 20,
    );

    final orders = [order1, order2, order3, order4];
    
    final batch = _firestore.batch();
    for (final order in orders) {
      final ref = _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('orders')
          .doc(order.id);
      batch.set(ref, order.toMap());
    }
    await batch.commit();
    
    // Update table statuses for occupied tables
    await _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('tables')
        .doc('table_03')
        .update({
      'isOccupied': true,
      'isAvailable': false,
      'status': 'occupied',
      'occupiedAt': order2.createdAt,
    });
    
    await _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('tables')
        .doc('table_04')
        .update({
      'isOccupied': true,
      'isAvailable': false,
      'status': 'occupied',
      'occupiedAt': order3.createdAt,
    });
    
    print('✅ Seeded ${orders.length} orders');
  }

  /// Clear all data for the tenant (use with caution!)
  Future<void> clearAll() async {
    print('🗑️ Clearing all data for tenant: $tenantId');
    
    // Clear tables
    final tablesSnapshot = await _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('tables')
        .get();
    
    final batch1 = _firestore.batch();
    for (final doc in tablesSnapshot.docs) {
      batch1.delete(doc.reference);
    }
    await batch1.commit();
    
    // Clear menu items
    final menuSnapshot = await _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('menuItems')
        .get();
    
    final batch2 = _firestore.batch();
    for (final doc in menuSnapshot.docs) {
      batch2.delete(doc.reference);
    }
    await batch2.commit();
    
    // Clear orders
    final ordersSnapshot = await _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('orders')
        .get();
    
    final batch3 = _firestore.batch();
    for (final doc in ordersSnapshot.docs) {
      batch3.delete(doc.reference);
    }
    await batch3.commit();
    
    print('✅ Cleared all data');
  }
}
