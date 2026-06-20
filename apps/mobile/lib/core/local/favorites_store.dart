import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entity/movie.dart';

class FavoritesStore {
  static const _key = 'favorite_movies';

  final SharedPreferences _prefs;
  final Map<int, Movie> _cache;

  FavoritesStore(this._prefs) : _cache = _load(_prefs);

  static Map<int, Movie> _load(SharedPreferences prefs) {
    final raw = prefs.getStringList(_key) ?? [];
    final map = <int, Movie>{};
    for (final item in raw) {
      try {
        final m = Movie.fromJson(jsonDecode(item) as Map<String, dynamic>);
        map[m.id] = m;
      } catch (_) {}
    }
    return map;
  }

  bool isFavorite(int id) => _cache.containsKey(id);

  Set<int> get favoriteIds => Set.unmodifiable(_cache.keys.toSet());

  // Newest first (LinkedHashMap preserves insertion order)
  List<Movie> get favorites => _cache.values.toList().reversed.toList();

  void toggle(Movie movie) {
    if (_cache.containsKey(movie.id)) {
      _cache.remove(movie.id);
    } else {
      _cache[movie.id] = movie;
    }
    _persist();
  }

  void _persist() {
    final encoded = _cache.values.map((m) => jsonEncode(m.toJson())).toList();
    _prefs.setStringList(_key, encoded);
  }
}
