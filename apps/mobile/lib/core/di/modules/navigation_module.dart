import 'package:flutter_kit_auth/flutter_kit_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/managers/navigation_manager/app_router.dart';
import '../../../core/managers/navigation_manager/guards.dart';
import '../../../core/splash/splash_coordinator.dart';
import '../../../features/shell/shell_coordinator.dart';

void setupNavigationModule(GetIt getIt) {
  getIt.registerLazySingleton<GoRouter>(() {
    final notifier = AuthRouterNotifier(getIt<AuthBloc>());
    return AppRouter.create(
      auth: notifier,
      initialLocation: AppConfig.instance.isDev
          ? ShellCoordinator.dashboardPath
          : SplashCoordinator.path,
    );
  });
}
