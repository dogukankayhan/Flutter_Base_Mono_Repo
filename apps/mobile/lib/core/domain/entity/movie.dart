import 'package:equatable/equatable.dart';
import '../../config/tmdb_config.dart';

class Movie extends Equatable {
  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.releaseDate,
    required this.voteAverage,
  });

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? releaseDate;
  final double voteAverage;

  String? get posterUrl =>
      posterPath != null ? '${TmdbConfig.imageBaseUrl}$posterPath' : null;

  String get releaseYear {
    final date = releaseDate;
    if (date == null || date.length < 4) return '';
    return date.substring(0, 4);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'overview': overview,
        'poster_path': posterPath,
        'release_date': releaseDate,
        'vote_average': voteAverage,
      };

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
        id: json['id'] as int,
        title: json['title'] as String,
        overview: json['overview'] as String,
        posterPath: json['poster_path'] as String?,
        releaseDate: json['release_date'] as String?,
        voteAverage: (json['vote_average'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [id, title, posterPath, voteAverage];
}
