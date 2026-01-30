# Quick Reference: Critical Bug Fixes

## 🔴 Session Validation (Bug #1)

### Usage in Controllers
```dart
import '../utils/session_validator.dart';

// In CartController or any controller
void addItem(MenuItem item) {
  final validation = SessionValidator.validateForCart(
    tenantId: _tenantId,
    tableId: _tableId,
    isParcelOrder: _isParcelOrder,
  );

  if (!validation.isValid) {
    throw Exception(validation.errorMessage);
  }
  
  // Proceed with operation
}
```

### Usage in UI
```dart
try {
  cartController.addItem(item);
} catch (e) {
  // Show error dialog
  SessionValidator.showValidationDialog(
    context: context,
    result: SessionValidationResult.invalid(
      message: e.toString(),
      errorType: SessionValidationError.missingTableId,
    ),
    onScanQR: () => Navigator.push(...),
    onEnterTable: () => showTableEntryDialog(),
  );
}
```

---

## 🔴 Request Debouncing (Bug #2)

### Backend Usage (Order Service)
```dart
import '../utils/request_debouncer.dart';

// Already integrated in OrderService.createOrder()
final orderId = await orderService.createOrder(
  tenantId: tenantId,
  guestId: guestId,
  orderType: orderType,
  tableId: tableId,
  cartItems: items,
  requestId: uuid.v4(), // Generate client-side
);
```

### UI Button Handler
```dart
import 'package:uuid/uuid.dart';
import '../utils/request_debouncer.dart';

class OrderButton extends StatefulWidget {
  @override
  _OrderButtonState createState() => _OrderButtonState();
}

class _OrderButtonState extends State<OrderButton> {
  final _debouncer = DebouncedAction<String>();
  bool _isProcessing = false;

  Future<void> _placeOrder() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final orderId = await _debouncer.execute((requestId) async {
        return await orderService.createOrder(
          // ... params
          requestId: requestId,
        );
      });

      if (orderId == null) {
        // Request was debounced
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please wait before placing another order')),
        );
        return;
      }

      // Success
      Navigator.push(...);
    } catch (e) {
      // Error handling
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _placeOrder,
      child: _isProcessing 
        ? CircularProgressIndicator()
        : Text('Place Order'),
    );
  }
}
```

### Simple UI Debouncing
```dart
import '../utils/request_debouncer.dart';

class SearchBar extends StatefulWidget {
  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final _debouncer = UIDebouncer(delay: Duration(milliseconds: 300));

  void _onSearchChanged(String query) {
    _debouncer.run(() {
      // This will only execute 300ms after user stops typing
      performSearch(query);
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
```

### Action Cooldown (Waiter Call)
```dart
import '../utils/request_debouncer.dart';

class WaiterCallButton extends StatefulWidget {
  @override
  _WaiterCallButtonState createState() => _WaiterCallButtonState();
}

class _WaiterCallButtonState extends State<WaiterCallButton> {
  final _cooldown = ActionCooldown();
  static const _cooldownPeriod = Duration(minutes: 2);

  Future<void> _callWaiter() async {
    final actionKey = 'waiter_call_${widget.tableId}';

    if (_cooldown.isOnCooldown(actionKey, _cooldownPeriod)) {
      final remaining = _cooldown.getRemainingCooldown(actionKey, _cooldownPeriod);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait ${remaining.inSeconds}s before calling again'),
        ),
      );
      return;
    }

    // Call waiter
    await waiterService.callWaiter(tableId: widget.tableId);
    _cooldown.markActionExecuted(actionKey);
  }
}
```

---

## 🔴 Bill Adjustments (Bug #3)

### Applying Admin Adjustments
```dart
// In admin panel when applying discount/rounding
Future<void> applyAdjustment(Order order, String type, double amount) async {
  final adjustments = Map<String, double>.from(order.billAdjustments ?? {});
  adjustments[type] = amount;

  // Calculate new total
  final lineItemsSubtotal = order.subtotal;
  final discount = order.discountAmount;
  final tax = order.tax;
  final adjustmentsTotal = adjustments.values.fold(0.0, (a, b) => a + b);
  final newTotal = lineItemsSubtotal - discount + tax + adjustmentsTotal;

  // Update order
  await firestore
    .collection('tenants')
    .doc(tenantId)
    .collection('orders')
    .doc(order.id)
    .update({
      'billAdjustments': adjustments,
      'total': newTotal,
      'updatedAt': FieldValue.serverTimestamp(),
    });
}
```

### Recalculating with Preserved Adjustments
```dart
// When customer adds items to existing order
Future<void> addItemsToOrder(Order order, List<OrderItem> newItems) async {
  final allItems = [...order.items, ...newItems];
  
  // Recalculate line items subtotal
  final newSubtotal = allItems.fold<double>(0, (sum, item) => sum + item.total);
  
  // Preserve existing adjustments
  final adjustments = order.billAdjustments ?? {};
  final adjustmentsTotal = adjustments.values.fold(0.0, (a, b) => a + b);
  
  // Recalculate tax on new subtotal
  final taxRate = order.subtotal > 0 ? (order.tax / order.subtotal) : 0.18;
  final newTax = newSubtotal * taxRate;
  
  // Calculate final total with preserved adjustments
  final newTotal = newSubtotal - order.discountAmount + newTax + adjustmentsTotal;

  await firestore
    .collection('tenants')
    .doc(tenantId)
    .collection('orders')
    .doc(order.id)
    .update({
      'items': allItems.map((i) => i.toMap()).toList(),
      'subtotal': newSubtotal,
      'tax': newTax,
      'total': newTotal,
      // billAdjustments is NOT updated - preserved!
      'updatedAt': FieldValue.serverTimestamp(),
    });
}
```

### Displaying Adjustments in Bill
```dart
Widget buildBillSummary(Order order) {
  final adjustments = order.billAdjustments ?? {};
  
  return Column(
    children: [
      BillRow('Subtotal', order.subtotal),
      if (order.discountAmount > 0)
        BillRow('Discount', -order.discountAmount),
      BillRow('Tax', order.tax),
      
      // Show adjustments
      ...adjustments.entries.map((e) => 
        BillRow(
          e.key.replaceAll('_', ' ').toUpperCase(),
          e.value,
          isAdjustment: true,
        )
      ),
      
      Divider(),
      BillRow('TOTAL', order.total, isBold: true),
    ],
  );
}
```

---

## 🧪 Testing Checklist

### Session Validation
- [ ] Try adding item without tableId (should fail)
- [ ] Try adding item without tenantId (should fail)
- [ ] Parcel order without tableId (should succeed)
- [ ] Dine-in order with tableId (should succeed)
- [ ] Show validation dialog on error

### Request Debouncing
- [ ] Rapid tap order button (only 1 order created)
- [ ] Wait 60s, tap again (new order allowed)
- [ ] Network timeout during order (marked as failed)
- [ ] Multiple devices, same table (each has own UUID)

### Bill Adjustments
- [ ] Apply rounding adjustment
- [ ] Customer adds items after adjustment
- [ ] Adjustment is preserved
- [ ] Total is recalculated correctly
- [ ] Adjustment shows in bill breakdown

---

## 🚨 Common Pitfalls

### ❌ DON'T
```dart
// Don't create order without validation
await orderService.createOrder(
  tenantId: null, // ❌ Will fail silently
  tableId: null,  // ❌ Will fail silently
  // ...
);

// Don't recalculate total blindly
order.total = order.subtotal + order.tax; // ❌ Loses adjustments

// Don't allow rapid taps
ElevatedButton(
  onPressed: () => placeOrder(), // ❌ No debouncing
);
```

### ✅ DO
```dart
// Validate session first
final validation = SessionValidator.validateForCart(
  tenantId: tenantId,
  tableId: tableId,
);
if (!validation.isValid) throw Exception(validation.errorMessage);

// Preserve adjustments when recalculating
final adjustmentsTotal = order.billAdjustments?.values.fold(0.0, (a, b) => a + b) ?? 0.0;
final newTotal = newSubtotal - discount + tax + adjustmentsTotal;

// Use debounced action
final result = await debouncedAction.execute((requestId) async {
  return await orderService.createOrder(requestId: requestId, ...);
});
```

---

## 📚 Additional Resources

- Full implementation plan: `BUG_FIX_IMPLEMENTATION_PLAN.md`
- Progress report: `P0_BUG_FIXES_REPORT.md`
- Session validator: `lib/utils/session_validator.dart`
- Request debouncer: `lib/utils/request_debouncer.dart`

---

**Last Updated:** 2026-01-28
