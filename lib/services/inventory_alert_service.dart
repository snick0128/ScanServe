import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/low_stock_alert.dart';

class InventoryAlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _alertRef(String tenantId) =>
      _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('inventory_alerts');

  Stream<List<LowStockAlert>> watchAlerts(String tenantId) {
    return _alertRef(tenantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((d) => LowStockAlert.fromFirestore(d)).toList(),
        );
  }

  Future<void> createAlertIfNeeded({
    required String tenantId,
    required String itemId,
    required String itemName,
    required String status,
    required double currentStock,
    required String unit,
  }) async {
    final existing = await _alertRef(tenantId)
        .where('itemId', isEqualTo: itemId)
        .where('status', isEqualTo: status)
        .where('acknowledged', isEqualTo: false)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return;

    final doc = _alertRef(tenantId).doc();
    final alert = LowStockAlert(
      id: doc.id,
      itemId: itemId,
      itemName: itemName,
      status: status,
      currentStock: currentStock,
      unit: unit,
      acknowledged: false,
      createdAt: DateTime.now(),
    );
    await doc.set(alert.toMap());
  }

  Future<void> acknowledgeAlert(String tenantId, String alertId) async {
    await _alertRef(tenantId).doc(alertId).update({
      'acknowledged': true,
      'acknowledgedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markWhatsappSent(String tenantId, String alertId) async {
    await _alertRef(tenantId).doc(alertId).update({'whatsappSent': true});
  }
}
