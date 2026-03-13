
import '../models/order.dart';

class BillCalculator {
  static const double defaultTaxRate = 0.18; // 18% GST

  /// Calculates the final values for a list of orders.
  /// supports both percentage and fixed discounts.
  static Map<String, double> calculateBill({
    required List<Order> orders,
    double discountValue = 0,
    bool isPercentageDiscount = true,
    double? customTaxRate,
  }) {
    double subtotal = 0;
    
    for (var order in orders) {
      // We calculate subtotal from items to ensure accuracy,
      // ignoring any existing order-level discounts/taxes initially.
      for (var item in order.items) {
        subtotal += item.price * item.quantity;
        // If there are item-level discounts, subtract them from subtotal?
        // Usually subtotal is before ANY discount.
      }
    }

    // Item-level discounts
    double itemLevelDiscount = 0;
    for (var order in orders) {
      for (var item in order.items) {
        if (item.discountPercentage > 0) {
          itemLevelDiscount += (item.price * item.quantity) * (item.discountPercentage / 100);
        } else {
          itemLevelDiscount += item.discountAmount;
        }
      }
    }

    double subtotalAfterItemDiscount = subtotal - itemLevelDiscount;

    // RULE: Bill-level discount (if any) applies AFTER item-level discounts
    double billLevelDiscount = 0;
    if (isPercentageDiscount) {
      billLevelDiscount = subtotalAfterItemDiscount * (discountValue / 100);
    } else {
      billLevelDiscount = discountValue;
    }

    double totalDiscount = itemLevelDiscount + billLevelDiscount;
    double taxableAmount = subtotal - totalDiscount;
    
    if (taxableAmount < 0) taxableAmount = 0;

    double taxRate = customTaxRate ?? defaultTaxRate;
    double taxAmount = taxableAmount * taxRate;
    double finalTotal = taxableAmount + taxAmount;

    // GST Rounding: 2 decimal places for financial accuracy
    double round(double val) => (val * 100).roundToDouble() / 100;

    return {
      'subtotal': round(subtotal),
      'itemLevelDiscount': round(itemLevelDiscount),
      'billLevelDiscount': round(billLevelDiscount),
      'totalDiscount': round(totalDiscount),
      'taxableAmount': round(taxableAmount),
      'taxAmount': round(taxAmount),
      'finalTotal': round(finalTotal),
      'taxRate': taxRate,
    };
  }
}
