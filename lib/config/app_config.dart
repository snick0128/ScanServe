import 'package:flutter/foundation.dart';
import 'package:scan_serve/models/order_model.dart';
import 'package:scan_serve/utils/qr_url_parser.dart';

class AppConfig {
  static const String defaultTenantId = 'demo_tenant';

  final String tenantId;
  final String? tableId;
  final OrderType? orderType;

  AppConfig({
    required this.tenantId,
    this.tableId,
    this.orderType,
  });

  static AppConfig init() {
    String tenantId = defaultTenantId;
    String? tableId;
    OrderType? orderType;

    if (kIsWeb) {
      final uri = Uri.base;
      final params = uri.queryParameters;

      // 1. Try reading from new parameters (store, table, type)
      if (params.containsKey('store')) {
        tenantId = params['store']!;
      }
      
      if (params.containsKey('table')) {
        tableId = params['table'];
      }

      if (params.containsKey('type')) {
        final typeStr = params['type']?.toLowerCase();
        if (typeStr == 'dinein') {
          orderType = OrderType.dineIn;
        } else if (typeStr == 'parcel') {
          orderType = OrderType.parcel;
        }
      }

      // 2. Fallback: Parse URL using legacy parser if new params are missing
      // This preserves existing QR code functionality if they use tenantId/tableId
      // and haven't been updated to the new format yet.
      if (tenantId == defaultTenantId && !params.containsKey('store')) {
         final legacyParams = QrUrlParser.parseUrl(uri.toString());
         if (legacyParams['tenantId'] != null) {
           tenantId = legacyParams['tenantId']!;
         }
         if (legacyParams['tableId'] != null) {
           tableId = legacyParams['tableId'];
         }
      }
    }

    return AppConfig(
      tenantId: tenantId,
      tableId: tableId,
      orderType: orderType,
    );
  }
}
