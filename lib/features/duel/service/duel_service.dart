// lib/features/duel/services/duel_service.dart

import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class DuelService {
  final _client = Supabase.instance.client;

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final code = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'VG-$code';
  }

  Future<String> createRoom({
    required String playerName,
    required List<int> countryIds,
    required List<int> roundTypes,
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
        countryIds: countryIds,
        roundTypes: roundTypes,
      );
    }

    await _client.from('matches').insert({
      'code': code,
      'status': 'waiting',
      'country_ids': countryIds,
      'round_types': roundTypes,
      'player_a_name': playerName,
      'player_a_ready': false,
      'player_a_results': [],
      'player_b_results': [],
    });

    return code;
  }

  Future<bool> joinRoom({
    required String code,
    required String playerName,
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
        .update({'player_b_name': playerName, 'player_b_ready': false})
        .eq('code', code);

    return true;
  }

  Future<void> setReady({
    required String code,
    required String playerId,
    required bool ready,
  }) async {
    final column = playerId == 'player_a' ? 'player_a_ready' : 'player_b_ready';
    await _client
        .from('matches')
        .update({column: ready})
        .eq('code', code);
  }

  Future<void> setStatus(String code, String status) async {
    await _client
        .from('matches')
        .update({'status': status})
        .eq('code', code);
  }

  Future<void> submitRoundResult({
    required String code,
    required String playerId,
    required int roundIndex,
    required bool correct,
    required int timeSeconds,
  }) async {
    final column = playerId == 'player_a' ? 'player_a_results' : 'player_b_results';

    // Récupère les résultats actuels
    final match = await _client
        .from('matches')
        .select(column)
        .eq('code', code)
        .single();

    final currentResults = List<Map<String, dynamic>>.from(match[column] ?? []);
    currentResults.add({
      'correct': correct,
      'timeSeconds': timeSeconds,
    });

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
    await _client
        .from('matches')
        .delete()
        .eq('code', code);
  }
}