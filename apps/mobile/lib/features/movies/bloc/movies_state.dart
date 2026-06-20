import 'package:flutter_kit_core/base_bloc/paginated_bloc.dart';

import '../../../core/domain/entity/movie.dart';

final class MoviesState extends PaginatedState<Movie> {
  const MoviesState({
    super.isLoading = false,
    super.errorMessage,
    this.items = const [],
    this.hasMore = true,
    this.nextOffset = 0,
  });

  @override
  final List<Movie> items;

  @override
  final bool hasMore;

  @override
  final int nextOffset;

  MoviesState copyWith({
    List<Movie>? items,
    bool? hasMore,
    int? nextOffset,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      MoviesState(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        nextOffset: nextOffset ?? this.nextOffset,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props =>
      [...super.props, items, hasMore, nextOffset];
}
