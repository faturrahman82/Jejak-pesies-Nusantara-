abstract final class ApiConfig {
  static const _configuredBaseUrl = String.fromEnvironment(
    'SPECIES_API_BASE_URL',
  );

  static Uri get baseUri {
    if (_configuredBaseUrl.isNotEmpty) {
      return Uri.parse(_configuredBaseUrl);
    }

    return Uri.https('api.gbif.org', '/v1');
  }
}
