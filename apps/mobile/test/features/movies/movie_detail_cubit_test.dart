import 'package:flutter_base_kit/core/domain/entity/movie.dart';
import 'package:flutter_base_kit/features/movies/cubit/favorites_cubit.dart';
import 'package:flutter_base_kit/features/movies/cubit/movie_detail_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'favorites_cubit_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFavoritesStore mockStore;
  late FavoritesCubit favoritesCubit;
  late MovieDetailCubit cubit;

  const tMovie = Movie(
    id: 1,
    title: 'Test Movie',
    overview: 'Overview',
    posterPath: 'poster_url',
    releaseDate: '2026-06-19',
    voteAverage: 7.5,
  );

  setUp(() {
    mockStore = MockFavoritesStore();
    when(mockStore.favorites).thenReturn([]);
    when(mockStore.favoriteIds).thenReturn({});

    favoritesCubit = FavoritesCubit(mockStore);
    cubit = MovieDetailCubit(movie: tMovie, favoritesCubit: favoritesCubit);
  });

  tearDown(() async {
    await cubit.close();
    await favoritesCubit.close();
  });

  group('MovieDetailCubit Initial State', () {
    test('initial state has correct movie and isFavorite status', () {
      expect(cubit.state.movie, tMovie);
      expect(cubit.state.isFavorite, false);
    });
  });

  group('MovieDetailCubit toggleFavorite', () {
    test('calls toggle on FavoritesCubit', () {
      cubit.toggleFavorite();
      verify(mockStore.toggle(tMovie)).called(1);
    });

    test('updates isFavorite when FavoritesCubit state changes', () async {
      when(mockStore.favorites).thenReturn([tMovie]);
      when(mockStore.favoriteIds).thenReturn({tMovie.id});

      expect(cubit.state.isFavorite, false);

      favoritesCubit.toggle(tMovie);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(cubit.state.isFavorite, true);
    });
  });
}
