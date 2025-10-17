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
}
