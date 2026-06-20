import 'package:equatable/equatable.dart';

import '../../../core/domain/entity/movie.dart';

class FavoritesState extends Equatable {
  const FavoritesState({
    this.favorites = const [],
    this.favoriteIds = const {},
  });

  final List<Movie> favorites;
  final Set<int> favoriteIds;

  bool isFavorite(int id) => favoriteIds.contains(id);

  @override
  List<Object?> get props => [favoriteIds];
}
