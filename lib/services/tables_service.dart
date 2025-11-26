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
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => RestaurantTable.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching tables: $e');
      return [];
    }
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
