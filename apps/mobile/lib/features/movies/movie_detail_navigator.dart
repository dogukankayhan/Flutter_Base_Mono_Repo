import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/entity/movie.dart';
import 'view/movie_detail_screen.dart';

final class MovieDetailNavigator {
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
  static void showFromMovies(BuildContext context, Movie movie) {
    context.push('$rootPath/${movie.id}', extra: movie);
  }

  /// From my favorites tab: push to shell navigator → navbar remains.
  static void showFromFavorites(BuildContext context, Movie movie) {
    context.push('/appointments/$_segment/${movie.id}', extra: movie);
  }
}
