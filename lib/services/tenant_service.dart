import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tenant_model.dart';

class TenantService {
  final _firestore = FirebaseFirestore.instance;

  Future<Tenant?> getTenantInfo(String tenantId) async {
    try {
      final docSnapshot = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return Tenant.fromFirestore(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    } catch (e) {
      print('Error fetching tenant info: $e');
      return null;
    }
  }


  /// Verify if a table exists for a tenant
  Future<bool> verifyTableExists(String tenantId, String tableId) async {
    try {
      final docSnapshot = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('tables')
          .doc(tableId)
          .get();

      return docSnapshot.exists;
    } catch (e) {
      print('Error verifying table existence: $e');
      return false;
    }
  }

  /// Get table status (occupied, current session)
  Future<Map<String, dynamic>?> getTableStatus(String tenantId, String tableId) async {
    try {
      final docSnapshot = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('tables')
          .doc(tableId)
          .get();

      if (!docSnapshot.exists) return null;
      return docSnapshot.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error getting table status: $e');
      return null;
    }
  }

  /// Attempt to lock the table for the current session
  /// Returns true if successful or if already locked by THIS session
  /// Returns false if locked by ANOTHER session
  Future<bool> lockTable(String tenantId, String tableId, String sessionId) async {
    final tableRef = _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('tables')
        .doc(tableId);

    try {
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(tableRef);
        
        if (!snapshot.exists) return false;
        
        final data = snapshot.data();
        final isOccupied = data?['isOccupied'] == true; // Robust bool check
        final isAvailable = data?['isAvailable'] != false; // Robust bool check
        final currentSession = data?['currentSessionId'];

        // Block if ALREADY occupied by someone else, or if NOT available
        if (isOccupied || !isAvailable) {
          // If occupied by SAME session, allow re-entry
          if (currentSession == sessionId) {
            return true;
          }

          // ROBUST CHECK: Is there actually an active order for this table?
          // If the admin panel is closed, the 'healing' logic doesn't run.
          // We check the orders collection here.
          final ordersSnapshot = await _firestore
              .collection('tenants')
              .doc(tenantId)
              .collection('orders')
              .where('tableId', isEqualTo: tableId)
              .where('status', whereNotIn: ['completed', 'cancelled'])
              .limit(1)
              .get();

          if (ordersSnapshot.docs.isEmpty) {
            // No active orders found! This is a ghost state. Heal it.
            print('👻 Ghost state detected for table $tableId. Healing...');
          } else {
             // Real orders exist -> Block
             return false;
          }
        }

        // Not occupied or Ghost State -> Lock it
        transaction.update(tableRef, {
          'isOccupied': true,
          'currentSessionId': sessionId,
          'status': 'occupied',
          'isAvailable': false,
          'occupiedAt': FieldValue.serverTimestamp(),
        });
        
        return true;
      });
    } catch (e) {
      print('Error locking table: $e');
      return false;
    }
  }

  Future<bool> unlockTable(String tenantId, String tableId) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('tables')
          .doc(tableId)
          .update({
        'isOccupied': false,
        'currentSessionId': null,
        'status': 'available',
        'isAvailable': true,
        'occupiedAt': null,
        'lastReleasedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error unlocking table: $e');
      return false;
    }
  }
}
