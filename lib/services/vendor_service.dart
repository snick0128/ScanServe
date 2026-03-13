import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vendor.dart';
import '../models/vendor_ledger_entry.dart';

class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _vendorRef(String tenantId) =>
      _firestore.collection('tenants').doc(tenantId).collection('vendors');

  CollectionReference<Map<String, dynamic>> _ledgerRef(String tenantId) =>
      _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('vendor_ledger');

  Stream<List<Vendor>> watchVendors(String tenantId) {
    return _vendorRef(tenantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((d) => Vendor.fromFirestore(d)).toList(),
        );
  }

  Stream<List<VendorLedgerEntry>> watchLedger(String tenantId) {
    return _ledgerRef(tenantId)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => VendorLedgerEntry.fromFirestore(d))
              .toList(),
        );
  }

  Future<void> addVendor(String tenantId, Vendor vendor) async {
    final doc = _vendorRef(tenantId).doc();
    await doc.set(vendor.copyWith(id: doc.id).toMap());
  }

  Future<void> updateVendor(String tenantId, Vendor vendor) async {
    await _vendorRef(tenantId).doc(vendor.id).update(vendor.toMap());
  }

  Future<void> adjustVendorBalance({
    required String tenantId,
    required String vendorId,
    required double amount,
    required String type, // debit | credit
    required String note,
    String? referenceId,
  }) async {
    final vendorDoc = _vendorRef(tenantId).doc(vendorId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(vendorDoc);
      if (!snapshot.exists) throw Exception('Vendor not found');
      final data = snapshot.data() as Map<String, dynamic>;
      final currentBalance = (data['currentBalance'] ?? 0).toDouble();
      final updatedBalance = type == 'debit'
          ? currentBalance + amount
          : currentBalance - amount;

      transaction.update(vendorDoc, {'currentBalance': updatedBalance});

      final ledgerRef = _ledgerRef(tenantId).doc();
      final entry = VendorLedgerEntry(
        id: '',
        vendorId: vendorId,
        type: type,
        amount: amount,
        referenceId: referenceId,
        note: note,
        createdAt: DateTime.now(),
      );
      transaction.set(ledgerRef, entry.toMap());
    });
  }
}
