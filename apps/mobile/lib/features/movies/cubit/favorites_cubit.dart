import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/entity/movie.dart';
import '../../../core/local/favorites_store.dart';
import 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(this._store)
    : super(
        FavoritesState(
          favorites: _store.favorites,
          favoriteIds: _store.favoriteIds,
        ),
      );

  final FavoritesStore _store;

  void toggle(Movie movie) {
    _store.toggle(movie);
    emit(
      FavoritesState(
        favorites: _store.favorites,
        favoriteIds: _store.favoriteIds,
      ),
    );
  }
}
