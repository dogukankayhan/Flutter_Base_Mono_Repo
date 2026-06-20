import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'view/movies_screen.dart';

final class MoviesNavigator {
  static const String path = '/movies';

  static GoRoute get route => GoRoute(
        path: path,
        builder: (_, _) => const MoviesScreen(),
      );

  static void show(BuildContext context) => context.go(path);
}
