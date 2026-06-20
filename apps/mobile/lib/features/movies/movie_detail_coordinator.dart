import 'package:flutter/material.dart';
import 'package:flutter_kit_core/base_bloc/active_cubit_helper.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/entity/movie.dart';
import 'cubit/movie_detail_cubit.dart';
import 'view/movie_detail_screen.dart';

final class MovieDetailCoordinator {
  static const _segment = 'movie';

  /// Root navigator route — bottom navbar is HIDDEN (from movies tab)
  static const rootPath = '/$_segment';

  static GoRoute rootRoute(GlobalKey<NavigatorState> rootKey) => GoRoute(
    path: '$rootPath/:id',
    parentNavigatorKey: rootKey,
    builder: (_, state) => MovieDetailScreen(movie: state.extra! as Movie),
  );

  /// Shell-internal nested route — bottom navbar REMAINS (from my favorites tab)
  static GoRoute nestedRoute() => GoRoute(
    path: '$_segment/:id',
    builder: (_, state) => MovieDetailScreen(movie: state.extra! as Movie),
  );

  /// From movies tab: push to root navigator → navbar is hidden.
  /// If cubit is already active in stack, push is skipped — duplicate instance for the same movie is prevented.
  static void showFromMovies(BuildContext context, Movie movie) {
    if (hasActive<MovieDetailCubit>(key: movie.id.toString())) return;
    context.push('$rootPath/${movie.id}', extra: movie);
  }

  /// From my favorites tab: push to shell navigator → navbar remains.
  /// If cubit is already active in stack, push is skipped.
  static void showFromFavorites(BuildContext context, Movie movie) {
    if (hasActive<MovieDetailCubit>(key: movie.id.toString())) return;
    context.push('/appointments/$_segment/${movie.id}', extra: movie);
  }
}
