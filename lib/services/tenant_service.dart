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

  /// Verify if a sessionId is still active and assigned to this table
  Future<bool> verifySession({
    required String tenantId,
    required String tableId,
    required String sessionId,
  }) async {
    try {
      final status = await getTableStatus(tenantId, tableId);
      if (status == null) return false;

      final isOccupied = status['isOccupied'] == true;
      final currentSessionId = status['currentSessionId'];
      final occupiedAt = status['occupiedAt'] as Timestamp?;

      if (!isOccupied || currentSessionId != sessionId) return false;

      // Check TTL (4 hours)
      if (occupiedAt != null) {
        final now = DateTime.now();
        final diff = now.difference(occupiedAt.toDate()).inHours;
        if (diff >= 4) {
          print('⚠️ Session $sessionId expired (TTL 4h)');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error verifying session: $e');
      return false;
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

          // TTL CHECK (4 hours fallback)
          final occupiedAt = data?['occupiedAt'] as Timestamp?;
          if (occupiedAt != null) {
            final diff = DateTime.now().difference(occupiedAt.toDate()).inHours;
            if (diff >= 4) {
              print('🔁 TTL expired (4h) for table $tableId. Allowing new lock.');
            } else {
              // Not expired yet -> strictly check orders
              final ordersSnapshot = await _firestore
                  .collection('tenants')
                  .doc(tenantId)
                  .collection('orders')
                  .where('tableId', isEqualTo: tableId)
                  .where('status', whereNotIn: ['completed', 'cancelled'])
                  .limit(1)
                  .get();

              if (ordersSnapshot.docs.isNotEmpty) {
                // Real active orders exist -> Block
                return false;
              }
              print('👻 Ghost state detected for table $tableId. Healing...');
            }
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
