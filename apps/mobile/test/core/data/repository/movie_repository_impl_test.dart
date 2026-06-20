import 'package:flutter_base_kit/core/data/repository/movie_repository_impl.dart';
import 'package:flutter_base_kit/core/domain/entity/movie.dart';
import 'package:flutter_kit_network/core/network/api/api_manager_interface.dart';
import 'package:flutter_kit_network/core/network/api/api_response.dart';
import 'package:flutter_kit_network/core/network/error/api_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'movie_repository_impl_test.mocks.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

final _kMovieJson = <String, dynamic>{
  'page': 1,
  'results': [
    {
      'id': 1,
      'title': 'Test Movie',
      'overview': 'An overview.',
      'poster_path': '/test.jpg',
      'release_date': '2024-01-01',
      'vote_average': 7.5,
    }
  ],
  'total_pages': 5,
};

final _kLastPageJson = <String, dynamic>{
  'page': 3,
  'results': [
    {
      'id': 2,
      'title': 'Last Movie',
      'overview': '',
      'poster_path': null,
      'release_date': null,
      'vote_average': 0.0,
    }
  ],
  'total_pages': 3,
};

final _kError = ApiError(message: 'service unavailable');

// ─── Mocks ────────────────────────────────────────────────────────────────────

@GenerateMocks([ApiManager])
void main() {
  late MockApiManager mockApi;
  late MovieRepositoryImpl repo;

  setUp(() {
    mockApi = MockApiManager();
    repo = MovieRepositoryImpl(mockApi);
  });

  // ─── getPopularMovies — success ────────────────────────────────────────────

  group('getPopularMovies — success', () {
    test('returns Ok with parsed movie list', () async {
      when(mockApi.get<Map<String, dynamic>>(
        path: anyNamed('path'),
        query: anyNamed('query'),
      )).thenAnswer((_) async => ApiResponse(data: _kMovieJson));

      final result = await repo.getPopularMovies(offset: 0, pageSize: 20);

      result.when(
        ok: (data) {
          final (movies, hasMore, offset) = data;
          expect(movies.length, 1);
          expect(movies.first.title, 'Test Movie');
          expect(movies.first.voteAverage, 7.5);
          expect(hasMore, true);
          expect(offset, 1);
        },
        err: (_) => fail('expected ok'),
      );
    });

    test('calculates hasMore=false when page equals totalPages', () async {
      when(mockApi.get<Map<String, dynamic>>(
        path: anyNamed('path'),
        query: anyNamed('query'),
      )).thenAnswer((_) async => ApiResponse(data: _kLastPageJson));

      final result = await repo.getPopularMovies(offset: 40, pageSize: 20);

      result.when(
        ok: (data) => expect(data.$2, false),
        err: (_) => fail('expected ok'),
      );
    });

    test('calculates correct page number from offset and pageSize', () async {
      when(mockApi.get<Map<String, dynamic>>(
        path: anyNamed('path'),
        query: anyNamed('query'),
      )).thenAnswer((_) async => ApiResponse(data: _kMovieJson));

      await repo.getPopularMovies(offset: 40, pageSize: 20);

      // offset=40, pageSize=20 → page = 40 ~/ 20 + 1 = 3
      final captured = verify(mockApi.get<Map<String, dynamic>>(
        path: anyNamed('path'),
        query: captureAnyNamed('query'),
      )).captured;
      expect((captured.first as Map)['page'], 3);
    });
  });

  // ─── getPopularMovies — errors ─────────────────────────────────────────────

  group('getPopularMovies — errors', () {
    test('returns Err wrapping ApiError from api', () async {
      when(mockApi.get<Map<String, dynamic>>(
        path: anyNamed('path'),
        query: anyNamed('query'),
      )).thenThrow(_kError);

      final result = await repo.getPopularMovies(offset: 0, pageSize: 20);

      result.when(
        ok: (_) => fail('expected err'),
        err: (e) => expect(e.message, 'service unavailable'),
      );
    });

    test('wraps generic exception as Err(ApiError)', () async {
      when(mockApi.get<Map<String, dynamic>>(
        path: anyNamed('path'),
        query: anyNamed('query'),
      )).thenThrow(Exception('decode failed'));

      final result = await repo.getPopularMovies(offset: 0, pageSize: 20);

      result.when(
        ok: (_) => fail('expected err'),
        err: (e) => expect(e.message, contains('decode failed')),
      );
    });
  });

  // ─── Movie entity mapping ──────────────────────────────────────────────────

  group('Movie entity mapping', () {
    test('maps nullable fields to defaults', () async {
      final jsonWithNulls = <String, dynamic>{
        'page': 1,
        'results': [
          {'id': 99, 'title': null, 'overview': null, 'poster_path': null}
        ],
        'total_pages': 1,
      };

      when(mockApi.get<Map<String, dynamic>>(
        path: anyNamed('path'),
        query: anyNamed('query'),
      )).thenAnswer((_) async => ApiResponse(data: jsonWithNulls));

      final result = await repo.getPopularMovies(offset: 0, pageSize: 20);

      result.when(
        ok: (data) {
          final movie = data.$1.first;
          expect(movie.title, 'Unknown');
          expect(movie.overview, '');
          expect(movie.posterPath, isNull);
          expect(movie, isA<Movie>());
        },
        err: (_) => fail('expected ok'),
      );
    });
  });
}
