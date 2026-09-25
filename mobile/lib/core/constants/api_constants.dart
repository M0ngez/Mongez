class ApiConstants {
  ApiConstants._();

  /// Production: pass via --dart-define=API_BASE_URL=https://your-domain.com/api/
  /// Dev:        defaults to local LAN IP for physical-device testing.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mongez-api-production-1a85.up.railway.app/api/',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  /// Google Web Client ID – passed via --dart-define for each build flavor.
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '945925867568-hkrej6riemi1arcahijktfi47vchbieb.apps.googleusercontent.com',
  );
}
