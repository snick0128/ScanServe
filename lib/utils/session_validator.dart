import 'package:flutter/material.dart';

/// Session Validation Result
class SessionValidationResult {
  final bool isValid;
  final String? errorMessage;
  final SessionValidationError? errorType;

  const SessionValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorType,
  });

  factory SessionValidationResult.valid() {
    return const SessionValidationResult(isValid: true);
  }

  factory SessionValidationResult.invalid({
    required String message,
    required SessionValidationError errorType,
  }) {
    return SessionValidationResult(
      isValid: false,
      errorMessage: message,
      errorType: errorType,
    );
  }
}

/// Types of session validation errors
enum SessionValidationError {
  missingTenantId,
  missingTableId,
  invalidTenantId,
  invalidTableId,
  sessionExpired,
}

/// Session Validator Utility
/// 
/// Enforces mandatory tableId and tenantId validation before:
/// - Adding items to cart
/// - Requesting bill
/// - Calling waiter
/// - Placing orders
class SessionValidator {
  /// Validate session has required identifiers
  static SessionValidationResult validate({
    required String? tenantId,
    required String? tableId,
    bool requireTableId = true,
  }) {
    // Validate tenantId
    if (tenantId == null || tenantId.isEmpty) {
      return SessionValidationResult.invalid(
        message: 'Restaurant information is missing. Please scan the QR code again.',
        errorType: SessionValidationError.missingTenantId,
      );
    }

    // Validate tableId (required for dine-in)
    if (requireTableId && (tableId == null || tableId.isEmpty)) {
      return SessionValidationResult.invalid(
        message: 'Table information is missing. Please scan the QR code or enter your table number.',
        errorType: SessionValidationError.missingTableId,
      );
    }

    return SessionValidationResult.valid();
  }

  /// Show validation error dialog
  static Future<bool> showValidationDialog({
    required BuildContext context,
    required SessionValidationResult result,
    VoidCallback? onScanQR,
    VoidCallback? onEnterTable,
  }) async {
    if (result.isValid) return true;

    final shouldRetry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Session Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.errorMessage ?? 'Session validation failed',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'To continue, please:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          if (onEnterTable != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop(true);
                onEnterTable();
              },
              icon: Icon(Icons.keyboard),
              label: Text('Enter Table Number'),
            ),
          if (onScanQR != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(true);
                onScanQR();
              },
              icon: Icon(Icons.qr_code_scanner),
              label: Text('Scan QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );

    return shouldRetry ?? false;
  }

  /// Validate before cart operations
  static SessionValidationResult validateForCart({
    required String? tenantId,
    required String? tableId,
    bool isParcelOrder = false,
  }) {
    return validate(
      tenantId: tenantId,
      tableId: tableId,
      requireTableId: !isParcelOrder,
    );
  }

  /// Validate before bill request
  static SessionValidationResult validateForBillRequest({
    required String? tenantId,
    required String? tableId,
  }) {
    return validate(
      tenantId: tenantId,
      tableId: tableId,
      requireTableId: true, // Bill request always requires table
    );
  }

  /// Validate before waiter call
  static SessionValidationResult validateForWaiterCall({
    required String? tenantId,
    required String? tableId,
  }) {
    return validate(
      tenantId: tenantId,
      tableId: tableId,
      requireTableId: true, // Waiter call always requires table
    );
  }

  /// Validate before order placement
  static SessionValidationResult validateForOrder({
    required String? tenantId,
    required String? tableId,
    bool isParcelOrder = false,
  }) {
    return validate(
      tenantId: tenantId,
      tableId: tableId,
      requireTableId: !isParcelOrder,
    );
  }
}
