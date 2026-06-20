import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_environment.dart';
import '../../../features/login/login_coordinator.dart';
import '../../../features/movies/movie_detail_coordinator.dart';
import '../../../features/register/register_coordinator.dart';
import '../../../features/shell/shell_coordinator.dart';

/// Root navigator key — all routes open via this key.
///
/// GoRouter is not taken as constructor parameter here or from GetIt
/// not pulled because this leads to navigation → auth → firebase cycle.
/// Bunun yerine [NotificationDeepLinkHandler.onNavigate] callback'i
/// set at app startup — firebase package does not import router.
final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final class AppCoordinator {
  AppCoordinator._()
      : login = LoginCoordinator(rootKey),
        register = RegisterCoordinator(rootKey),
        shell = ShellCoordinator();

  static final instance = AppCoordinator._();

  final LoginCoordinator login;
  final RegisterCoordinator register;
  final ShellCoordinator shell;

  List<RouteBase> get routes => [
        login.route,
        register.route,
        shell.route,
        MovieDetailCoordinator.rootRoute(rootKey),
      ];

  static const _shellPaths = {
    ShellCoordinator.dashboardPath,
    ShellCoordinator.appointmentsPath,
    ShellCoordinator.pokemonPath,
  };

  String? redirect({required bool isLoggedIn, required String path}) {
    if (AppConfig.instance.isDev) return null;
    if (!isLoggedIn) {
      if (_shellPaths.contains(path)) return LoginCoordinator.path;
    } else {
      if (path == LoginCoordinator.path || path == RegisterCoordinator.path) {
        return ShellCoordinator.dashboardPath;
      }
    }
    return null;
  }
}
