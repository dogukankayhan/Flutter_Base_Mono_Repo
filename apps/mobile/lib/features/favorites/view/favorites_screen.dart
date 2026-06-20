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
import '../../movies/cubit/favorites_cubit.dart';
import '../../movies/cubit/favorites_state.dart';
import '../../movies/movie_detail_coordinator.dart';
import '../../pokemon_favorites/bloc/pokemon_favorites_bloc.dart';
import '../../pokemon_favorites/bloc/pokemon_favorites_state.dart';
import '../../pokemon_favorites/view/favorites_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FavoritesCubit>.value(
      value: getIt<FavoritesCubit>(),
      child: BaseBlocView<PokemonFavoritesBloc, PokemonFavoritesState>(
        create: () => PokemonFavoritesBloc.create(),
        loadingOverlay: const SizedBox.shrink(),
        builder: (context, pokemonState, pokemonBloc) {
          return DefaultTabController(
            length: 2,
            child: Builder(
              builder: (context) => Scaffold(
                backgroundColor: context.appColors.background,
                appBar: AppBar(
                  title: Text(
                    context.translations.favorites.title,
                    style: context.textStyle.title18Bold,
                  ),
                  automaticallyImplyLeading: false,
                  actions: [
                    AnimatedBuilder(
                      animation: DefaultTabController.of(context),
                      builder: (context, _) {
                        final isPokeTab = DefaultTabController.of(context).index == 1;
                        if (isPokeTab && pokemonState.favorites.isNotEmpty) {
                          return IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: context.translations.favorites.clearTooltip,
                            onPressed: () => _showClearAllDialog(context, pokemonBloc),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                  bottom: TabBar(
                    labelColor: AppBrandColors.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppBrandColors.primary,
                    tabs: [
                      Tab(text: context.translations.favorites.tabMovies),
                      Tab(text: context.translations.favorites.tabPokemon),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    const _MovieFavoritesTab(),
                    PokemonFavoritesTab(state: pokemonState, bloc: pokemonBloc),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showClearAllDialog(BuildContext context, PokemonFavoritesBloc bloc) {
    final t = context.translations;
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.favorites.clearTitle),
        content: Text(t.favorites.clearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () {
              bloc.add(PokemonFavoritesClearAll());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.favorites.clearSuccess),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.favorites.clearButton),
          ),
        ],
      ),
    );
  }
}

// ─── Movie Favorites Tab ──────────────────────────────────────────────────────

class _MovieFavoritesTab extends StatelessWidget {
  const _MovieFavoritesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        if (state.favorites.isEmpty) return const _EmptyMoviesView();
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          itemCount: state.favorites.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _FavoriteCard(movie: state.favorites[index]),
          ),
        );
      },
    );
  }
}

// ─── Favorite Card ────────────────────────────────────────────────────────────

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: () => MovieDetailCoordinator.showFromFavorites(context, movie),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(color: AppBrandColors.shadow, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Poster(url: movie.posterUrl),
            SizedBox(width: 12.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text(
                      movie.title,
                      style: context.textStyle.paragraph14SemiBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (movie.releaseYear.isNotEmpty)
                      Text(
                        movie.releaseYear,
                        style: context.textStyle.paragraph12Regular.copyWith(
                          color: colors.secondaryTextColor,
                        ),
                      ),
                    Row(
                      spacing: 4,
                      children: [
                        Icon(Icons.star_rounded, size: 14.w, color: AppBrandColors.gold),
                        Text(
                          movie.voteAverage.toStringAsFixed(1),
                          style: context.textStyle.paragraph12Medium.copyWith(
                            color: colors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    if (movie.overview.isNotEmpty)
                      Text(
                        movie.overview,
                        style: context.textStyle.paragraph12Regular.copyWith(
                          color: colors.secondaryTextColor,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.favorite, color: AppBrandColors.error, size: 20.w),
              tooltip: context.translations.favorites.removeTooltip,
              onPressed: () => context.read<FavoritesCubit>().toggle(movie),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Poster ──────────────────────────────────────────────────────────────────

class _Poster extends StatelessWidget {
  const _Poster({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(12.r),
        bottomLeft: Radius.circular(12.r),
      ),
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url!,
              width: 90.w,
              height: 140.h,
              fit: BoxFit.cover,
              placeholder: (_, _) => _placeholder(),
              errorWidget: (_, _, _) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: 90.w,
        height: 140.h,
        color: AppBrandColors.tertiaryContainer,
        child: Icon(Icons.movie_outlined, size: 32.w, color: AppBrandColors.tertiary),
      );
}

// ─── Empty Views ──────────────────────────────────────────────────────────────

class _EmptyMoviesView extends StatelessWidget {
  const _EmptyMoviesView();

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 64.w, color: cs.onSurface.withValues(alpha: 0.25)),
          SizedBox(height: 16.h),
          Text(
            t.favorites.emptyMovies,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
          ),
          SizedBox(height: 8.h),
          Text(
            t.favorites.emptyMoviesHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
          ),
        ],
      ),
    );
  }
}
