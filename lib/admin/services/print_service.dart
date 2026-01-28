import 'package:flutter/foundation.dart';
import '../../models/order.dart' as model;

class PrintService {
  static final PrintService _instance = PrintService._internal();
  factory PrintService() => _instance;
  PrintService._internal();

  /// Simulates printing a KOT for an order
  Future<bool> printKOT(model.Order order, {bool isAddon = false}) async {
    print('🖨️ [KOT PRINT] Starting print for Order #${order.id.substring(0, 8)}');
    print('🖨️ [KOT PRINT] Table: ${order.tableName ?? 'Unknown'}');
    print('🖨️ [KOT PRINT] Type: ${isAddon ? "ADD-ON" : "NEW ORDER"}');
    
    for (var item in order.items) {
      // If it's an add-on print, we usually only print the new items. 
      // But for this mock, let's just list what's being "printed".
      if (isAddon && !item.isAddon) continue; 
      
      print('🖨️ [KOT PRINT]   - ${item.quantity}x ${item.name} ${item.notes != null ? "(${item.notes})" : ""}');
    }
    
    if (order.chefNote != null && order.chefNote!.isNotEmpty) {
      print('🖨️ [KOT PRINT] Chef Note: ${order.chefNote}');
    }

    print('🖨️ [KOT PRINT] SUCCESS: KOT command fired to printer buffer.');
    return true;
  }

  /// Simulates printing a Bill
  Future<bool> printBill(model.Order order) async {
    print('🖨️ [BILL PRINT] Generating bill for Order #${order.id.substring(0, 8)}');
    print('🖨️ [BILL PRINT] Table: ${order.tableName ?? 'Unknown'}');
    print('🖨️ [BILL PRINT] Total: ₹${order.total.toStringAsFixed(2)}');
    print('🖨️ [BILL PRINT] SUCCESS: Bill printed.');
    return true;
  }
}
