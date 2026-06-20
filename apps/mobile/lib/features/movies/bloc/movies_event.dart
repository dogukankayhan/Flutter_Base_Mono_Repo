sealed class MoviesEvent {
  const MoviesEvent();
}

final class MoviesStarted extends MoviesEvent {
  const MoviesStarted();
}

final class MoviesLoadMore extends MoviesEvent {
  const MoviesLoadMore();
}

final class MoviesRefreshed extends MoviesEvent {
  const MoviesRefreshed();
}
