abstract final class GetPopularMoviesEndpoint {
  static const path = '/movie/popular';
  static Map<String, dynamic> query({required int page}) => {'page': page};
}

abstract final class GetNowPlayingMoviesEndpoint {
  static const path = '/movie/now_playing';
  static Map<String, dynamic> query({required int page}) => {'page': page};
}

abstract final class GetMovieDetailEndpoint {
  static String path(int movieId) => '/movie/$movieId';
}
