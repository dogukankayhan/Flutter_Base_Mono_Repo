import 'package:flutter_base_kit/core/data/dto/evolution_chain_dto.dart';
import 'package:flutter_base_kit/core/domain/entity/evolution_chain_entity.dart';
import 'package:flutter_kit_network/core/network/api/api_manager_interface.dart';
import '../../domain/entity/pokemon_brief_entity.dart';
import '../../domain/entity/pokemon_entity.dart';
import '../../domain/entity/pokemon_species_entity.dart';
import '../dto/pokemon_brief_dto.dart';
import '../dto/pokemon_dto.dart';
import '../dto/pokemon_species_dto.dart';

/// Interface for Pokemon remote data operations
abstract class PokemonRemoteDataSource {
  Future<List<PokemonBrief>> listPokemon({int limit = 20, int offset = 0});
  Future<Pokemon> getDetailByName(String name);
  Future<Pokemon> getDetailByUrl(String url);
  Future<List<PokemonBrief>> filterByType(String type);
  Future<List<PokemonBrief>> searchPokemon(String query);
  Future<PokemonSpecies> getSpeciesByUrl(String url);
  Future<EvolutionChain> getEvolutionChain(String url);
}

/// Remote datasource for Pokemon API implementation
class PokemonRemoteDataSourceImpl implements PokemonRemoteDataSource {
  final ApiManager _api;

  PokemonRemoteDataSourceImpl({required ApiManager api}) : _api = api;

  @override
  Future<List<PokemonBrief>> listPokemon({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _api.get<List<PokemonBrief>>(
      path: 'pokemon',
      query: {'limit': limit, 'offset': offset},
      extractor: (data) {
        final results = (data as Map<String, dynamic>)['results'] as List;
        return results
            .map(
              (e) => PokemonBriefDto.fromJson(
                (e as Map).cast<String, dynamic>(),
              ).toDomain(),
            )
            .toList();
      },
    );

    return response.data;
  }

  @override
  Future<Pokemon> getDetailByName(String name) async {
    final response = await _api.get<Pokemon>(
      path: 'pokemon/$name',
      fromJson: (json) => PokemonDto.fromJson(json).toDomain(),
    );

    return response.data;
  }

  @override
  Future<Pokemon> getDetailByUrl(String url) async {
    final name = url.split('/').where((e) => e.isNotEmpty).last;
    return getDetailByName(name);
  }

  @override
  Future<List<PokemonBrief>> filterByType(String type) async {
    final response = await _api.get<List<PokemonBrief>>(
      path: 'type/$type',
      extractor: (data) {
        final pokemon = (data as Map<String, dynamic>)['pokemon'] as List;
        return pokemon.map((e) {
          final pokemonData = e['pokemon'] as Map<String, dynamic>;
          return PokemonBriefDto.fromJson(pokemonData).toDomain();
        }).toList();
      },
    );

    return response.data;
  }

  @override
  Future<List<PokemonBrief>> searchPokemon(String query) async {
    final response = await _api.get<List<PokemonBrief>>(
      path: 'pokemon',
      query: {'limit': 1000},
      extractor: (data) {
        final results = (data as Map<String, dynamic>)['results'] as List;
        return results
            .map(
              (e) => PokemonBriefDto.fromJson(
                (e as Map).cast<String, dynamic>(),
              ).toDomain(),
            )
            .toList();
      },
      priority: RequestPriority.high,
    );

    return response.data
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<PokemonSpecies> getSpeciesByUrl(String url) async {
    // URL format: https://pokeapi.co/api/v2/pokemon-species/1/
    final parts = url.split('/').where((e) => e.isNotEmpty).toList();
    final id = parts.last;

    final response = await _api.get<PokemonSpecies>(
      path: 'pokemon-species/$id',
      fromJson: (json) => PokemonSpeciesDto.fromJson(json).toDomain(),
    );
    return response.data;
  }

  @override
  Future<EvolutionChain> getEvolutionChain(String url) async {
    // URL format: https://pokeapi.co/api/v2/evolution-chain/1/
    final parts = url.split('/').where((e) => e.isNotEmpty).toList();
    final id = parts.last;

    final response = await _api.get<EvolutionChain>(
      path: 'evolution-chain/$id',
      fromJson: (json) => EvolutionChainDto.fromJson(json).toDomain(),
    );
    return response.data;
  }
}
