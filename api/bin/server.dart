import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  final api = SpeciesApi();
  stdout.writeln('Jejak Spesies API berjalan di http://0.0.0.0:$port/api');

  await for (final request in server) {
    unawaited(api.handle(request));
  }
}

class SpeciesApi {
  SpeciesApi({HttpClient? upstream, Uri? gbifBaseUri})
    : _upstream = upstream ?? HttpClient(),
      _gbifBaseUri = gbifBaseUri ?? Uri.https('api.gbif.org', '/v1') {
    _upstream.connectionTimeout = const Duration(seconds: 10);
  }

  final HttpClient _upstream;
  final Uri _gbifBaseUri;
  final _ResponseCache _cache = _ResponseCache();

  Future<void> handle(HttpRequest request) async {
    _setCorsHeaders(request.response);
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    try {
      final path = request.uri.path;
      if (request.method != 'GET') {
        _writeJson(request.response, HttpStatus.methodNotAllowed, {
          'error': 'Metode yang didukung hanya GET.',
        });
      } else if (path == '/api/health') {
        _writeJson(request.response, HttpStatus.ok, {
          'status': 'ok',
          'service': 'Jejak Spesies Nusantara API',
        });
      } else if (path == '/api/occurrence/search') {
        await _search(request);
      } else if (path == '/api/provinces') {
        await _suggestProvinces(request);
      } else if (path.startsWith('/api/species/')) {
        await _vernacularNames(request);
      } else if (path.startsWith('/api/occurrence/')) {
        await _detail(request);
      } else {
        _writeJson(request.response, HttpStatus.notFound, {
          'error': 'Endpoint tidak ditemukan.',
        });
      }
    } on FormatException catch (error) {
      _writeJson(request.response, HttpStatus.badRequest, {
        'error': error.message,
      });
    } catch (error) {
      _writeJson(request.response, HttpStatus.badGateway, {
        'error': 'Layanan GBIF tidak dapat dijangkau.',
      });
      stderr.writeln('Request gagal: $error');
    }
  }

  Future<void> _search(HttpRequest request) async {
    final query = request.uri.queryParameters;
    final offset = _boundedInt(
      query['offset'],
      fallback: 0,
      min: 0,
      max: 99999,
    );
    final limit = _boundedInt(query['limit'], fallback: 20, min: 1, max: 300);
    if (offset + limit > 100000) {
      throw const FormatException(
        'Batas pencarian GBIF adalah 100.000 catatan.',
      );
    }

    final parameters = <String, String>{
      'country': 'ID',
      'mediaType': 'StillImage',
      'offset': '$offset',
      'limit': '$limit',
    };
    _copyIfPresent(query, parameters, 'q');
    _copyIfPresent(query, parameters, 'stateProvince');
    await _proxy(
      request.response,
      _gbifUri('/occurrence/search').replace(queryParameters: parameters),
    );
  }

  Future<void> _suggestProvinces(HttpRequest request) async {
    final query = request.uri.queryParameters;
    final text = query['q']?.trim() ?? '';
    if (text.isEmpty) {
      _writeJson(request.response, HttpStatus.ok, const <String>[]);
      return;
    }
    final limit = _boundedInt(query['limit'], fallback: 8, min: 1, max: 20);
    await _proxy(
      request.response,
      _gbifUri('/occurrence/search/stateProvince')
          .replace(queryParameters: {'q': text, 'limit': '$limit'}),
    );
  }

  Future<void> _detail(HttpRequest request) async {
    final id = request.uri.pathSegments.last;
    if (int.tryParse(id) == null) {
      _writeJson(request.response, HttpStatus.badRequest, {
        'error': 'ID catatan harus berupa angka GBIF.',
      });
      return;
    }
    await _proxy(request.response, _gbifUri('/occurrence/$id'));
  }

  Future<void> _vernacularNames(HttpRequest request) async {
    final segments = request.uri.pathSegments;
    if (segments.length != 4 || segments.last != 'vernacularNames') {
      _writeJson(request.response, HttpStatus.notFound, {
        'error': 'Endpoint nama lokal tidak ditemukan.',
      });
      return;
    }

    final speciesKey = int.tryParse(segments[2]);
    if (speciesKey == null || speciesKey < 0) {
      _writeJson(request.response, HttpStatus.badRequest, {
        'error': 'Kunci spesies harus berupa angka GBIF.',
      });
      return;
    }

    await _proxy(
      request.response,
      _gbifUri('/species/$speciesKey/vernacularNames')
          .replace(queryParameters: const {'limit': '100'}),
    );
  }

  Uri _gbifUri(String path) =>
      _gbifBaseUri.replace(path: '${_gbifBaseUri.path}$path');

  Future<void> _proxy(HttpResponse response, Uri target) async {
    final result = await _cache.get(target, () async {
      final upstreamRequest = await _upstream
          .getUrl(target)
          .timeout(const Duration(seconds: 20));
      upstreamRequest.headers.set(HttpHeaders.acceptHeader, 'application/json');
      upstreamRequest.headers.set(
        HttpHeaders.userAgentHeader,
        'JejakSpesiesNusantara/1.0',
      );
      final upstreamResponse = await upstreamRequest.close().timeout(
        const Duration(seconds: 20),
      );
      final body = await utf8.decoder
          .bind(upstreamResponse)
          .join()
          .timeout(const Duration(seconds: 20));
      return _CachedResponse(upstreamResponse.statusCode, body);
    });

    _writeRawJson(response, result.statusCode, result.body);
  }

  int _boundedInt(
    String? value, {
    required int fallback,
    required int min,
    required int max,
  }) {
    if (value == null) return fallback;
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < min || parsed > max) {
      throw FormatException('Nilai harus berupa angka antara $min dan $max.');
    }
    return parsed;
  }

  void _copyIfPresent(
    Map<String, String> source,
    Map<String, String> target,
    String key,
  ) {
    final value = source[key]?.trim();
    if (value != null && value.isNotEmpty) target[key] = value;
  }

  void _setCorsHeaders(HttpResponse response) {
    response.headers
      ..set(HttpHeaders.accessControlAllowOriginHeader, '*')
      ..set(HttpHeaders.accessControlAllowMethodsHeader, 'GET, OPTIONS')
      ..set(
        HttpHeaders.accessControlAllowHeadersHeader,
        'Accept, Content-Type',
      );
  }

  void _writeJson(HttpResponse response, int status, Object body) {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    unawaited(response.close());
  }

  void _writeRawJson(HttpResponse response, int status, String body) {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(body);
    unawaited(response.close());
  }

  void close() => _upstream.close(force: true);
}

class _CachedResponse {
  const _CachedResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

class _CacheEntry {
  const _CacheEntry(this.response, this.expiresAt);

  final _CachedResponse response;
  final DateTime expiresAt;
}

class _ResponseCache {
  static const _ttl = Duration(seconds: 45);
  static const _maxEntries = 150;
  final Map<String, _CacheEntry> _entries = {};

  Future<_CachedResponse> get(
    Uri uri,
    Future<_CachedResponse> Function() fetch,
  ) async {
    final key = uri.toString();
    final now = DateTime.now();
    final cached = _entries[key];
    if (cached != null && cached.expiresAt.isAfter(now)) {
      return cached.response;
    }

    final response = await fetch();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _entries.removeWhere((_, entry) => entry.expiresAt.isBefore(now));
      while (_entries.length >= _maxEntries) {
        _entries.remove(_entries.keys.first);
      }
      _entries[key] = _CacheEntry(response, now.add(_ttl));
    }
    return response;
  }
}
