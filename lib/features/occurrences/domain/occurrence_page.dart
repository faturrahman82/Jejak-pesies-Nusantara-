import 'species_occurrence.dart';

class OccurrencePage {
  const OccurrencePage({
    required this.results,
    required this.offset,
    required this.count,
    required this.endOfRecords,
    this.rawResultCount,
  });

  final List<SpeciesOccurrence> results;
  final int offset;
  final int count;
  final bool endOfRecords;
  final int? rawResultCount;

  int get consumedResultCount => rawResultCount ?? results.length;

  factory OccurrencePage.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];
    final results = rawResults
        .whereType<Map<String, dynamic>>()
        .map(SpeciesOccurrence.fromJson)
        .where((item) => item.id.isNotEmpty)
        .where((item) => item.firstPhoto != null)
        .toList(growable: false);
    return OccurrencePage(
      results: results,
      offset: json['offset'] is int ? json['offset'] as int : 0,
      count: json['count'] is int ? json['count'] as int : rawResults.length,
      endOfRecords: json['endOfRecords'] == true,
      rawResultCount: rawResults.length,
    );
  }
}
