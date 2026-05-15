// lib/features/duel/services/duel_service.dart

import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    required String playerName,
    required int playerRankIndex,
    required String gameKey,
    required List<int> countryIds,
    required List<int> roundTypes,
    required List<Map<String, int>> spaceRounds,
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
      'player_a_name': playerName,
      'player_a_rank_index': playerRankIndex,
      'player_a_ready': false,
      'player_a_results': [],
      'player_b_results': [],
    });

    return code;
  }

  Future<bool> joinRoom({
    required String code,
    required String playerName,
    required int playerRankIndex,
  }) async {
    final match = await _client
        .from('matches')
        .select()
        .eq('code', code)
        .eq('status', 'waiting')
        .maybeSingle();

    if (match == null) return false;
    if (match['player_b_name'] != null) return false;

    await _client
        .from('matches')
        .update({
          'player_b_name': playerName,
          'player_b_rank_index': playerRankIndex,
          'player_b_ready': false,
        })
        .eq('code', code);

    return true;
  }

  Future<void> setReady({
    required String code,
    required String playerId,
    required bool ready,
  }) async {
    final column = playerId == 'player_a' ? 'player_a_ready' : 'player_b_ready';
    await _client.from('matches').update({column: ready}).eq('code', code);
  }

  Future<void> setStatus(String code, String status) async {
    await _client.from('matches').update({'status': status}).eq('code', code);
  }

  Future<void> setSelectedGame(String code, String gameKey) async {
    try {
      await _client
          .from('matches')
          .update({'game_key': gameKey})
          .eq('code', code);
    } catch (_) {
      // Older Supabase schemas do not have game_key yet. Flags remains the
      // default multiplayer game, so room creation and existing duels stay usable.
    }
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
    final column = playerId == 'player_a'
        ? 'player_a_results'
        : 'player_b_results';

    // Récupère les résultats actuels
    final match = await _client
        .from('matches')
        .select(column)
        .eq('code', code)
        .single();

    final currentResults = List<Map<String, dynamic>>.from(match[column] ?? []);
    final result = <String, dynamic>{
      'correct': correct,
      'timeSeconds': timeSeconds,
      'score': score,
    };
    if (differenceMillionKm != null) {
      result['differenceMillionKm'] = differenceMillionKm;
    }
    currentResults.add(result);

    await _client
        .from('matches')
        .update({column: currentResults})
        .eq('code', code);
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
