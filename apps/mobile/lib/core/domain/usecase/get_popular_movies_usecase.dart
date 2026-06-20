import 'package:flutter_kit_network/core/network/error/api_error.dart';

import '../entity/movie.dart';
import '../repository/movie_repository.dart';

class GetPopularMoviesUseCase {
  GetPopularMoviesUseCase(this._repository);

  final MovieRepository _repository;

  Future<(List<Movie>, bool, int)> call({
    required int offset,
    required int pageSize,
  }) async {
    final result = await _repository.getPopularMovies(
      offset: offset,
      pageSize: pageSize,
    );
    return result.when(
      ok: (data) => data,
      err: (e) => throw ApiError(message: e.message),
    );
  }
}
