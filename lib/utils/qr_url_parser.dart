class QrUrlParser {
  static Map<String, String?> parseUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      // 1. Try standard query parameters
      String? tenantId = uri.queryParameters['tenantId'];
      String? tableId = uri.queryParameters['tableId'];

      // 2. If not found, check the fragment (Hash routing: /#/?tenantId=...)
      if (tenantId == null && uri.fragment.isNotEmpty) {
        // Handle cases like "ScanServe/#/?tenantId=..." or "ScanServe/#/pages?tenantId=..."
        final fragment = uri.fragment;
        final queryIndex = fragment.indexOf('?');
        
        if (queryIndex != -1) {
          final queryStr = fragment.substring(queryIndex + 1);
          final queryParams = Uri.splitQueryString(queryStr);
          
          tenantId = queryParams['tenantId'];
          tableId = queryParams['tableId'];
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
