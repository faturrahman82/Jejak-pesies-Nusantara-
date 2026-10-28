import 'package:flutter_test/flutter_test.dart';
import 'package:jejak_spesies_nusantara/features/occurrences/domain/occurrence_page.dart';
import 'package:jejak_spesies_nusantara/features/occurrences/domain/species_occurrence.dart';

void main() {
  test('parses a full GBIF occurrence including taxonomy and media', () {
    final occurrence = SpeciesOccurrence.fromJson(_record());

    expect(occurrence.id, '12345');
    expect(occurrence.scientificName, 'Chlidonias hybrida');
    expect(occurrence.speciesKey, '5231190');
    expect(occurrence.groupLabel, 'Burung');
    expect(occurrence.location, 'Rungkut, Surabaya, Jawa Timur, Indonesia');
    expect(occurrence.eventDate?.year, 2026);
    expect(occurrence.eventDate?.month, 1);
    expect(occurrence.eventDate?.day, 5);
    expect(occurrence.hasCoordinates, isTrue);
    expect(occurrence.iucnCategory, 'LC');
    expect(occurrence.firstPhoto?.credit, 'Pandu Ilmi');
    expect(occurrence.firstPhoto?.licenseUrl, contains('creativecommons.org'));
  });

  test('leaves optional data empty without rejecting the record', () {
    final occurrence = SpeciesOccurrence.fromJson({
      'key': 9,
      'scientificName': 'Rafflesia arnoldii',
      'country': 'Indonesia',
      'kingdom': 'Plantae',
    });

    expect(occurrence.groupLabel, 'Tumbuhan');
    expect(occurrence.firstPhoto, isNull);
    expect(occurrence.hasCoordinates, isFalse);
    expect(occurrence.eventDate, isNull);
  });

  test('parses empty and paged GBIF search responses', () {
    final page = OccurrencePage.fromJson({
      'offset': 20,
      'count': 21,
      'endOfRecords': true,
      'results': [_record()],
    });

    expect(page.offset, 20);
    expect(page.count, 21);
    expect(page.endOfRecords, isTrue);
    expect(page.results, hasLength(1));
    expect(page.consumedResultCount, 1);
    expect(OccurrencePage.fromJson(const {}).results, isEmpty);
  });

  test('does not include records with a missing photo URL', () {
    final page = OccurrencePage.fromJson({
      'offset': 0,
      'count': 2,
      'endOfRecords': true,
      'results': [
        _record(),
        {
          'key': 77,
          'scientificName': 'No photo species',
          'country': 'Indonesia',
          'media': [
            {'identifier': '  '},
          ],
        },
      ],
    });

    expect(page.results.map((item) => item.id), ['12345']);
    expect(page.consumedResultCount, 2);
  });
}

Map<String, dynamic> _record() => {
  'key': 12345,
  'scientificName': 'Chlidonias hybrida',
  'country': 'Indonesia',
  'kingdom': 'Animalia',
  'phylum': 'Chordata',
  'class': 'Aves',
  'order': 'Charadriiformes',
  'family': 'Laridae',
  'genus': 'Chlidonias',
  'taxonRank': 'SPECIES',
  'speciesKey': 5231190,
  'stateProvince': 'Jawa Timur',
  'locality': 'Rungkut',
  'gadm': {
    'level2': {'name': 'Surabaya'},
    'level3': {'name': 'Rungkut'},
  },
  'eventDate': '2026-01-05T15:59',
  'decimalLatitude': -7.31,
  'decimalLongitude': 112.82,
  'iucnRedListCategory': 'LC',
  'basisOfRecord': 'HUMAN_OBSERVATION',
  'datasetName': 'iNaturalist research-grade observations',
  'recordedBy': 'Pandu Ilmi',
  'references': 'https://www.inaturalist.org/observations/1',
  'license': 'CC BY-NC',
  'media': [
    {
      'identifier': 'https://example.org/bird.jpg',
      'creator': 'Pandu Ilmi',
      'license': 'https://creativecommons.org/licenses/by-nc/4.0/',
      'references': 'https://example.org/photo/1',
    },
  ],
};
