import 'package:flutter/foundation.dart';
import 'package:flutter_base_kit/core/config/tmdb_config.dart';
import 'package:flutter_base_kit/core/data/repository/movie_repository_impl.dart';
import 'package:flutter_base_kit/core/domain/repository/movie_repository.dart';
import 'package:flutter_kit_network/core/config/api_config.dart';
import 'package:flutter_kit_network/core/network/api/api_manager.dart';
import 'package:flutter_kit_network/core/network/api/api_manager_interface.dart';
import 'package:flutter_kit_network/core/network/client/dio_client.dart';
import 'package:flutter_kit_network/core/network/serializer/json_serializer.dart';
import 'package:get_it/get_it.dart';
import 'package:requests_inspector/requests_inspector.dart';

void setupMovieModule(GetIt getIt) {
  if (getIt.isRegistered<ApiManager>(instanceName: 'tmdb')) return;

  const tmdbConfig = ApiConfig(
    baseUrl: TmdbConfig.baseUrl,
    defaultHeaders: {'Authorization': 'Bearer ${TmdbConfig.apiKey}'},
    enableLogging: true,
  );

  getIt.registerLazySingleton<ApiManager>(
    () => DioApiManager(
      client: DioClient(
        tmdbConfig,
        extraInterceptors: kDebugMode ? [RequestsInspectorInterceptor()] : null,
      ),
      serializer: const JsonSerializer(),
    ),
    instanceName: 'tmdb',
  );

  getIt.registerLazySingleton<MovieRepository>(
    () => MovieRepositoryImpl(getIt<ApiManager>(instanceName: 'tmdb')),
  );
}
