import 'package:flutter_base_kit/core/domain/entity/movie.dart';
import 'package:flutter_base_kit/core/local/favorites_store.dart';
import 'package:flutter_base_kit/features/movies/cubit/favorites_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'favorites_cubit_test.mocks.dart';

@GenerateMocks([FavoritesStore])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFavoritesStore mockStore;
  late FavoritesCubit cubit;

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

    cubit = FavoritesCubit(mockStore);
  });

  tearDown(() async {
    await cubit.close();
  });

  group('FavoritesCubit Initial State', () {
    test('initial state gets data from store', () {
      expect(cubit.state.favorites, isEmpty);
      expect(cubit.state.favoriteIds, isEmpty);
    });
  });

  group('FavoritesCubit Toggle', () {
    test('toggles favorite movie status and emits new state', () {
      when(mockStore.favorites).thenReturn([tMovie]);
      when(mockStore.favoriteIds).thenReturn({1});

      cubit.toggle(tMovie);

      verify(mockStore.toggle(tMovie)).called(1);
      expect(cubit.state.favorites, contains(tMovie));
      expect(cubit.state.favoriteIds, contains(1));
    });
  });
}
