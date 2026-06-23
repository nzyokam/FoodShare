// Values are injected at compile time via --dart-define.
//
// Development (default, no flags needed):
//   flutter run
//
// Production:
//   flutter run  --dart-define=ENVIRONMENT=production
//   flutter build apk --dart-define=ENVIRONMENT=production
//   flutter build web --dart-define=ENVIRONMENT=production
//
// The netlify.toml already passes these flags for web builds.

class AppConfig {
  static const _env = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const _devApiUrl = 'http://192.168.1.4:8000';
  static const _prodApiUrl = 'https://api-foodshare.nzyoka.com';

  static bool get isProduction => _env == 'production';

  static String get apiUrl =>
      isProduction ? _prodApiUrl : _devApiUrl;
}
