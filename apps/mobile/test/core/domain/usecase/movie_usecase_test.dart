import 'package:flutter_base_kit/core/domain/entity/movie.dart';
import 'package:flutter_base_kit/core/domain/repository/movie_repository.dart';
import 'package:flutter_base_kit/core/domain/usecase/get_popular_movies_usecase.dart';
import 'package:flutter_kit_network/core/network/error/api_error.dart';
import 'package:flutter_kit_network/core/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'movie_usecase_test.mocks.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

final _kMovie = Movie(
  id: 1,
  title: 'Test Movie',
  overview: 'An overview.',
  posterPath: '/test.jpg',
  releaseDate: '2024-01-01',
  voteAverage: 7.5,
);

final _kError = ApiError(message: 'not found');

// ─── Mocks ────────────────────────────────────────────────────────────────────

@GenerateMocks([MovieRepository])
void main() {
  late MockMovieRepository mockRepo;
  late GetPopularMoviesUseCase useCase;

  setUp(() {
    provideDummy<Result<(List<Movie>, bool, int), ApiError>>(
      const Ok(([], false, 0)),
    );
    mockRepo = MockMovieRepository();
    useCase = GetPopularMoviesUseCase(mockRepo);
  });

  group('GetPopularMoviesUseCase', () {
    test('returns page data on ok', () async {
      when(mockRepo.getPopularMovies(offset: 0, pageSize: 20))
          .thenAnswer((_) async => Ok(([_kMovie], true, 20)));

      final (movies, hasMore, offset) =
          await useCase(offset: 0, pageSize: 20);

      expect(movies, [_kMovie]);
      expect(hasMore, true);
      expect(offset, 20);
    });

    test('forwards correct arguments to repository', () async {
      when(mockRepo.getPopularMovies(offset: 40, pageSize: 10))
          .thenAnswer((_) async => const Ok(([], false, 40)));

      await useCase(offset: 40, pageSize: 10);

      verify(mockRepo.getPopularMovies(offset: 40, pageSize: 10)).called(1);
    });

    test('throws ApiError on err', () {
      when(mockRepo.getPopularMovies(offset: anyNamed('offset'), pageSize: anyNamed('pageSize')))
          .thenAnswer((_) async => Err(_kError));

      expect(
        () => useCase(offset: 0, pageSize: 20),
        throwsA(isA<ApiError>().having((e) => e.message, 'message', 'not found')),
      );
    });
  });
}
