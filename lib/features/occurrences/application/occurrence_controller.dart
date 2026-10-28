import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../features/favorites/data/favorites_store.dart';
import '../data/occurrence_repository.dart';
import '../domain/occurrence_page.dart';
import '../domain/species_occurrence.dart';

class OccurrenceController extends ChangeNotifier {
  factory OccurrenceController({
    required OccurrenceRepository repository,
    required FavoritesStore favoritesStore,
  }) => OccurrenceController._(repository, favoritesStore);

  OccurrenceController._(this._repository, this._favoritesStore);

  final OccurrenceRepository _repository;
  final FavoritesStore _favoritesStore;
  final List<SpeciesOccurrence> _occurrences = [];
  final List<SpeciesOccurrence> _favoriteRecords = [];
  final Map<String, Future<String?>> _localNames = {};
  Set<String> _favoriteIds = {};
  bool _loadingMore = false;
  bool _loadingFavorites = true;
  bool _hasMore = true;
  String? _loadMoreError;
  String _query = '';
  String province = '';
  int _generation = 0;
  int _nextOffset = 0;
  final Random _random = Random();

  List<SpeciesOccurrence> get occurrences => List.unmodifiable(_occurrences);
  List<SpeciesOccurrence> get favoriteOccurrences =>
      List.unmodifiable(_favoriteRecords);
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  bool get loadingMore => _loadingMore;
  bool get loadingFavorites => _loadingFavorites;
  bool get hasMore => _hasMore;
  String? get loadMoreError => _loadMoreError;
  String get query => _query;

  Future<List<String>> suggestNames(String query) =>
      _repository.suggestNames(query);

  Future<String?> localNameFor(SpeciesOccurrence occurrence) {
    final key =
        occurrence.speciesKey ??
        (occurrence.taxonRank?.toUpperCase() == 'SPECIES'
            ? occurrence.taxonKey
            : null);
    if (key == null) return Future.value(null);
    return _localNames.putIfAbsent(key, () async {
      try {
        return await _repository.indonesianVernacularName(key);
      } catch (_) {
        _localNames.remove(key);
        rethrow;
      }
    });
  }

  Future<String?> reloadLocalName(SpeciesOccurrence occurrence) {
    final key =
        occurrence.speciesKey ??
        (occurrence.taxonRank?.toUpperCase() == 'SPECIES'
            ? occurrence.taxonKey
            : null);
    if (key != null) {
      _localNames.remove(key);
    }
    return localNameFor(occurrence);
  }

  Future<void> loadFavorites() async {
    try {
      _favoriteIds = await _favoritesStore.load();
      notifyListeners();
      final records = await Future.wait(
        _favoriteIds.map((id) async {
          try {
            return await _repository.byId(id);
          } catch (_) {
            return null;
          }
        }),
      );
      _favoriteRecords
        ..clear()
        ..addAll(records.whereType<SpeciesOccurrence>());
      notifyListeners();
    } catch (_) {
      _favoriteIds = {};
    } finally {
      _loadingFavorites = false;
      notifyListeners();
    }
  }

  Future<OccurrencePage> loadFirstPage({String query = ''}) async {
    final generation = ++_generation;
    _query = query.trim();
    _occurrences.clear();
    _hasMore = true;
    _loadMoreError = null;
    _nextOffset = 0;
    notifyListeners();

    final page = await _repository.search(
      offset: 0,
      query: _query,
      province: province,
    );
    if (generation != _generation) return page;
    final shuffled = [...page.results]..shuffle(_random);
    _append(shuffled);
    _nextOffset = page.offset + page.consumedResultCount;
    _hasMore =
        !page.endOfRecords && _nextOffset < page.count && _nextOffset < 100000;
    notifyListeners();
    return page;
  }

  Future<void> loadNextPage() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    _loadMoreError = null;
    notifyListeners();
    try {
      final page = await _repository.search(
        offset: _nextOffset,
        province: province,
        query: _query,
      );
      final shuffled = [...page.results]..shuffle(_random);
      _append(shuffled);
      _nextOffset = page.offset + page.consumedResultCount;
      _hasMore =
          !page.endOfRecords &&
          _nextOffset < page.count &&
          _nextOffset < 100000;
    } catch (_) {
      _loadMoreError = 'Belum berhasil memuat catatan berikutnya.';
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(SpeciesOccurrence occurrence) async {
    final ids = {..._favoriteIds};
    if (!ids.add(occurrence.id)) {
      ids.remove(occurrence.id);
      _favoriteRecords.removeWhere((item) => item.id == occurrence.id);
    } else if (!_favoriteRecords.any((item) => item.id == occurrence.id)) {
      _favoriteRecords.insert(0, occurrence);
    }
    _favoriteIds = ids;
    notifyListeners();
    await _favoritesStore.save(ids);
  }

  void _append(List<SpeciesOccurrence> incoming) {
    final indexes = <String, int>{};
    for (var index = 0; index < _occurrences.length; index++) {
      indexes[_occurrences[index].speciesIdentity] = index;
    }
    final knownIds = _occurrences.map((item) => item.id).toSet();
    for (final occurrence in incoming) {
      if (knownIds.contains(occurrence.id)) continue;
      final existingIndex = indexes[occurrence.speciesIdentity];
      if (existingIndex == null) {
        indexes[occurrence.speciesIdentity] = _occurrences.length;
        knownIds.add(occurrence.id);
        _occurrences.add(occurrence);
      } else if (occurrence.completenessScore >
          _occurrences[existingIndex].completenessScore) {
        _occurrences[existingIndex] = occurrence;
        knownIds.add(occurrence.id);
      }
    }
  }
}
