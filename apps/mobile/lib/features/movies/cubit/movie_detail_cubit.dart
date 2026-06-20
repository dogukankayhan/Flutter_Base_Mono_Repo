import 'dart:async';

import 'package:flutter_kit_core/base_bloc/base_cubit.dart';

import '../../../core/domain/entity/movie.dart';
import 'favorites_cubit.dart';
import 'favorites_state.dart';
import 'movie_detail_state.dart';

/// Her film detayı için ayrı instance — BaseBlocView(activeKey: movie.id) ile
/// navigation stack'te eşzamanlı birden fazla detay sayfası açık olabilir.
///
/// FavoritesCubit stream'ini dinler: favoriler dışarıdan değiştiğinde
/// (favoriler tabından toggle) bu cubit anında güncellenir.
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
