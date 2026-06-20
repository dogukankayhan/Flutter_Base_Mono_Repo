import 'package:flutter_kit_core/base_bloc/base_state.dart';

import '../../../core/domain/entity/movie.dart';

class MovieDetailState extends BaseState {
  const MovieDetailState({
    required this.movie,
    required this.isFavorite,
    super.isLoading,
    super.errorMessage,
  });

  final Movie movie;
  final bool isFavorite;

  MovieDetailState copyWith({
    bool? isFavorite,
    bool? isLoading,
    String? errorMessage,
  }) =>
      MovieDetailState(
        movie: movie,
        isFavorite: isFavorite ?? this.isFavorite,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [...super.props, movie.id, isFavorite];
}
