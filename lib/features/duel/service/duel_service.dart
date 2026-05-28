// lib/features/duel/services/duel_service.dart

import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

const int maxDuelPlayers = 4;

class DuelService {
  final _client = Supabase.instance.client;

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final code = List.generate(
      4,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return 'VG-$code';
  }

  Future<String> createRoom({
    required String playerId,
    required String playerName,
    required int playerRankIndex,
    required String gameKey,
    required List<int> countryIds,
    required List<int> roundTypes,
    required List<Map<String, dynamic>> spaceRounds,
    required List<int> gemstoneIds,
    required List<int> gemstoneRoundTypes,
  }) async {
    final code = _generateCode();

    // Vérifie que le code n'existe pas
    final existing = await _client
        .from('matches')
        .select('code')
        .eq('code', code)
        .maybeSingle();

    if (existing != null) {
      return createRoom(
        playerId: playerId,
        playerName: playerName,
        playerRankIndex: playerRankIndex,
        gameKey: gameKey,
        countryIds: countryIds,
        roundTypes: roundTypes,
        spaceRounds: spaceRounds,
        gemstoneIds: gemstoneIds,
        gemstoneRoundTypes: gemstoneRoundTypes,
      );
    }

    await _client.from('matches').insert({
      'code': code,
      'status': 'waiting',
      'game_key': gameKey,
      'country_ids': countryIds,
      'round_types': roundTypes,
      'space_rounds': spaceRounds,
      'gemstone_ids': gemstoneIds,
      'gemstone_round_types': gemstoneRoundTypes,
      'host_player_id': playerId,
      'players': [
        _buildPlayerPayload(
          id: playerId,
          name: playerName,
          rankIndex: playerRankIndex,
        ),
      ],
      // Legacy columns kept populated so existing nullable/NOT NULL schema
      // constraints do not block the new multi-player payload.
      'player_a_name': playerName,
      'player_a_rank_index': playerRankIndex,
      'player_a_ready': false,
      'player_a_results': [],
      'player_b_results': [],
    });

    return code;
  }

  Map<String, dynamic> _buildPlayerPayload({
    required String id,
    required String name,
    required int rankIndex,
  }) {
    return {
      'id': id,
      'name': name,
      'rankIndex': rankIndex,
      'ready': false,
      'results': [],
    };
  }

  Future<String?> joinRoom({
    required String code,
    required String playerName,
    required int playerRankIndex,
  }) async {
    final playerId = await _client.rpc<String?>(
      'join_match',
      params: {
        'p_code': code,
        'p_player_name': playerName,
        'p_rank_index': playerRankIndex,
      },
    );
    return playerId;
  }

  Future<void> setReady({
    required String code,
    required String playerId,
    required bool ready,
  }) async {
    await _client.rpc<void>(
      'set_player_ready',
      params: {'p_code': code, 'p_player_id': playerId, 'p_ready': ready},
    );
  }

  Future<void> setStatus(String code, String status) async {
    await _client.from('matches').update({'status': status}).eq('code', code);
  }

  Future<void> setSelectedGame(String code, String gameKey) async {
    await _client.rpc<void>(
      'set_match_game',
      params: {'p_code': code, 'p_game_key': gameKey},
    );
  }

  Future<void> submitRoundResult({
    required String code,
    required String playerId,
    required int roundIndex,
    required bool correct,
    required int timeSeconds,
    int score = 0,
    double? differenceMillionKm,
  }) async {
    final result = <String, dynamic>{
      'roundIndex': roundIndex,
      'correct': correct,
      'timeSeconds': timeSeconds,
      'score': score,
    };
    if (differenceMillionKm != null) {
      result['differenceMillionKm'] = differenceMillionKm;
    }

    await _client.rpc<void>(
      'submit_player_result',
      params: {
        'p_code': code,
        'p_player_id': playerId,
        'p_round_index': roundIndex,
        'p_result': result,
      },
    );
  }

  Future<Map<String, dynamic>?> getRoom(String code) async {
    return await _client
        .from('matches')
        .select()
        .eq('code', code)
        .maybeSingle();
  }

  Stream<Map<String, dynamic>?> watchRoom(String code) {
    return _client
        .from('matches')
        .stream(primaryKey: ['code'])
        .eq('code', code)
        .map((list) => list.isNotEmpty ? list.first : null);
  }

  Future<void> deleteRoom(String code) async {
    await _client.from('matches').delete().eq('code', code);
  }
}
