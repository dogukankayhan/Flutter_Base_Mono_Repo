import 'package:flutter_kit_network/core/network/error/api_error.dart';
import 'package:flutter_kit_network/core/utils/result.dart';

import '../entity/movie.dart';

abstract interface class MovieRepository {
  Future<Result<(List<Movie>, bool hasMore, int nextOffset), ApiError>>
  getPopularMovies({required int offset, required int pageSize});
}
