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
      var params = Map<String, String>.from(uri.queryParameters);

      // Robust check: if main query params are empty or missing tenantId, check fragment (Hash Routing)
      // Standard Flutter Web often moves query params after the '#'
      if (params['tenantId'] == null && params['store'] == null && uri.fragment.contains('?')) {
        try {
          final fragQuery = uri.fragment.split('?').last;
          final fragParams = Uri.splitQueryString(fragQuery);
          params.addAll(fragParams);
          print('🔗 Detected parameters in URL fragment (Hash Routing)');
        } catch (e) {
          print('❌ Error parsing URL fragment: $e');
        }
      }

      // 1. tenantId (modern) or store (legacy)
      tenantId = params['tenantId'] ?? params['store'];

      // 2. tableId (modern) or table (legacy)
      tableId = params['tableId'] ?? params['table'];
      
      // 3. Determine OrderType (Table ID presence usually implies Dine-In)
      if (tableId != null && tableId.isNotEmpty) {
        orderType = OrderType.dineIn;
      } else {
        orderType = OrderType.parcel;
      }

      // 4. Explicit override if 'type' param exists
      if (params.containsKey('type')) {
        final typeStr = params['type']?.toLowerCase();
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
