class EndPointConstants {
  const EndPointConstants._();
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://6ae1d044bbb54129229932f4.mockapi.io/api/v1/',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
