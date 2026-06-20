import 'package:flutter_base_kit/core/domain/entity/movie.dart';
import 'package:flutter_base_kit/core/domain/usecase/get_popular_movies_usecase.dart';
import 'package:flutter_base_kit/features/movies/bloc/movies_bloc.dart';
import 'package:flutter_base_kit/features/movies/bloc/movies_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'movies_bloc_test.mocks.dart';

@GenerateMocks([GetPopularMoviesUseCase])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGetPopularMoviesUseCase mockUseCase;
  late MoviesBloc bloc;

  const tMovie = Movie(
    id: 1,
    title: 'Test Movie',
    overview: 'Overview',
    posterPath: 'poster_url',
    releaseDate: '2026-06-19',
    voteAverage: 7.5,
  );

  setUp(() {
    mockUseCase = MockGetPopularMoviesUseCase();
    bloc = MoviesBloc(mockUseCase);
  });

  tearDown(() async {
    await bloc.close();
  });

  group('MoviesBloc Initial State', () {
    test('initial state has correct default values', () {
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.isLoading, false);
      expect(bloc.state.hasMore, true);
      expect(bloc.state.nextOffset, 0);
      expect(bloc.state.errorMessage, isNull);
    });
  });

  group('MoviesStarted', () {
    test('loads popular movies successfully', () async {
      when(
        mockUseCase(offset: 0, pageSize: 20),
      ).thenAnswer((_) async => ([tMovie], true, 20));

      final loadingStates = <bool>[];
      final subscription = bloc.stream.listen(
        (s) => loadingStates.add(s.isLoading),
      );

      bloc.add(const MoviesStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(loadingStates, containsAll([true, false]));
      expect(bloc.state.items, contains(tMovie));
      expect(bloc.state.hasMore, true);
      expect(bloc.state.nextOffset, 20);

      await subscription.cancel();
    });

    test('emits error state when loading popular movies fails', () async {
      when(
        mockUseCase(offset: 0, pageSize: 20),
      ).thenThrow(Exception('Server error'));

      bloc.add(const MoviesStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isLoading, false);
      expect(bloc.state.errorMessage, contains('Server error'));
    });
  });
}
