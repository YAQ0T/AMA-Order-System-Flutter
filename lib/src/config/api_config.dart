import 'dart:io';

/// Configuration for connecting to the existing Node.js API.
class ApiConfig {
  /// Override at build time with `--dart-define=API_BASE_URL=http://host:port`.
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://213.6.226.163:6001');

  /// Allow bypassing self-signed certificates during local development.
  static const bool allowBadCertificates =
      bool.fromEnvironment('ALLOW_BAD_CERTS', defaultValue: false);
}

/// HttpOverrides that accepts self-signed certificates when enabled.
class PermissiveHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    if (ApiConfig.allowBadCertificates) {
      client.badCertificateCallback = (cert, host, port) => true;
    }
    return client;
  }
}
