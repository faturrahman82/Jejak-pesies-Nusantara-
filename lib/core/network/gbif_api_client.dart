import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class GbifApiClient {
  GbifApiClient({http.Client? client, Uri? baseUri})
    : _client = client ?? http.Client(),
      _baseUri = baseUri ?? Uri.https('api.gbif.org', '/v1');

  final http.Client _client;
  final Uri _baseUri;

  Future<Map<String, dynamic>> searchOccurrences({
    required int offset,
    required int limit,
    String query = '',
    String province = '',
  }) {
    final parameters = <String, String>{
      'country': 'ID',
      'mediaType': 'StillImage',
      'limit': '$limit',
      'offset': '$offset',
    };
    if (query.trim().isNotEmpty) parameters['q'] = query.trim();
    if (province.trim().isNotEmpty) {
      parameters['stateProvince'] = province.trim();
    }
    final uri = _baseUri.replace(
      path: '${_baseUri.path}/occurrence/search',
      queryParameters: parameters,
    );
    return _getJson(uri);
  }

  Future<List<String>> suggestNames(String query) async {
    if (query.trim().length < 2) return [];
    final response = await _client
        .get(
          Uri.https('api.gbif.org', '/v1/species/suggest', {
            'q': query.trim(),
            'limit': '5',
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return [];
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map((item) => item['canonicalName'] ?? item['scientificName'])
        .whereType<String>()
        .toSet()
        .toList();
  }

  Future<Map<String, dynamic>> occurrenceById(String id) {
    final uri = _baseUri.replace(path: '${_baseUri.path}/occurrence/$id');
    return _getJson(uri);
  }

  Future<String?> indonesianVernacularName(String speciesKey) async {
    final uri = _baseUri.replace(
      path: '${_baseUri.path}/species/$speciesKey/vernacularNames',
      queryParameters: const {'limit': '100'},
    );
    final response = await _getJson(uri);
    final names = (response['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((item) {
          final language = (item['language'] as String?)?.toLowerCase();
          final name = item['vernacularName'];
          return (language == 'id' || language == 'ind') &&
              name is String &&
              name.trim().isNotEmpty;
        })
        .toList(growable: false);
    if (names.isEmpty) return null;

    final preferred = names.where((item) => item['preferred'] == true);
    return (preferred.isNotEmpty
            ? preferred.first
            : names.first)['vernacularName']
        as String;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    late final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'JejakSpesiesNusantara/1.0 (Flutter UTS project)',
            },
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw ApiException(
        ApiFailureKind.timeout,
        'Permintaan terlalu lama. Coba lagi.',
      );
    } on http.ClientException {
      throw const ApiException(
        ApiFailureKind.network,
        'Tidak dapat terhubung ke API. Periksa koneksi atau pastikan server API berjalan.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        ApiFailureKind.httpStatus,
        'API mengembalikan status ${response.statusCode}. Coba lagi nanti.',
        statusCode: response.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      throw const ApiException(
        ApiFailureKind.invalidJson,
        'Respons API tidak dapat dibaca.',
      );
    }
    throw const ApiException(
      ApiFailureKind.invalidJson,
      'Format respons API tidak sesuai.',
    );
  }

  void close() => _client.close();
}
