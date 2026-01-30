import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/order.dart' as model;
import '../../services/printing_service.dart';

class BackgroundPrintProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PrintingService _printingService = PrintingService();
  
  String? _tenantId;
  StreamSubscription? _orderSubscription;
  bool _isInitialized = false;
  
  // Local state for UI feedback
  bool get isPrinterReady => _printingService.isPrinterReady;
  DateTime? get lastFailureAt => _printingService.lastFailureAt;
  String? get lastError => _printingService.lastError;

  void initialize(String tenantId) {
    if (_tenantId == tenantId && _isInitialized) return;
    
    _tenantId = tenantId;
    _stopListener();
    _startListener();
    _isInitialized = true;
    notifyListeners();
  }

  void _startListener() {
    if (_tenantId == null) return;

    debugPrint('🖨️ BackgroundPrintProvider: Starting listener for $_tenantId');

    // Listen to ALL active orders for this tenant
    // We filter for orders created in the last 12 hours to avoid overhead
    final twelveHoursAgo = DateTime.now().subtract(const Duration(hours: 12));

    _orderSubscription = _firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('orders')
        .where('createdAt', isGreaterThan: twelveHoursAgo)
        .where('status', whereNotIn: [model.OrderStatus.completed.name, model.OrderStatus.cancelled.name])
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
              _processOrderChange(change.doc);
            }
          }
        });
  }

  Future<void> _processOrderChange(DocumentSnapshot doc) async {
    try {
      final order = model.Order.fromFirestore(doc);
      
      // 1. Identify unprinted items
      final unprintedItems = order.items.where((i) => !i.printedToKOT).toList();
      
      if (unprintedItems.isEmpty) return;

      debugPrint('🖨️ BackgroundPrintProvider: Found ${unprintedItems.length} unprinted items for order ${order.id}');

      // 2. Trigger Print
      // If it's a completely new order (all items unprinted and order.printedToKOT is false), print as KOT
      // If it's an update (some items unprinted), print as ADD-ON KOT
      final success = await _printingService.printKOT(order, itemsToPrint: unprintedItems);

      if (success) {
        // 3. Mark items as printed in Firestore
        await _markAsPrinted(doc.reference, order, unprintedItems);
        notifyListeners();
      } else {
        notifyListeners(); // Update UI with failure state
      }
    } catch (e) {
      debugPrint('❌ BackgroundPrintProvider Error: $e');
    }
  }

  Future<void> _markAsPrinted(DocumentReference orderRef, model.Order order, List<model.OrderItem> printedItems) async {
    try {
      final now = DateTime.now();
      
      // Update the specific items in the items list
      final updatedItems = order.items.map((item) {
        final wasPrintedJustNow = printedItems.any((pi) => pi.id == item.id && pi.timestamp == item.timestamp);
        if (wasPrintedJustNow) {
          return item.copyWith(
            printedToKOT: true,
            printedAt: now,
          );
        }
        return item;
      }).toList();

      // Check if the entire order is now considered "started" printing
      bool orderPrintedStatus = order.printedToKOT || printedItems.length == order.items.length;

      await orderRef.update({
        'items': updatedItems.map((i) => i.toMap()).toList(),
        'printedToKOT': orderPrintedStatus,
        'printedAt': orderPrintedStatus ? FieldValue.serverTimestamp() : order.printedAt != null ? Timestamp.fromDate(order.printedAt!) : null,
      });
      
      debugPrint('✅ BackgroundPrintProvider: Marked ${printedItems.length} items as printed for ${order.id}');
    } catch (e) {
      debugPrint('❌ BackgroundPrintProvider: Failed to mark as printed: $e');
    }
  }

  Future<void> checkPrinter() async {
    final success = await _printingService.checkPrinter();
    notifyListeners();
  }

  void _stopListener() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
  }

  @override
  void dispose() {
    _stopListener();
    super.dispose();
  }
}
