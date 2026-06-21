import 'package:flutter_base_kit/core/domain/entity/pokemon_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_kit_core/base_bloc/base_bloc.dart';

import 'compare_event.dart';
import 'compare_state.dart';

class CompareBloc extends BaseBloc<CompareEvent, CompareState> {
  CompareBloc({required List<Pokemon> pokemons})
      : super(CompareState(pokemons: List.unmodifiable(pokemons))) {
    on<ComparePokemonRemoved>(_onRemoved);
  }

  void _onRemoved(ComparePokemonRemoved event, Emitter<CompareState> emit) {
    final updated = state.pokemons.where((p) => p.id != event.pokemonId).toList();
    if (updated.isEmpty) return;
    emit(CompareState(pokemons: List.unmodifiable(updated)));
  }
}
