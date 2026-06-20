import 'package:flutter_base_kit/core/service/api/movie_api.dart';
import 'package:flutter_kit_network/core/network/api/api_manager_interface.dart';
import 'package:flutter_kit_network/core/network/error/api_error.dart';
import 'package:flutter_kit_network/core/utils/result.dart';

import '../../domain/entity/movie.dart';
import '../../domain/repository/movie_repository.dart';
import '../dto/movie_dto.dart';

class MovieRepositoryImpl implements MovieRepository {
  MovieRepositoryImpl(this._api);

  final ApiManager _api;

  @override
  Future<Result<(List<Movie>, bool, int), ApiError>> getPopularMovies({
    required int offset,
    required int pageSize,
  }) async {
    try {
      final page = offset ~/ pageSize + 1;
      final response = await _api.get<Map<String, dynamic>>(
        path: GetPopularMoviesEndpoint.path,
        query: GetPopularMoviesEndpoint.query(page: page),
      );
      final pageDto = MoviePageDto.fromJson(response.data);
      final movies = pageDto.results.map((dto) => dto.toDomain()).toList();
      final hasMore = pageDto.page < pageDto.totalPages;
      final nextOffset = offset + movies.length;
      return Ok((movies, hasMore, nextOffset));
    } on ApiError catch (e) {
      return Err(e);
    } catch (e) {
      return Err(ApiError(message: e.toString()));
    }
  }
}
