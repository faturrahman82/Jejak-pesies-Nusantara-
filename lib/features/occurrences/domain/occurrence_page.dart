import 'species_occurrence.dart';

class OccurrencePage {
  const OccurrencePage({
    required this.results,
    required this.offset,
    required this.count,
    required this.endOfRecords,
  });

  final List<SpeciesOccurrence> results;
  final int offset;
  final int count;
  final bool endOfRecords;

  factory OccurrencePage.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SpeciesOccurrence.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
    return OccurrencePage(
      results: results,
      offset: json['offset'] is int ? json['offset'] as int : 0,
      count: json['count'] is int ? json['count'] as int : results.length,
      endOfRecords: json['endOfRecords'] == true,
    );
  }
}
