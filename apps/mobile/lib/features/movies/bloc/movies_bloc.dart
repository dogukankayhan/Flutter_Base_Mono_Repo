import 'package:flutter_kit_core/base_bloc/base_bloc.dart';
import 'package:flutter_kit_core/base_bloc/paginated_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/domain/entity/movie.dart';
import '../../../core/domain/repository/movie_repository.dart';
import '../../../core/domain/usecase/get_popular_movies_usecase.dart';
import 'movies_event.dart';
import 'movies_state.dart';

class MoviesBloc extends BaseBloc<MoviesEvent, MoviesState>
    with PaginatedBloc<Movie, MoviesEvent, MoviesState> {
  MoviesBloc(this._useCase) : super(const MoviesState()) {
    on<MoviesStarted>((_, emit) => handleLoadInitial(emit));
    on<MoviesLoadMore>((_, emit) => handleLoadMore(emit));
    on<MoviesRefreshed>((_, emit) => handleLoadInitial(emit));
  }

  MoviesBloc.create()
      : this(GetPopularMoviesUseCase(getIt<MovieRepository>()));

  final GetPopularMoviesUseCase _useCase;

  @override
  void onReady() => add(const MoviesStarted());

  @override
  Future<(List<Movie>, bool, int)> fetchPage(int offset, int size) =>
      _useCase(offset: offset, pageSize: size);

  @override
  MoviesState paginatedState({
    List<Movie>? items,
    bool? hasMore,
    int? nextOffset,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      state.copyWith(
        items: items,
        hasMore: hasMore,
        nextOffset: nextOffset,
        isLoading: isLoading,
        errorMessage: errorMessage,
        clearError: clearError,
      );
}
