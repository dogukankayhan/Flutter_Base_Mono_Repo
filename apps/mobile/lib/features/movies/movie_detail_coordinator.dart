import 'package:flutter/material.dart';
import 'package:flutter_kit_core/base_bloc/active_cubit_helper.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/entity/movie.dart';
import 'cubit/movie_detail_cubit.dart';
import 'view/movie_detail_screen.dart';

final class MovieDetailCoordinator {
  static const _segment = 'movie';

  /// Root navigator route — bottom navbar GİZLENİR (filmler tabından)
  static const rootPath = '/$_segment';

  static GoRoute rootRoute(GlobalKey<NavigatorState> rootKey) => GoRoute(
    path: '$rootPath/:id',
    parentNavigatorKey: rootKey,
    builder: (_, state) => MovieDetailScreen(movie: state.extra! as Movie),
  );

  /// Shell-içi nested route — bottom navbar KALIR (favorilerim tabından)
  static GoRoute nestedRoute() => GoRoute(
    path: '$_segment/:id',
    builder: (_, state) => MovieDetailScreen(movie: state.extra! as Movie),
  );

  /// Filmler tabından: root navigator'a push → navbar gizlenir.
  /// Cubit zaten stack'te aktifse push atlanır — aynı film için çift instance engellenir.
  static void showFromMovies(BuildContext context, Movie movie) {
    if (hasActive<MovieDetailCubit>(key: movie.id.toString())) return;
    context.push('$rootPath/${movie.id}', extra: movie);
  }

  /// Favorilerim tabından: shell navigator'a push → navbar kalır.
  /// Cubit zaten stack'te aktifse push atlanır.
  static void showFromFavorites(BuildContext context, Movie movie) {
    if (hasActive<MovieDetailCubit>(key: movie.id.toString())) return;
    context.push('/appointments/$_segment/${movie.id}', extra: movie);
  }
}
