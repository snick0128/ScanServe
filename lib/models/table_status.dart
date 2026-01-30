/// Table Lifecycle States
/// 
/// Defines the complete lifecycle of a restaurant table from available to cleaning.
/// This prevents table deadlocks and ensures proper state transitions.
enum TableStatus {
  /// Table is clean and ready for new customers
  available('available', 'Available', '✅'),
  
  /// Table has customers seated and actively dining
  occupied('occupied', 'Occupied', '👥'),
  
  /// Food has been served but payment is pending
  /// This state allows new customers to be seated at other tables
  /// while preserving the unpaid bill
  servedPendingPayment('served_pending_payment', 'Served - Pending Payment', '🍽️'),
  
  /// Table is being cleaned after customers leave
  cleaning('cleaning', 'Cleaning', '🧹'),
  
  /// Bill has been requested by customer
  billRequested('bill_requested', 'Bill Requested', '🧾'),
  
  /// Customer has chosen Cash at Counter, payment is pending
  paymentPending('payment_pending', 'Payment Pending', '💰');


  final String value;
  final String displayName;
  final String emoji;

  const TableStatus(this.value, this.displayName, this.emoji);

  /// Parse from string value
  static TableStatus fromString(String? value) {
    if (value == null) return TableStatus.available;
    
    // Handle legacy values
    switch (value.toLowerCase()) {
      case 'vacant':
      case 'available':
        return TableStatus.available;
      case 'occupied':
        return TableStatus.occupied;
      case 'served_pending_payment':
      case 'served':
        return TableStatus.servedPendingPayment;
      case 'cleaning':
        return TableStatus.cleaning;
      case 'bill_requested':
      case 'billrequested':
        return TableStatus.billRequested;
      case 'payment_pending':
      case 'paymentpending':
        return TableStatus.paymentPending;

      default:
        return TableStatus.values.firstWhere(
          (s) => s.value == value.toLowerCase(),
          orElse: () => TableStatus.available,
        );
    }
  }

  /// Check if table can accept new customers
  bool get canAcceptCustomers => this == TableStatus.available;

  /// Check if table has active session
  bool get hasActiveSession => 
      this == TableStatus.occupied || 
      this == TableStatus.servedPendingPayment ||
      this == TableStatus.billRequested ||
      this == TableStatus.paymentPending;


  /// Check if table has unpaid bills
  bool get hasUnpaidBills => 
      this == TableStatus.servedPendingPayment ||
      this == TableStatus.billRequested ||
      this == TableStatus.paymentPending;

}

/// Table State Transition Rules
/// 
/// Defines valid state transitions to prevent invalid states
class TableStateTransition {
  /// Validate if transition is allowed
  static bool isValidTransition(TableStatus from, TableStatus to) {
    switch (from) {
      case TableStatus.available:
        // Can only transition to occupied or cleaning
        return to == TableStatus.occupied || to == TableStatus.cleaning;
      case TableStatus.occupied:
        // Can transition to served, bill requested, payment pending, or back to available (force release)
        return to == TableStatus.servedPendingPayment ||
               to == TableStatus.billRequested ||
               to == TableStatus.paymentPending ||
               to == TableStatus.available;


      
      case TableStatus.servedPendingPayment:
        // Can transition to bill requested, payment pending, or cleaning (after payment)
        return to == TableStatus.billRequested || 
               to == TableStatus.paymentPending || 
               to == TableStatus.cleaning;

      
      case TableStatus.billRequested:
        // Can transition to payment pending or cleaning (after payment)
        return to == TableStatus.paymentPending || to == TableStatus.cleaning;
      
      case TableStatus.paymentPending:
        // Can only transition to cleaning (after payment) or back to bill requested
        return to == TableStatus.cleaning || to == TableStatus.billRequested;

      
      case TableStatus.cleaning:
        // Can only transition to available
        return to == TableStatus.available;
    }
  }

  /// Get next valid states
  static List<TableStatus> getValidNextStates(TableStatus current) {
    return TableStatus.values
        .where((status) => isValidTransition(current, status))
        .toList();
  }

  /// Validate transition and throw error if invalid
  static void validateTransition(TableStatus from, TableStatus to, {
    bool hasUnpaidOrders = false,
  }) {
    // Special rule: Cannot force release if there are unpaid orders
    if (from == TableStatus.occupied && 
        to == TableStatus.available && 
        hasUnpaidOrders) {
      throw Exception(
        'Cannot release table with unpaid orders. '
        'Please complete payment or move to "Served - Pending Payment" state.'
      );
    }

    if (!isValidTransition(from, to)) {
      throw Exception(
        'Invalid table state transition: ${from.displayName} → ${to.displayName}'
      );
    }
  }
}
