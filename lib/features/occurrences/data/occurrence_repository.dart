import '../../../core/network/gbif_api_client.dart';
import '../domain/occurrence_page.dart';
import '../domain/species_occurrence.dart';

class OccurrenceRepository {
  const OccurrenceRepository(this._api);

  final GbifApiClient _api;
  static const int pageSize = 20;

  Future<OccurrencePage> search({
    required int offset,
    String query = '',
    String province = '',
  }) async {
    final json = await _api.searchOccurrences(
      offset: offset,
      limit: pageSize,
      query: query,
      province: province,
    );
    return OccurrencePage.fromJson(json);
  }

  Future<List<String>> suggestNames(String query) => _api.suggestNames(query);

  Future<SpeciesOccurrence> byId(String id) async =>
      SpeciesOccurrence.fromJson(await _api.occurrenceById(id));
}
