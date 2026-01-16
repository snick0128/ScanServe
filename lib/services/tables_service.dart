import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tenant_model.dart';

class TablesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<RestaurantTable>> getTables(String tenantId) async {
    try {
      final snapshot = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('tables')
          .orderBy('orderIndex')
          .get();

      return snapshot.docs
          .map((doc) => RestaurantTable.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching tables: $e');
      return [];
    }
  }

  Stream<List<RestaurantTable>> getTablesStream(String tenantId) {
    print('🔥 TablesService: Setting up stream for tenant: $tenantId');
    
    // DON'T use orderBy - it requires an index and fails silently
    // Instead, fetch all tables and sort in memory
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('tables')
        .snapshots()
        .map((snapshot) {
          print('📊 TablesService: Received ${snapshot.docs.length} table documents');
          
          final tables = <RestaurantTable>[];
          for (var doc in snapshot.docs) {
            try {
              print('  - Processing table: ${doc.id}');
              final table = RestaurantTable.fromMap(doc.data(), doc.id);
              tables.add(table);
              print('    ✅ Parsed: ${table.name}');
            } catch (e) {
              print('    ❌ Error parsing table ${doc.id}: $e');
              print('    Data: ${doc.data()}');
            }
          }
          
          // Sort by orderIndex in memory
          tables.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          
          print('📊 TablesService: Returning ${tables.length} parsed tables');
          return tables;
        });
  }

  Future<void> addTable(String tenantId, RestaurantTable table) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('tables')
          .doc(table.id)
          .set(table.toMap());
    } catch (e) {
      print('Error adding table: $e');
      rethrow;
    }
  }

  Future<void> updateTable(String tenantId, RestaurantTable table) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('tables')
          .doc(table.id)
          .update(table.toMap());
    } catch (e) {
      print('Error updating table: $e');
      rethrow;
    }
  }

  Future<void> deleteTable(String tenantId, String tableId) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('tables')
          .doc(tableId)
          .delete();
    } catch (e) {
      print('Error deleting table: $e');
      rethrow;
    }
  }
}
