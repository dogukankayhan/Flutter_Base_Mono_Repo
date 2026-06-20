import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_kit_core/base_bloc/base_bloc_view.dart';
import 'package:flutter_kit_ui/theme/app_brand_colors.dart';
import 'package:flutter_kit_ui/theme/app_colors.dart';
import 'package:flutter_kit_ui/theme/app_text_style.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/di/injection.dart';
import '../../../core/domain/entity/movie.dart';
import '../../../core/localization/localization_extension.dart';
import '../bloc/movies_bloc.dart';
import '../bloc/movies_event.dart';
import '../bloc/movies_state.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';
import '../movie_detail_navigator.dart';

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FavoritesCubit>.value(
      value: getIt<FavoritesCubit>(),
      child: BaseBlocView<MoviesBloc, MoviesState>(
        create: MoviesBloc.create,
        loadingOverlay: const SizedBox.shrink(),
        builder: (context, state, bloc) => Scaffold(
          backgroundColor: context.appColors.background,
          appBar: AppBar(
            title: Text(
              context.translations.movies.title,
              style: context.textStyle.title18Bold,
            ),
            automaticallyImplyLeading: false,
          ),
          body: RepaintBoundary(
            child: _Body(state: state, bloc: bloc),
          ),
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.bloc});
  final MoviesState state;
  final MoviesBloc bloc;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return _ErrorView(
        message: state.errorMessage!,
        onRetry: () => bloc.add(const MoviesRefreshed()),
      );
    }

    final itemCount = state.items.length + (state.hasMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const MoviesRefreshed()),
      child: GridView.builder(
        padding: EdgeInsets.all(12.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 10.h,
          childAspectRatio: 0.52,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            bloc.add(const MoviesLoadMore());
            return const Center(child: CircularProgressIndicator());
          }
          if (index >= state.items.length - 4 && state.hasMore) {
            bloc.add(const MoviesLoadMore());
          }
          return _MovieCard(movie: state.items[index]);
        },
      ),
    );
  }
}

// ─── Movie Card (grid — dikey layout) ────────────────────────────────────────

class _MovieCard extends StatelessWidget {
  const _MovieCard({required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: () => MovieDetailNavigator.showFromMovies(context, movie),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppBrandColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster + kalp overlay
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12.r),
                    ),
                    child: movie.posterUrl != null
                        ? Hero(
                            tag: 'movie-poster-${movie.id}',
                            child: CachedNetworkImage(
                              imageUrl: movie.posterUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => _posterPlaceholder(),
                              errorWidget: (_, _, _) => _posterPlaceholder(),
                            ),
                          )
                        : _posterPlaceholder(),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: BlocSelector<FavoritesCubit, FavoritesState, bool>(
                      selector: (s) => s.favoriteIds.contains(movie.id),
                      builder: (context, isFavorite) => GestureDetector(
                        onTap: () =>
                            context.read<FavoritesCubit>().toggle(movie),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? AppBrandColors.error
                                : Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Text(
                    movie.title,
                    style: context.textStyle.paragraph12SemiBold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    spacing: 3,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 11.w,
                        color: AppBrandColors.gold,
                      ),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: context.textStyle.paragraph12Regular.copyWith(
                          color: colors.secondaryTextColor,
                        ),
                      ),
                      if (movie.releaseYear.isNotEmpty) ...[
                        Text(
                          '·',
                          style: TextStyle(color: colors.secondaryTextColor),
                        ),
                        Text(
                          movie.releaseYear,
                          style: context.textStyle.paragraph12Regular.copyWith(
                            color: colors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterPlaceholder() => Container(
    color: AppBrandColors.tertiaryContainer,
    child: Center(
      child: Icon(
        Icons.movie_outlined,
        size: 32.w,
        color: AppBrandColors.tertiary,
      ),
    ),
  );
}

// ─── Error View ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_outlined,
              size: 48.w,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.translations.common.retry),
            ),
          ],
        ),
      ),
    );
  }
}
