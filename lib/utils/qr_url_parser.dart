class QrUrlParser {
  static Map<String, String?> parseUrl(String url) {
    try {
      final uri = Uri.parse(url);

      return {
        'tenantId': uri.queryParameters['tenantId'],
        'tableId': uri.queryParameters['tableId'],
      };
    } catch (e) {
      print('Error parsing QR URL: $e');
      return {'tenantId': null, 'tableId': null};
    }
  }
}
