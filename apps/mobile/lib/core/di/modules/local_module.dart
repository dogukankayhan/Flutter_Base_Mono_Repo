import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/movies/cubit/favorites_cubit.dart';
import '../../local/favorites_store.dart';

// SharedPreferences is already registered by setupNetworkModule (flutter_kit_network).
void setupLocalModule(GetIt getIt) {
  getIt.registerLazySingleton<FavoritesStore>(
    () => FavoritesStore(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<FavoritesCubit>(
    () => FavoritesCubit(getIt<FavoritesStore>()),
  );
}
