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
  test('loads subsequent pages and skips duplicate occurrence IDs', () async {
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
    expect(controller.occurrences.map((item) => item.id), ['1', '2']);
    await controller.loadNextPage();
    expect(controller.occurrences.map((item) => item.id), ['1', '2', '3']);
    expect(controller.hasMore, isFalse);

    controller.dispose();
    api.close();
  });

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

Map<String, dynamic> _record(int id) => {
  'key': id,
  'scientificName': 'Species $id',
  'country': 'Indonesia',
  'decimalLatitude': -6.2,
  'decimalLongitude': 106.8,
};
