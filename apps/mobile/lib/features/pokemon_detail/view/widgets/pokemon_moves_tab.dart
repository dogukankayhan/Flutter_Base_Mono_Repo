import 'package:flutter/material.dart';
import 'package:flutter_base_kit/core/domain/entity/pokemon_entity.dart';
import 'package:flutter_base_kit/core/domain/entity/pokemon_move_entity.dart';
import 'package:flutter_base_kit/core/localization/localization_extension.dart';
import '../../../../core/utils/pokemon_utils.dart';

class PokemonMovesTab extends StatefulWidget {
  final Pokemon pokemon;

  const PokemonMovesTab({super.key, required this.pokemon});

  @override
  State<PokemonMovesTab> createState() => _PokemonMovesTabState();
}

class _PokemonMovesTabState extends State<PokemonMovesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const _versionPriorities = [
    'scarlet-violet',
    'legends-arceus',
    'brilliant-diamond-shining-pearl',
    'sword-shield',
    'lets-go-pikachu-lets-go-eevee',
    'ultra-sun-ultra-moon',
    'sun-moon',
    'omega-ruby-alpha-sapphire',
    'x-y',
    'black-2-white-2',
    'black-white',
    'heartgold-soulsilver',
    'platinum',
    'diamond-pearl',
    'emerald',
    'firered-leafgreen',
    'ruby-sapphire',
    'crystal',
    'gold-silver',
    'yellow',
    'red-blue',
  ];

  VersionGroupDetail _getBestDetail(List<VersionGroupDetail> details) {
    if (details.isEmpty) {
      return const VersionGroupDetail(
        levelLearnedAt: 0,
        moveLearnMethod: MoveLearnMethod(name: 'unknown', url: ''),
        versionGroup: VersionGroup(name: 'unknown', url: ''),
      );
    }

    VersionGroupDetail? bestDetail;
    int bestPriority = -1;

    for (final detail in details) {
      final idx = _versionPriorities.indexOf(detail.versionGroup.name);
      final priority = idx == -1 ? _versionPriorities.length : idx;

      if (bestDetail == null || priority < bestPriority) {
        bestDetail = detail;
        bestPriority = priority;
      } else if (priority == bestPriority) {
        if (detail.moveLearnMethod.name == 'level-up' &&
            bestDetail.moveLearnMethod.name != 'level-up') {
          bestDetail = detail;
        }
      }
    }

    return bestDetail!;
  }

  Color _getLearnMethodBgColor(String method) {
    switch (method) {
      case 'level-up':
        return Colors.blue.withValues(alpha: 0.15);
      case 'machine':
        return Colors.purple.withValues(alpha: 0.15);
      case 'egg':
        return Colors.amber.withValues(alpha: 0.15);
      case 'tutor':
        return Colors.teal.withValues(alpha: 0.15);
      default:
        return Colors.grey.withValues(alpha: 0.15);
    }
  }

  Color _getLearnMethodBorderColor(String method) {
    switch (method) {
      case 'level-up':
        return Colors.blue.withValues(alpha: 0.4);
      case 'machine':
        return Colors.purple.withValues(alpha: 0.4);
      case 'egg':
        return Colors.amber.withValues(alpha: 0.4);
      case 'tutor':
        return Colors.teal.withValues(alpha: 0.4);
      default:
        return Colors.grey.withValues(alpha: 0.4);
    }
  }

  Color _getLearnMethodTextColor(String method) {
    switch (method) {
      case 'level-up':
        return Colors.blueAccent;
      case 'machine':
        return Colors.purpleAccent;
      case 'egg':
        return Colors.amberAccent;
      case 'tutor':
        return Colors.tealAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Sort moves: level-up first (by level ascending), then others alphabetically
    final sortedMoves = List<PokemonMove>.from(widget.pokemon.moves);
    sortedMoves.sort((a, b) {
      final detailA = _getBestDetail(a.versionGroupDetails);
      final detailB = _getBestDetail(b.versionGroupDetails);

      final isLevelUpA = detailA.moveLearnMethod.name == 'level-up';
      final isLevelUpB = detailB.moveLearnMethod.name == 'level-up';

      if (isLevelUpA && !isLevelUpB) return -1;
      if (!isLevelUpA && isLevelUpB) return 1;

      if (isLevelUpA && isLevelUpB) {
        final lvlCompare = detailA.levelLearnedAt.compareTo(detailB.levelLearnedAt);
        if (lvlCompare != 0) return lvlCompare;
      }

      return a.move.name.compareTo(b.move.name);
    });

    return CustomScrollView(
      key: const PageStorageKey('moves'),
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final move = sortedMoves[index];
              final bestDetail = _getBestDetail(move.versionGroupDetails);
              final method = bestDetail.moveLearnMethod.name;

              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      PokemonUtils.capitalize(
                        move.move.name.replaceAll('-', ' '),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getLearnMethodBgColor(method),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getLearnMethodBorderColor(method),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        method == 'level-up'
                            ? 'LV. ${bestDetail.levelLearnedAt}'
                            : method == 'machine'
                                ? 'TM'
                                : method.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getLearnMethodTextColor(method),
                        ),
                      ),
                    ),
                    subtitle: Text(
                      context.translations.pokemon.detail.moves.learnMethod(
                        method: method.replaceAll('-', ' '),
                      ),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  if (index < sortedMoves.length - 1) const Divider(),
                ],
              );
            }, childCount: sortedMoves.length),
          ),
        ),
      ],
    );
  }
}
