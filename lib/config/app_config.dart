class AppConfig {
  AppConfig._();

  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://skillforge.takiyo.us',
  );

  static const String baseApiUrl = '$baseUrl/api/v1';
}
