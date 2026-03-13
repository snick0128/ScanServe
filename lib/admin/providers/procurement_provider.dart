import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/vendor.dart';
import '../../models/vendor_ledger_entry.dart';
import '../../models/purchase_order.dart';
import '../../models/low_stock_alert.dart';
import '../../models/inventory_item.dart';
import '../../services/vendor_service.dart';
import '../../services/purchase_order_service.dart';
import '../../services/inventory_alert_service.dart';
import '../../services/inventory_service.dart';

class ProcurementProvider with ChangeNotifier {
  final VendorService _vendorService = VendorService();
  final PurchaseOrderService _poService = PurchaseOrderService();
  final InventoryAlertService _alertService = InventoryAlertService();
  final InventoryService _inventoryService = InventoryService();

  String? _tenantId;
  bool _isLoading = false;

  List<Vendor> _vendors = [];
  List<VendorLedgerEntry> _ledger = [];
  List<PurchaseOrder> _orders = [];
  List<LowStockAlert> _alerts = [];

  StreamSubscription? _vendorSub;
  StreamSubscription? _ledgerSub;
  StreamSubscription? _poSub;
  StreamSubscription? _alertSub;

  bool _alertSyncPending = false;

  List<Vendor> get vendors => _vendors;
  List<VendorLedgerEntry> get ledger => _ledger;
  List<PurchaseOrder> get purchaseOrders => _orders;
  List<LowStockAlert> get alerts => _alerts;
  bool get isLoading => _isLoading;

  void initialize(String tenantId) {
    if (_tenantId == tenantId) return;
    _tenantId = tenantId;
    _isLoading = true;
    notifyListeners();
    _disposeStreams();
    _listen();
  }

  void _listen() {
    if (_tenantId == null) return;

    _vendorSub = _vendorService.watchVendors(_tenantId!).listen((data) {
      _vendors = data;
      _isLoading = false;
      notifyListeners();
    });

    _ledgerSub = _vendorService.watchLedger(_tenantId!).listen((data) {
      _ledger = data;
      notifyListeners();
    });

    _poSub = _poService.watchPurchaseOrders(_tenantId!).listen((data) {
      _orders = data;
      notifyListeners();
    });

    _alertSub = _alertService.watchAlerts(_tenantId!).listen((data) {
      _alerts = data;
      notifyListeners();
    });
  }

  void _disposeStreams() {
    _vendorSub?.cancel();
    _ledgerSub?.cancel();
    _poSub?.cancel();
    _alertSub?.cancel();
  }

  Future<void> addVendor(Vendor vendor) async {
    if (_tenantId == null) return;
    await _vendorService.addVendor(_tenantId!, vendor);
  }

  Future<void> updateVendor(Vendor vendor) async {
    if (_tenantId == null) return;
    await _vendorService.updateVendor(_tenantId!, vendor);
  }

  Future<void> recordVendorPayment({
    required String vendorId,
    required double amount,
    required String note,
    String? referenceId,
  }) async {
    if (_tenantId == null) return;
    await _vendorService.adjustVendorBalance(
      tenantId: _tenantId!,
      vendorId: vendorId,
      amount: amount,
      type: 'credit',
      note: note,
      referenceId: referenceId,
    );
  }

  Future<void> createPurchaseOrder(PurchaseOrder po) async {
    if (_tenantId == null) return;
    await _poService.createPurchaseOrder(_tenantId!, po);
  }

  Future<void> markPurchaseOrderStatus(String poId, String status) async {
    if (_tenantId == null) return;
    await _poService.updateStatus(_tenantId!, poId, status);
  }

  Future<void> receivePurchaseOrder(PurchaseOrder po, String receivedBy) async {
    if (_tenantId == null) return;
    await _poService.receivePurchaseOrder(
      tenantId: _tenantId!,
      po: po,
      receivedBy: receivedBy,
    );
  }

  Future<void> acknowledgeAlert(String alertId) async {
    if (_tenantId == null) return;
    await _alertService.acknowledgeAlert(_tenantId!, alertId);
  }

  Future<void> markWhatsappSent(String alertId) async {
    if (_tenantId == null) return;
    await _alertService.markWhatsappSent(_tenantId!, alertId);
  }

  Future<void> syncLowStockAlerts(List<InventoryItem> items) async {
    if (_tenantId == null || _alertSyncPending) return;
    _alertSyncPending = true;

    try {
      for (final item in items) {
        if (item.status == StockStatus.low) {
          await _alertService.createAlertIfNeeded(
            tenantId: _tenantId!,
            itemId: item.id,
            itemName: item.name,
            status: 'low',
            currentStock: item.currentStock,
            unit: item.unit,
          );
        } else if (item.status == StockStatus.out) {
          await _alertService.createAlertIfNeeded(
            tenantId: _tenantId!,
            itemId: item.id,
            itemName: item.name,
            status: 'out',
            currentStock: item.currentStock,
            unit: item.unit,
          );
        }
      }
    } finally {
      _alertSyncPending = false;
    }
  }

  @override
  void dispose() {
    _disposeStreams();
    super.dispose();
  }
}
