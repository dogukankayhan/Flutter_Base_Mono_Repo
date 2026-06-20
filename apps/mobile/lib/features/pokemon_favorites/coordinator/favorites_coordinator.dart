import 'package:flutter/material.dart';
import 'package:flutter_base_kit/core/domain/entity/pokemon_entity.dart';
import 'package:go_router/go_router.dart';

import '../../shell/shell_coordinator.dart';

final class PokemonFavoritesCoordinator {
  static void showDetail(BuildContext context, Pokemon pokemon) {
    context.push(
      '${ShellCoordinator.appointmentsPath}/pokemon/${pokemon.id}',
      extra: pokemon,
    );
  }
}
