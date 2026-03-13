import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_order.dart';
import '../models/inventory_log.dart';
import '../services/inventory_service.dart';
import '../services/vendor_service.dart';

class PurchaseOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InventoryService _inventoryService = InventoryService();
  final VendorService _vendorService = VendorService();

  CollectionReference<Map<String, dynamic>> _poRef(String tenantId) =>
      _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('purchase_orders');

  Stream<List<PurchaseOrder>> watchPurchaseOrders(String tenantId) {
    return _poRef(tenantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((d) => PurchaseOrder.fromFirestore(d)).toList(),
        );
  }

  Future<void> createPurchaseOrder(String tenantId, PurchaseOrder po) async {
    final doc = _poRef(tenantId).doc();
    await doc.set(po.copyWith(id: doc.id).toMap());
  }

  Future<void> updateStatus(String tenantId, String poId, String status) async {
    await _poRef(tenantId).doc(poId).update({
      'status': status,
      if (status == 'received') 'receivedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> receivePurchaseOrder({
    required String tenantId,
    required PurchaseOrder po,
    required String receivedBy,
  }) async {
    if (po.status == 'received' || po.status == 'closed') return;

    // 1) Update stock for each item
    for (final item in po.items) {
      await _inventoryService.updateStock(
        tenantId: tenantId,
        itemId: item.itemId,
        quantityChange: item.quantity,
        type: InventoryChangeType.stockIn,
        reason: InventoryChangeReason.purchase,
        performedBy: receivedBy,
        sourceId: 'PO: ${po.id.substring(0, 8)}',
      );
    }

    // 2) Mark PO received
    await _poRef(tenantId).doc(po.id).update({
      'status': 'received',
      'receivedAt': FieldValue.serverTimestamp(),
    });

    // 3) Add vendor ledger debit
    await _vendorService.adjustVendorBalance(
      tenantId: tenantId,
      vendorId: po.vendorId,
      amount: po.totalAmount,
      type: 'debit',
      note: 'Purchase Order ${po.id.substring(0, 8)}',
      referenceId: po.id,
    );
  }
}
