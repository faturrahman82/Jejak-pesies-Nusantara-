import 'package:shared_preferences/shared_preferences.dart';

class FavoritesStore {
  static const _key = 'favorite_occurrence_ids';
  FavoritesStore({SharedPreferencesAsync? preferences}) {
    _preferences = preferences;
  }

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();

  Future<Set<String>> load() async =>
      (await _store.getStringList(_key) ?? const <String>[]).toSet();

  Future<void> save(Set<String> ids) =>
      _store.setStringList(_key, ids.toList(growable: false));
}
