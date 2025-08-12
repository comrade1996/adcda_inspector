/// UAE PASS constants and helpers
class Const {
  // ACR values
  static const String uaePassMobileACR = 'urn:digitalid:authentication:flow:mobileondevice';
  static const String uaePassWebACR = 'urn:safelayer:tws:policies:authentication:level:low';

  // URL schemes
  static const String _uaePassProdScheme = 'uaepass://';
  static const String _uaePassStgScheme = 'uaepassstg://';

  // Base URLs
  static const String _uaePassProdBaseUrl = 'https://id.uaepass.ae';
  static const String _uaePassStgBaseUrl = 'https://stg-id.uaepass.ae';

  static String baseUrl(bool isProduction) => isProduction ? _uaePassProdBaseUrl : _uaePassStgBaseUrl;
  static String uaePassScheme(bool isProduction) => isProduction ? _uaePassProdScheme : _uaePassStgScheme;
}
