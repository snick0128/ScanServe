import 'package:flutter/foundation.dart';
import 'package:scan_serve/models/order_model.dart';
import 'package:scan_serve/utils/qr_url_parser.dart';

class AppConfig {
  static const String defaultTenantId = 'demo_tenant';

  final String? tenantId;
  final String? tableId;
  final OrderType? orderType;
  final bool isValid;

  AppConfig({
    this.tenantId,
    this.tableId,
    this.orderType,
    this.isValid = true,
  });

  static AppConfig init() {
    String? tenantId;
    String? tableId;
    OrderType? orderType;

    if (kIsWeb) {
      final uri = Uri.base;
      final params = QrUrlParser.parseUrl(uri.toString());
      
      tenantId = params['tenantId'];
      tableId = params['tableId'];
      
      // Fallback to manual check for explicit 'type' or other params not in QrUrlParser
      final queryParams = uri.queryParameters;
      
      // 3. Determine OrderType (Table ID presence usually implies Dine-In)
      if (tableId != null && tableId.isNotEmpty) {
        orderType = OrderType.dineIn;
      } else {
        orderType = OrderType.parcel;
      }

      // 4. Explicit override if 'type' param exists
      if (queryParams.containsKey('type')) {
        final typeStr = queryParams['type']?.toLowerCase();
        if (typeStr == 'dinein') {
          orderType = OrderType.dineIn;
        } else if (typeStr == 'parcel') {
          orderType = OrderType.parcel;
        }
      }
    }

    // Validation: tenantId is MANDATORY
    bool isValid = tenantId != null && tenantId.isNotEmpty;

    return AppConfig(
      tenantId: tenantId,
      tableId: tableId,
      orderType: orderType,
      isValid: isValid,
    );
  }
}
