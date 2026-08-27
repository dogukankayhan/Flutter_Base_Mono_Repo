import 'dart:isolate';

import 'package:flutter_kit_network/core/network/api/api_manager_interface.dart';
import 'package:flutter_kit_network/core/network/error/api_error.dart';
import 'package:flutter_kit_network/core/network/error/api_exception.dart';
import 'package:flutter_kit_network/core/utils/result.dart';

import '../../domain/entity/evolution_chain_entity.dart';
import '../../domain/entity/pokemon_brief_entity.dart';
import '../../domain/entity/pokemon_entity.dart';
import '../../domain/entity/pokemon_species_entity.dart';
import '../../domain/repository/pokemon_repository.dart';
import '../../service/api/pokemon_api.dart';
import '../dto/evolution_chain_dto.dart';
import '../dto/pokemon_brief_dto.dart';
import '../dto/pokemon_dto.dart';
import '../dto/pokemon_species_dto.dart';

class PokemonRepositoryImpl implements PokemonRepository {
  final ApiManager _api;
  final int pageSize;

  PokemonRepositoryImpl(this._api, {this.pageSize = 20});

  // Cached after the first search — never re-fetched within the same session.
  List<PokemonBrief>? _allBriefs;

  @override
  Future<Result<(List<Pokemon>, bool, int), ApiError>> page(int offset) {
    return pageWithSize(pageSize, offset);
  }

  @override
  Future<Result<(List<Pokemon>, bool, int), ApiError>> pageWithSize(
    int size,
    int offset,
  ) async {
    try {
      final briefs = await _listPokemon(limit: size, offset: offset);
      final details = await _batchFetchDetails(briefs, concurrency: 5);
      final hasMore = briefs.isNotEmpty && briefs.length == size;
      return Ok((details, hasMore, offset + briefs.length));
    } on ApiException catch (e) {
      return Err(e.error);
    } catch (e) {
      return Err(ApiError(message: e.toString()));
    }
  }

  @override
  Future<Result<(List<Pokemon>, bool, int), ApiError>> pageByType(
    String type,
    int size,
    int offset,
  ) async {
    try {
      final briefs = await _filterByType(type);
      final batch = briefs.skip(offset).take(size).toList();
      final details = await _batchFetchDetails(batch, concurrency: 5);
      final hasMore = (offset + batch.length) < briefs.length;
      return Ok((details, hasMore, offset + batch.length));
    } on ApiException catch (e) {
      return Err(e.error);
    } catch (e) {
      return Err(ApiError(message: e.toString()));
    }
  }

  @override
  Future<Result<(List<Pokemon>, bool, int), ApiError>> pageSearch(
    String query,
    int size,
    int offset,
  ) async {
    try {
      _allBriefs ??= await _listPokemon(limit: 1302, offset: 0);
      final filtered = _allBriefs!
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      final batch = filtered.skip(offset).take(size).toList();
      final details = await _batchFetchDetails(batch, concurrency: 5);
      final hasMore = (offset + batch.length) < filtered.length;
      return Ok((details, hasMore, offset + batch.length));
    } on ApiException catch (e) {
      return Err(e.error);
    } catch (e) {
      return Err(ApiError(message: e.toString()));
    }
  }

  @override
  Future<Result<Pokemon, ApiError>> getById(int id) async {
    try {
      return Ok(await _getDetailByName(id.toString()));
    } on ApiException catch (e) {
      return Err(e.error);
    } catch (e) {
      return Err(ApiError(message: e.toString()));
    }
  }

  @override
  Future<Result<Pokemon, ApiError>> getByName(String name) async {
    try {
      return Ok(await _getDetailByName(name));
    } on ApiException catch (e) {
      return Err(e.error);
    } catch (e) {
      return Err(ApiError(message: e.toString()));
    }
  }

  @override
  Future<Result<PokemonSpecies, ApiError>> getSpecies(String url) async {
    try {
      final id = url.split('/').where((e) => e.isNotEmpty).last;
      final response = await _api.get<PokemonSpeciesDto>(
        path: GetPokemonSpeciesEndpoint.path(id),
        fromJson: PokemonSpeciesDto.fromJson,
      );
      return Ok(await Isolate.run(() => response.data.toDomain()));
    } on ApiException catch (e) {
      return Err(e.error);
    } catch (e) {
      return Err(ApiError(message: e.toString()));
    }
  }

  @override
  Future<Result<EvolutionChain, ApiError>> getEvolutionChain(String url) async {
    try {
      final id = url.split('/').where((e) => e.isNotEmpty).last;
      final response = await _api.get<EvolutionChainDto>(
        path: GetEvolutionChainEndpoint.path(id),
        fromJson: EvolutionChainDto.fromJson,
      );
      return Ok(await Isolate.run(() => response.data.toDomain()));
    } on ApiException catch (e) {
      return Err(e.error);
    } catch (e) {
      return Err(ApiError(message: e.toString()));
    }
  }

  Future<List<PokemonBrief>> _listPokemon({
    required int limit,
    required int offset,
  }) async {
    final response = await _api.get<List<PokemonBriefDto>>(
      path: ListPokemonEndpoint.path,
      query: ListPokemonEndpoint.query(limit: limit, offset: offset),
      fromJson: PokemonBriefDto.fromJson,
      listWrapperKey: ListPokemonEndpoint.listWrapperKey,
    );
    return Isolate.run(() => response.data.map((dto) => dto.toDomain()).toList());
  }

  Future<List<PokemonBrief>> _filterByType(String type) async {
    final response = await _api.get<List<PokemonBriefDto>>(
      path: FilterPokemonByTypeEndpoint.path(type),
      extractor: (data) {
        final pokemon = (data as Map<String, dynamic>)['pokemon'] as List;
        return pokemon
            .map((e) => PokemonBriefDto.fromJson(e['pokemon'] as Map<String, dynamic>))
            .toList();
      },
    );
    return Isolate.run(() => response.data.map((dto) => dto.toDomain()).toList());
  }

  Future<Pokemon> _getDetailByName(String name, {bool includeMoves = true}) async {
    final response = await _api.get<PokemonDto>(
      path: GetPokemonDetailEndpoint.path(name),
      fromJson: (json) => PokemonDto.fromJson(json, includeMoves: includeMoves),
    );
    return Isolate.run(() => response.data.toDomain());
  }

  Future<Pokemon> _getDetailByUrl(String url, {bool includeMoves = true}) {
    final name = url.split('/').where((e) => e.isNotEmpty).last;
    return _getDetailByName(name, includeMoves: includeMoves);
  }

  // Batch fetch with concurrency limit to prevent network congestion.
  // Failures are swallowed per-item so a single bad request doesn't wipe the page.
  Future<List<Pokemon>> _batchFetchDetails(
    List<PokemonBrief> briefs, {
    int concurrency = 5,
  }) async {
    final results = <Pokemon>[];
    for (var i = 0; i < briefs.length; i += concurrency) {
      final batch = briefs.skip(i).take(concurrency).toList();
      final batchResults = await Future.wait(
        batch.map(
          (b) => _getDetailByUrl(b.url, includeMoves: false)
              .then<Pokemon?>((p) => p)
              .onError((_, _) => null),
        ),
      );
      results.addAll(batchResults.whereType<Pokemon>());
    }
    return results;
  }
}
