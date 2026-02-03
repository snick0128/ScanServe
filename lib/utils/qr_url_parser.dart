class QrUrlParser {
  static Map<String, String?> parseUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      // 1. Try standard query parameters
      String? tenantId = uri.queryParameters['tenantId'] ?? uri.queryParameters['store'];
      String? tableId = uri.queryParameters['tableId'] ?? uri.queryParameters['table'];

      // 2. If not found, check the fragment
      if (tenantId == null && uri.fragment.isNotEmpty) {
        final fragment = uri.fragment;
        
        // Check for query params in fragment (Hash routing: /#/?tenantId=...)
        final queryIndex = fragment.indexOf('?');
        if (queryIndex != -1) {
          final queryStr = fragment.substring(queryIndex + 1);
          final queryParams = Uri.splitQueryString(queryStr);
          
          tenantId = tenantId ?? queryParams['tenantId'] ?? queryParams['store'];
          tableId = tableId ?? queryParams['tableId'] ?? queryParams['table'];
        } 
        
        // Check for path segments in fragment (Hash routing: /#/demo_tenant/table1)
        if (tenantId == null) {
          final pathSegments = fragment.split('/').where((s) => s.isNotEmpty && s != '#').toList();
          if (pathSegments.length >= 1) {
            tenantId = pathSegments[0];
            if (pathSegments.length >= 2) {
              tableId = pathSegments[1];
            }
          }
        }
      }

      print('🔍 Parsed QR - Tenant: $tenantId, Table: $tableId');
      
      return {
        'tenantId': tenantId,
        'tableId': tableId,
      };
    } catch (e) {
      print('❌ Error parsing QR URL: $e');
      return {'tenantId': null, 'tableId': null};
    }
  }
}
