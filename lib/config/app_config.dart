import 'package:flutter/foundation.dart';
import 'package:scan_serve/models/order_model.dart';
import 'package:scan_serve/utils/qr_url_parser.dart';

class AppConfig {
  static const String defaultTenantId = 'demo_tenant';

  final String? tenantId;
  final String? tableId;
  final OrderType? orderType;
  final bool isValid;
  final String? errorMessage;

  AppConfig({
    this.tenantId,
    this.tableId,
    this.orderType,
    this.isValid = true,
    this.errorMessage,
  });

  static AppConfig init() {
    String? tenantId;
    String? tableId;
    OrderType? orderType;
    String? error;

    if (kIsWeb) {
      final uri = Uri.base;
      
      // Basic URL structural validation
      if (uri.path.contains('/admin')) {
         return AppConfig(isValid: true); // Admin handles its own config
      }

      final params = QrUrlParser.parseUrl(uri.toString());
      
      tenantId = params['tenantId'];
      tableId = params['tableId'];
      
      // Fallback to manual check for explicit 'type' or other params not in QrUrlParser
      final queryParams = uri.queryParameters;
      
      // Determine OrderType (Table ID presence usually implies Dine-In)
      if (tableId != null && tableId.isNotEmpty) {
        orderType = OrderType.dineIn;
      } else {
        orderType = OrderType.parcel;
      }

      // Explicit override if 'type' param exists
      if (queryParams.containsKey('type')) {
        final typeStr = queryParams['type']?.toLowerCase();
        if (typeStr == 'dinein') {
          orderType = OrderType.dineIn;
        } else if (typeStr == 'parcel') {
          orderType = OrderType.parcel;
        }
      }

      // STRICT VALIDATION: tenantId is MANDATORY for customer web app
      if (tenantId == null || tenantId.isEmpty) {
        error = 'Missing Restaurant ID. Please scan a valid QR code.';
      }
    } else {
      // In case someone tries to run on mobile (unsupported per rules but for safety)
      error = 'Mobile platform is not supported.';
    }

    return AppConfig(
      tenantId: tenantId,
      tableId: tableId,
      orderType: orderType,
      isValid: error == null && tenantId != null,
      errorMessage: error,
    );
  }
}
