import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jejak_spesies_nusantara/core/network/api_exception.dart';
import 'package:jejak_spesies_nusantara/core/network/gbif_api_client.dart';

void main() {
  test(
    'always scopes searches to Indonesia and requests bounded pages',
    () async {
      final client = GbifApiClient(
        client: MockClient((request) async {
          expect(request.url.host, 'api.gbif.org');
          expect(request.url.path, '/v1/occurrence/search');
          expect(request.url.queryParameters['country'], 'ID');
          expect(request.url.queryParameters['offset'], '20');
          expect(request.url.queryParameters['limit'], '20');
          expect(request.url.queryParameters['q'], 'Rafflesia');
          expect(request.url.queryParameters['stateProvince'], 'Jawa Timur');
          expect(request.url.queryParameters['mediaType'], 'StillImage');
          expect(request.headers['Accept'], 'application/json');
          return http.Response('{"results":[]}', 200);
        }),
      );

      expect(
        await client.searchOccurrences(
          offset: 20,
          limit: 20,
          query: 'Rafflesia',
          province: 'Jawa Timur',
        ),
        {'results': []},
      );
      client.close();
    },
  );

  test('reports server status as a readable API exception', () async {
    final client = GbifApiClient(
      client: MockClient((_) async => http.Response('busy', 503)),
    );

    await expectLater(
      client.searchOccurrences(offset: 0, limit: 20),
      throwsA(
        isA<ApiException>().having(
          (error) => error.kind,
          'kind',
          ApiFailureKind.httpStatus,
        ),
      ),
    );
    client.close();
  });

  test('rejects malformed JSON', () async {
    final client = GbifApiClient(
      client: MockClient((_) async => http.Response('{bad', 200)),
    );

    await expectLater(
      client.searchOccurrences(offset: 0, limit: 20),
      throwsA(
        isA<ApiException>().having(
          (error) => error.kind,
          'kind',
          ApiFailureKind.invalidJson,
        ),
      ),
    );
    client.close();
  });

  test('selects a preferred Indonesian vernacular name', () async {
    final client = GbifApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/v1/species/5231190/vernacularNames');
        expect(request.url.queryParameters['limit'], '100');
        return http.Response(
          '{"results":['
          '{"vernacularName":"Whiskered tern","language":"eng","preferred":true},'
          '{"vernacularName":"Dara laut kumis","language":"ind"},'
          '{"vernacularName":"Dara laut","language":"id","preferred":true}'
          ']}',
          200,
        );
      }),
    );

    expect(await client.indonesianVernacularName('5231190'), 'Dara laut');
    client.close();
  });

  test('returns no Indonesian name when GBIF has none', () async {
    final client = GbifApiClient(
      client: MockClient(
        (_) async => http.Response(
          '{"results":[{"vernacularName":"Whiskered tern","language":"eng"}]}',
          200,
        ),
      ),
    );

    expect(await client.indonesianVernacularName('5231190'), isNull);
    client.close();
  });

  test('maps a failed API connection to a network exception', () async {
    final client = GbifApiClient(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(
      client.searchOccurrences(offset: 0, limit: 20),
      throwsA(
        isA<ApiException>().having(
          (error) => error.kind,
          'kind',
          ApiFailureKind.network,
        ),
      ),
    );
    client.close();
  });
}
