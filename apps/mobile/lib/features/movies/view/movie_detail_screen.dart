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
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';
import '../cubit/movie_detail_cubit.dart';
import '../cubit/movie_detail_state.dart';
import '../movie_detail_navigator.dart';

/// Movie detail screen.
///
/// activeKey = movie.id — multiple MovieDetailCubit instances
/// MovieDetailCubit instance is registered uniquely.
/// Externally accessible via `getActive<MovieDetailCubit>(key: id)`.
class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({super.key, required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FavoritesCubit>.value(
      value: getIt<FavoritesCubit>(),
      child: BaseBlocView<MovieDetailCubit, MovieDetailState>(
        activeKey: movie.id.toString(),
        create: () => MovieDetailCubit(
          movie: movie,
          favoritesCubit: getIt<FavoritesCubit>(),
        ),
        builder: (context, state, cubit) => Scaffold(
          backgroundColor: context.appColors.background,
          body: CustomScrollView(
            slivers: [
              _DetailAppBar(
                movie: movie,
                isFavorite: state.isFavorite,
                onToggleFavorite: cubit.toggleFavorite,
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoSection(movie: movie),
                    _FavoritesSection(currentMovieId: movie.id),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Collapsing AppBar with poster ────────────────────────────────────────────

class _DetailAppBar extends StatelessWidget {
  const _DetailAppBar({
    required this.movie,
    required this.isFavorite,
    required this.onToggleFavorite,
  });
  final Movie movie;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320.h,
      pinned: true,
      actions: [
        IconButton(
          tooltip: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? AppBrandColors.error : Colors.white,
          ),
          onPressed: onToggleFavorite,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.fromLTRB(16.w, 0, 56.w, 14.h),
        title: Text(
          movie.title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        background: movie.posterUrl != null
            ? Hero(
                tag: 'movie-poster-${movie.id}',
                child: CachedNetworkImage(
                  imageUrl: movie.posterUrl!,
                  fit: BoxFit.fill,
                  placeholder: (_, _) => _posterPlaceholder(),
                  errorWidget: (_, _, _) => _posterPlaceholder(),
                ),
              )
            : _posterPlaceholder(),
        collapseMode: CollapseMode.pin,
      ),
    );
  }

  Widget _posterPlaceholder() => Container(
    color: AppBrandColors.tertiaryContainer,
    child: Center(
      child: Icon(
        Icons.movie_outlined,
        size: 64.w,
        color: AppBrandColors.tertiary,
      ),
    ),
  );
}

// ─── Info Section ─────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            spacing: 16,
            children: [
              if (movie.releaseYear.isNotEmpty)
                _Chip(label: movie.releaseYear, icon: Icons.calendar_today),
              _Chip(
                label: movie.voteAverage.toStringAsFixed(1),
                icon: Icons.star_rounded,
                iconColor: AppBrandColors.gold,
              ),
            ],
          ),
          if (movie.overview.isNotEmpty) ...[
            Text('Özet', style: context.textStyle.title16Bold),
            Text(
              movie.overview,
              style: context.textStyle.paragraph14Regular.copyWith(
                color: colors.secondaryTextColor,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon, this.iconColor});
  final String label;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(
            icon,
            size: 14.w,
            color: iconColor ?? cs.onSurface.withValues(alpha: 0.6),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Favorites Section ────────────────────────────────────────────────────────
//
// FavoritesCubit (singleton) + MovieDetailCubit (activeKey) at the same time
// active on the same screen — example of two different cubit types working together.

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection({required this.currentMovieId});
  final int currentMovieId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        final others = state.favorites
            .where((m) => m.id != currentMovieId)
            .toList();
        if (others.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 10.h),
              child: Text('Favorilerim', style: context.textStyle.title16Bold),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 180.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                itemCount: others.length,
                itemBuilder: (_, i) => _FavoritePosterCard(movie: others[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FavoritePosterCard extends StatelessWidget {
  const _FavoritePosterCard({required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => MovieDetailNavigator.showFromMovies(context, movie),
      child: Container(
        width: 90.w,
        margin: EdgeInsets.only(right: 10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: movie.posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: movie.posterUrl!,
                        width: 90.w,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _placeholder(),
                        errorWidget: (_, _, _) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              movie.title,
              style: context.textStyle.paragraph12Medium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppBrandColors.tertiaryContainer,
    child: Center(
      child: Icon(
        Icons.movie_outlined,
        size: 24.w,
        color: AppBrandColors.tertiary,
      ),
    ),
  );
}
