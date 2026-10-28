import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../api/bin/server.dart';

void main() {
  test('proxies the GBIF vernacular-name endpoint and caches its response', () async {
    HttpServer? gbifServer;
    HttpServer? proxyServer;
    SpeciesApi? api;
    final client = HttpClient();
    Uri? upstreamUri;
    var upstreamRequests = 0;

    try {
      gbifServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      gbifServer.listen((request) async {
        upstreamRequests++;
        upstreamUri = request.uri;
        request.response
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'results': [
                {'vernacularName': 'Dara laut', 'language': 'ind'},
              ],
            }),
          );
        await request.response.close();
      });

      api = SpeciesApi(
        gbifBaseUri: Uri.parse('http://127.0.0.1:${gbifServer.port}/v1'),
      );
      proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      proxyServer.listen((request) => unawaited(api!.handle(request)));

      final uri = Uri.parse(
        'http://127.0.0.1:${proxyServer.port}/api/species/5231190/vernacularNames',
      );
      final first = await _get(client, uri);
      final second = await _get(client, uri);

      expect(first.statusCode, HttpStatus.ok);
      expect(second.body, first.body);
      expect(upstreamUri?.path, '/v1/species/5231190/vernacularNames');
      expect(upstreamUri?.queryParameters['limit'], '100');
      expect(upstreamRequests, 1);
    } finally {
      client.close(force: true);
      if (proxyServer != null) await proxyServer.close(force: true);
      if (gbifServer != null) await gbifServer.close(force: true);
      api?.close();
    }
  });
}

Future<_TestResponse> _get(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri);
  final response = await request.close();
  return _TestResponse(
    response.statusCode,
    await utf8.decoder.bind(response).join(),
  );
}

class _TestResponse {
  const _TestResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}
