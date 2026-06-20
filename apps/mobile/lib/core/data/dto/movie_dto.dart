import '../../domain/entity/movie.dart';

class MoviePageDto {
  final int page;
  final List<MovieDto> results;
  final int totalPages;

  const MoviePageDto({
    required this.page,
    required this.results,
    required this.totalPages,
  });

  factory MoviePageDto.fromJson(Map<String, dynamic> json) => MoviePageDto(
        page: json['page'] as int? ?? 1,
        results: (json['results'] as List<dynamic>? ?? [])
            .map((e) => MovieDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalPages: json['total_pages'] as int? ?? 1,
      );
}

class MovieDto {
  final int id;
  final String? title;
  final String? overview;
  final String? posterPath;
  final String? releaseDate;
  final double? voteAverage;

  const MovieDto({
    required this.id,
    this.title,
    this.overview,
    this.posterPath,
    this.releaseDate,
    this.voteAverage,
  });

  factory MovieDto.fromJson(Map<String, dynamic> json) => MovieDto(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String?,
        overview: json['overview'] as String?,
        posterPath: json['poster_path'] as String?,
        releaseDate: json['release_date'] as String?,
        voteAverage: (json['vote_average'] as num?)?.toDouble(),
      );

  Movie toDomain() => Movie(
        id: id,
        title: title ?? 'Unknown',
        overview: overview ?? '',
        posterPath: posterPath,
        releaseDate: releaseDate,
        voteAverage: voteAverage ?? 0.0,
      );
}
