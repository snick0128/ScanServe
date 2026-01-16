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
}
