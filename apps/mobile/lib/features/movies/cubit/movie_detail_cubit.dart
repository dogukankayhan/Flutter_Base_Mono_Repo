import 'dart:async';

import 'package:flutter_kit_core/base_bloc/base_cubit.dart';

import '../../../core/domain/entity/movie.dart';
import 'favorites_cubit.dart';
import 'favorites_state.dart';
import 'movie_detail_state.dart';

/// Separate instance for each movie detail — with BaseBlocView(activeKey: movie.id)
/// multiple detail pages can be open simultaneously in navigation stack.
///
/// Listens to FavoritesCubit stream: when favorites change externally
/// (toggled from favorites tab) this cubit is updated instantly.
class MovieDetailCubit extends BaseCubit<MovieDetailState> {
  MovieDetailCubit({
    required Movie movie,
    required FavoritesCubit favoritesCubit,
  })  : _favoritesCubit = favoritesCubit,
        super(MovieDetailState(
          movie: movie,
          isFavorite: favoritesCubit.state.isFavorite(movie.id),
        )) {
    _sub = favoritesCubit.stream.listen((favState) {
      safeEmit(state.copyWith(isFavorite: favState.isFavorite(movie.id)));
    });
  }

  final FavoritesCubit _favoritesCubit;
  late final StreamSubscription<FavoritesState> _sub;

  void toggleFavorite() => _favoritesCubit.toggle(state.movie);

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
