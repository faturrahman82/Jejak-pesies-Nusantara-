import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jejak_spesies_nusantara/core/network/gbif_api_client.dart';
import 'package:jejak_spesies_nusantara/features/favorites/data/favorites_store.dart';
import 'package:jejak_spesies_nusantara/features/occurrences/application/occurrence_controller.dart';
import 'package:jejak_spesies_nusantara/features/occurrences/data/occurrence_repository.dart';
import 'package:jejak_spesies_nusantara/features/occurrences/domain/species_occurrence.dart';

void main() {
  test(
    'loads pages, removes duplicate IDs, and preserves the result set',
    () async {
      final api = GbifApiClient(
        client: MockClient((request) async {
          final offset = int.parse(request.url.queryParameters['offset']!);
          final results = offset == 0
              ? [_record(1), _record(2)]
              : [_record(2), _record(3)];
          return http.Response(
            jsonEncode({
              'offset': offset,
              'count': 3,
              'endOfRecords': false,
              'results': results,
            }),
            200,
          );
        }),
      );
      final controller = OccurrenceController(
        repository: OccurrenceRepository(api),
        favoritesStore: _MemoryFavoritesStore(),
      );

      await controller.loadFirstPage();
      expect(controller.occurrences.map((item) => item.id).toSet(), {'1', '2'});
      expect(controller.occurrences, hasLength(2));
      await controller.loadNextPage();
      expect(controller.occurrences.map((item) => item.id).toSet(), {
        '1',
        '2',
        '3',
      });
      expect(controller.occurrences, hasLength(3));
      expect(controller.hasMore, isFalse);

      controller.dispose();
      api.close();
    },
  );

  test('continues pagination when a raw page has no usable photos', () async {
    final offsets = <int>[];
    final api = GbifApiClient(
      client: MockClient((request) async {
        final offset = int.parse(request.url.queryParameters['offset']!);
        offsets.add(offset);
        final results = offset == 0
            ? [_record(1, withPhoto: false), _record(2, withPhoto: false)]
            : [_record(3)];
        return http.Response(
          jsonEncode({
            'offset': offset,
            'count': 3,
            'endOfRecords': offset != 0,
            'results': results,
          }),
          200,
        );
      }),
    );
    final controller = OccurrenceController(
      repository: OccurrenceRepository(api),
      favoritesStore: _MemoryFavoritesStore(),
    );

    await controller.loadFirstPage();
    expect(controller.occurrences, isEmpty);
    expect(controller.hasMore, isTrue);
    await controller.loadNextPage();

    expect(offsets, [0, 2]);
    expect(controller.occurrences.single.id, '3');
    expect(controller.hasMore, isFalse);

    controller.dispose();
    api.close();
  });

  test(
    'caches Indonesian names by species and retries failed lookups',
    () async {
      var requests = 0;
      final api = GbifApiClient(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/vernacularNames')) {
            requests++;
            if (requests == 1) {
              throw http.ClientException('network unavailable');
            }
            return http.Response(
              jsonEncode({
                'results': [
                  {'vernacularName': 'Burung dara laut', 'language': 'ind'},
                ],
              }),
              200,
            );
          }
          return http.Response('{}', 200);
        }),
      );
      final controller = OccurrenceController(
        repository: OccurrenceRepository(api),
        favoritesStore: _MemoryFavoritesStore(),
      );
      final occurrence = SpeciesOccurrence.fromJson({
        ..._record(9),
        'speciesKey': 5231190,
        'taxonRank': 'SPECIES',
      });

      await expectLater(controller.localNameFor(occurrence), throwsException);
      expect(await controller.reloadLocalName(occurrence), 'Burung dara laut');
      expect(await controller.localNameFor(occurrence), 'Burung dara laut');
      expect(requests, 2);

      controller.dispose();
      api.close();
    },
  );

  test('favorites persist IDs and can be toggled off', () async {
    final store = _MemoryFavoritesStore();
    final api = GbifApiClient(
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    final controller = OccurrenceController(
      repository: OccurrenceRepository(api),
      favoritesStore: store,
    );
    final record = _record(12);
    final occurrence = SpeciesOccurrence.fromJson(record);

    await controller.toggleFavorite(occurrence);
    expect(store.ids, contains('12'));
    expect(controller.favoriteOccurrences.single.id, '12');
    await controller.toggleFavorite(occurrence);
    expect(store.ids, isEmpty);
    expect(controller.favoriteOccurrences, isEmpty);

    controller.dispose();
    api.close();
  });
}

class _MemoryFavoritesStore extends FavoritesStore {
  Set<String> ids = {};

  @override
  Future<Set<String>> load() async => ids;

  @override
  Future<void> save(Set<String> value) async {
    ids = {...value};
  }
}

Map<String, dynamic> _record(int id, {bool withPhoto = true}) => {
  'key': id,
  'scientificName': 'Species $id',
  'country': 'Indonesia',
  if (withPhoto)
    'media': [
      {'identifier': 'https://example.org/species-$id.jpg'},
    ],
  'decimalLatitude': -6.2,
  'decimalLongitude': 106.8,
};
