import 'dart:isolate';
import 'package:flutter_base_kit/core/data/dto/evolution_chain_dto.dart';
import 'package:flutter_base_kit/core/domain/entity/evolution_chain_entity.dart';
import 'package:flutter_kit_network/core/network/api/api_manager_interface.dart';
import '../../domain/entity/pokemon_brief_entity.dart';
import '../../domain/entity/pokemon_entity.dart';
import '../../domain/entity/pokemon_species_entity.dart';
import '../dto/pokemon_brief_dto.dart';
import '../dto/pokemon_dto.dart';
import '../dto/pokemon_species_dto.dart';

abstract class PokemonRemoteDataSource {
  Future<List<PokemonBrief>> listPokemon({int limit = 20, int offset = 0});
  Future<List<PokemonBrief>> getAllBriefs();
  Future<Pokemon> getDetailByName(String name, {bool includeMoves = true});
  Future<Pokemon> getDetailByUrl(String url, {bool includeMoves = true});
  Future<List<PokemonBrief>> filterByType(String type);
  Future<List<PokemonBrief>> searchPokemon(String query);
  Future<PokemonSpecies> getSpeciesByUrl(String url);
  Future<EvolutionChain> getEvolutionChain(String url);
}

class PokemonRemoteDataSourceImpl implements PokemonRemoteDataSource {
  final ApiManager _api;

  PokemonRemoteDataSourceImpl({required ApiManager api}) : _api = api;

  @override
  Future<List<PokemonBrief>> getAllBriefs() => listPokemon(limit: 1302);

  @override
  Future<List<PokemonBrief>> listPokemon({int limit = 20, int offset = 0}) async {
    final response = await _api.sendRequest<PokemonBriefDto, List<PokemonBriefDto>>(
      'pokemon',
      fromJson: PokemonBriefDto.fromJson,
      method: RequestMethod.get,
      queryParameters: {'limit': limit, 'offset': offset},
      listWrapperKey: 'results',
    );
    return Isolate.run(() => response.data.map((dto) => dto.toDomain()).toList());
  }

  @override
  Future<Pokemon> getDetailByName(String name, {bool includeMoves = true}) async {
    final response = await _api.sendRequest<PokemonDto, PokemonDto>(
      'pokemon/$name',
      fromJson: (json) => PokemonDto.fromJson(json, includeMoves: includeMoves),
      method: RequestMethod.get,
    );
    return Isolate.run(() => response.data.toDomain());
  }

  @override
  Future<Pokemon> getDetailByUrl(String url, {bool includeMoves = true}) async {
    final name = url.split('/').where((e) => e.isNotEmpty).last;
    return getDetailByName(name, includeMoves: includeMoves);
  }

  @override
  Future<List<PokemonBrief>> filterByType(String type) async {
    final response = await _api.sendRequest<PokemonBriefDto, List<PokemonBriefDto>>(
      'type/$type',
      fromJson: PokemonBriefDto.fromJson,
      method: RequestMethod.get,
      extractor: (data) {
        final pokemon = (data as Map<String, dynamic>)['pokemon'] as List;
        return pokemon
            .map((e) => PokemonBriefDto.fromJson(e['pokemon'] as Map<String, dynamic>))
            .toList();
      },
    );
    return Isolate.run(() => response.data.map((dto) => dto.toDomain()).toList());
  }

  @override
  Future<List<PokemonBrief>> searchPokemon(String query) async {
    final response = await _api.sendRequest<PokemonBriefDto, List<PokemonBriefDto>>(
      'pokemon',
      fromJson: PokemonBriefDto.fromJson,
      method: RequestMethod.get,
      queryParameters: {'limit': 1000},
      listWrapperKey: 'results',
      priority: RequestPriority.high,
    );
    final briefs = await Isolate.run(
      () => response.data.map((dto) => dto.toDomain()).toList(),
    );
    return briefs.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  @override
  Future<PokemonSpecies> getSpeciesByUrl(String url) async {
    final id = url.split('/').where((e) => e.isNotEmpty).last;
    final response = await _api.sendRequest<PokemonSpeciesDto, PokemonSpeciesDto>(
      'pokemon-species/$id',
      fromJson: PokemonSpeciesDto.fromJson,
      method: RequestMethod.get,
    );
    return Isolate.run(() => response.data.toDomain());
  }

  @override
  Future<EvolutionChain> getEvolutionChain(String url) async {
    final id = url.split('/').where((e) => e.isNotEmpty).last;
    final response = await _api.sendRequest<EvolutionChainDto, EvolutionChainDto>(
      'evolution-chain/$id',
      fromJson: EvolutionChainDto.fromJson,
      method: RequestMethod.get,
    );
    return Isolate.run(() => response.data.toDomain());
  }
}
