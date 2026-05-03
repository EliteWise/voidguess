// lib/features/duel/providers/duel_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../data/repositories/country_repository.dart';
import '../../../data/models/country.dart';
import '../service/duel_service.dart';
import '../../flag_game/providers/flag_game_provider.dart';

// ─── Providers ──────────────────────────────────────────────────────────────

final duelServiceProvider = Provider<DuelService>((ref) => DuelService());

final duelProvider = StateNotifierProvider<DuelNotifier, DuelState>((ref) {
  final service = ref.watch(duelServiceProvider);
  final countryRepo = ref.watch(countryRepositoryProvider);
  return DuelNotifier(service, countryRepo);
});

// ─── Enums ──────────────────────────────────────────────────────────────────

enum DuelPhase { idle, lobby, countdown, playing, finished }
enum DuelRole { host, guest }

// ─── Player State ───────────────────────────────────────────────────────────

class DuelPlayer {
  final String name;
  final bool ready;
  final List<DuelRoundResult> results;

  const DuelPlayer({
    required this.name,
    this.ready = false,
    this.results = const [],
  });

  int get correctCount => results.where((r) => r.correct).length;
  int get totalTime => results.fold(0, (sum, r) => sum + r.timeSeconds);
  double get avgTime => results.isEmpty ? 0 : totalTime / results.length;
}

class DuelRoundResult {
  final bool correct;
  final int timeSeconds;

  const DuelRoundResult({
    required this.correct,
    required this.timeSeconds,
  });
}

// ─── State ──────────────────────────────────────────────────────────────────

class DuelState {
  final DuelPhase phase;
  final DuelRole? role;
  final String? roomCode;
  final DuelPlayer? me;
  final DuelPlayer? opponent;
  final String? error;

  // Jeu en cours
  final List<Country> countries;     // les 10 pays de la run
  final List<Country> options;       // les 6 options du round courant
  final List<int> roundTypes;        // 0 = nameToFlag, 1 = flagToName
  final int currentRound;
  final int timeSeconds;
  final bool? isCorrect;
  final int? selectedCountryId;
  final int countdownValue;          // 3, 2, 1
  final bool isRunFinished;

  const DuelState({
    this.phase = DuelPhase.idle,
    this.role,
    this.roomCode,
    this.me,
    this.opponent,
    this.error,
    this.countries = const [],
    this.options = const [],
    this.roundTypes = const [],
    this.currentRound = 0,
    this.timeSeconds = 0,
    this.isCorrect,
    this.selectedCountryId,
    this.countdownValue = 3,
    this.isRunFinished = false,
  });

  Country? get currentCountry =>
      currentRound < countries.length ? countries[currentRound] : null;

  FlagRoundType get currentRoundType =>
      currentRound < roundTypes.length && roundTypes[currentRound] == 1
          ? FlagRoundType.flagToName
          : FlagRoundType.nameToFlag;

  bool get isHost => role == DuelRole.host;
  bool get opponentJoined => opponent != null;
  bool get bothReady => (me?.ready ?? false) && (opponent?.ready ?? false);
  int get totalRounds => countries.length;
  bool get isLastRound => currentRound >= totalRounds - 1;

  DuelState copyWith({
    DuelPhase? phase,
    DuelRole? role,
    String? roomCode,
    DuelPlayer? me,
    DuelPlayer? opponent,
    String? error,
    List<Country>? countries,
    List<Country>? options,
    List<int>? roundTypes,
    int? currentRound,
    int? timeSeconds,
    bool? isCorrect,
    int? selectedCountryId,
    int? countdownValue,
    bool? isRunFinished,
  }) {
    return DuelState(
      phase: phase ?? this.phase,
      role: role ?? this.role,
      roomCode: roomCode ?? this.roomCode,
      me: me ?? this.me,
      opponent: opponent ?? this.opponent,
      error: error ?? this.error,
      countries: countries ?? this.countries,
      options: options ?? this.options,
      roundTypes: roundTypes ?? this.roundTypes,
      currentRound: currentRound ?? this.currentRound,
      timeSeconds: timeSeconds ?? this.timeSeconds,
      isCorrect: isCorrect ?? this.isCorrect,
      selectedCountryId: selectedCountryId ?? this.selectedCountryId,
      countdownValue: countdownValue ?? this.countdownValue,
      isRunFinished: isRunFinished ?? this.isRunFinished,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class DuelNotifier extends StateNotifier<DuelState> {
  final DuelService _service;
  final CountryRepository _countryRepo;
  StreamSubscription<Map<String, dynamic>?>? _roomSub;

  DuelNotifier(this._service, this._countryRepo) : super(const DuelState());

  // ── Créer une room ────────────────────────────────────────────────────

  Future<void> createRoom(String playerName) async {
    try {
      // Génère les 10 pays + round types
      final allCountries = await _countryRepo.getCountries();
      allCountries.shuffle();
      final selected = allCountries.take(10).toList();
      final countryIds = selected.map((c) => c.id).toList();
      final roundTypes = List.generate(10, (i) => i % 2); // alternance

      final code = await _service.createRoom(
        playerName: playerName,
        countryIds: countryIds,
        roundTypes: roundTypes,
      );

      state = state.copyWith(
        phase: DuelPhase.lobby,
        role: DuelRole.host,
        roomCode: code,
        me: DuelPlayer(name: playerName),
        countries: selected,
        roundTypes: roundTypes,
      );

      _listenToRoom(code);
    } catch (e) {
      state = state.copyWith(error: 'Failed to create room');
    }
  }

  // ── Rejoindre une room ────────────────────────────────────────────────

  Future<bool> joinRoom(String code, String playerName) async {
    try {
      final success = await _service.joinRoom(
        code: code.toUpperCase(),
        playerName: playerName,
      );

      if (!success) {
        state = state.copyWith(error: 'Room not found or full');
        return false;
      }

      state = state.copyWith(
        phase: DuelPhase.lobby,
        role: DuelRole.guest,
        roomCode: code.toUpperCase(),
        me: DuelPlayer(name: playerName),
      );

      _listenToRoom(code.toUpperCase());
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to join room');
      return false;
    }
  }

  // ── Toggle ready ──────────────────────────────────────────────────────

  Future<void> toggleReady() async {
    if (state.roomCode == null || state.me == null) return;

    final newReady = !(state.me!.ready);
    final playerId = state.isHost ? 'player_a' : 'player_b';

    await _service.setReady(
      code: state.roomCode!,
      playerId: playerId,
      ready: newReady,
    );
  }

  // ── Écouter les changements Firebase ──────────────────────────────────

  void _listenToRoom(String code) {
    _roomSub?.cancel();
    _roomSub = _service.watchRoom(code).listen((data) async {
      if (data == null) return;

      final status = data['status'] as String;

      // Parse opponent
      DuelPlayer? opponent;
      final oppNameKey = state.isHost ? 'player_b_name' : 'player_a_name';
      final oppReadyKey = state.isHost ? 'player_b_ready' : 'player_a_ready';
      final oppResultsKey = state.isHost ? 'player_b_results' : 'player_a_results';

      if (data[oppNameKey] != null) {
        opponent = DuelPlayer(
          name: data[oppNameKey] as String? ?? 'Player',
          ready: data[oppReadyKey] as bool? ?? false,
          results: _parseResults(data[oppResultsKey]),
        );
      }

      // Parse my ready state
      final myReadyKey = state.isHost ? 'player_a_ready' : 'player_b_ready';
      final myReady = data[myReadyKey] as bool? ?? false;

      final updatedMe = DuelPlayer(
        name: state.me?.name ?? 'Player',
        ready: myReady,
        results: state.me?.results ?? [],
      );

      // Charge les countries si guest (première fois)
      if (state.role == DuelRole.guest && state.countries.isEmpty) {
        final countryIds = List<int>.from(data['country_ids'] ?? []);
        final roundTypes = List<int>.from(data['round_types'] ?? []);
        final allCountries = await _countryRepo.getCountries();
        final selected = countryIds
            .map((id) => allCountries.firstWhere((c) => c.id == id))
            .toList();
        state = state.copyWith(
          countries: selected,
          roundTypes: roundTypes,
        );
      }

      // Update state based on status
      switch (status) {
        case 'waiting':
          state = state.copyWith(
            phase: DuelPhase.lobby,
            me: updatedMe,
            opponent: opponent,
          );
          break;

        case 'countdown':
          if (state.phase != DuelPhase.countdown) {
            state = state.copyWith(
              phase: DuelPhase.countdown,
              me: updatedMe,
              opponent: opponent,
              countdownValue: 3,
            );
          }
          break;

        case 'playing':
          if (state.phase == DuelPhase.countdown) {
            // On passe en playing AVANT l'await pour éviter la ré-entrance :
            // Supabase peut envoyer plusieurs events quasi-simultanés lors de la
            // transition countdown→playing. Sans ça, deux listeners async voient
            // tous les deux phase==countdown et appellent _loadOptions() en parallèle,
            // ce qui corrompt le state (options/me/opponent écrasés avec des données stale).
            state = state.copyWith(
              phase: DuelPhase.playing,
              me: updatedMe,
              opponent: opponent,
            );
            await _loadOptions();
          } else {
            state = state.copyWith(opponent: opponent);
          }
          break;

        case 'finished':
          state = state.copyWith(
            phase: DuelPhase.finished,
            me: updatedMe,
            opponent: opponent,
          );
          break;
      }

      // Détecte quand les deux joueurs ont fini
      if (status == 'playing' && state.isHost) {
        final myResultsCount = state.me?.results.length ?? 0;
        final oppResultsCount = opponent?.results.length ?? 0;

        if (myResultsCount >= 10 && oppResultsCount >= 10) {
          await _service.setStatus(code, 'finished');
        }
      }

      // Auto-start countdown
      if (status == 'waiting' && state.isHost && updatedMe.ready && (opponent?.ready ?? false)) {
        await _service.setStatus(code, 'countdown');
      }
    });
  }

  List<DuelRoundResult> _parseResults(dynamic resultsRaw) {
    if (resultsRaw == null) return [];
    final list = resultsRaw as List;
    return list.map((r) {
      final map = r as Map<String, dynamic>;
      return DuelRoundResult(
        correct: map['correct'] as bool? ?? false,
        timeSeconds: map['timeSeconds'] as int? ?? 0,
      );
    }).toList();
  }

  // ── Countdown ─────────────────────────────────────────────────────────

  Future<void> tickCountdown() async {
    if (state.countdownValue <= 1) {
      // Go !
      if (state.isHost) {
        await _service.setStatus(state.roomCode!, 'playing');
      }
    } else {
      state = state.copyWith(countdownValue: state.countdownValue - 1);
    }
  }

  // ── Gameplay ──────────────────────────────────────────────────────────

  Future<void> _loadOptions() async {
    if (state.currentCountry == null) return;
    final options = await _countryRepo.getOptions(correct: state.currentCountry!);
    state = DuelState(
      phase: state.phase,
      role: state.role,
      roomCode: state.roomCode,
      me: state.me,
      opponent: state.opponent,
      countries: state.countries,
      roundTypes: state.roundTypes,
      currentRound: state.currentRound,
      options: options,
      timeSeconds: 0,
      isCorrect: null,
      selectedCountryId: null,
      countdownValue: state.countdownValue,
    );
  }

  void tick() {
    if (state.phase != DuelPhase.playing) return;
    if (state.isCorrect != null) return; // déjà répondu

    final newTime = state.timeSeconds + 1;
    if (newTime >= 15) {
      submitAnswer(null); // timeout
      return;
    }
    state = state.copyWith(timeSeconds: newTime);
  }

  Future<void> submitAnswer(Country? selected) async {
    if (state.phase != DuelPhase.playing) return;
    if (state.isCorrect != null) return;
    if (state.currentCountry == null) return;

    final correct = selected != null && selected.id == state.currentCountry!.id;
    final playerId = state.isHost ? 'player_a' : 'player_b';

    // Envoie le résultat à Firebase
    await _service.submitRoundResult(
      code: state.roomCode!,
      playerId: playerId,
      roundIndex: state.currentRound,
      correct: correct,
      timeSeconds: state.timeSeconds,
    );

    // Update local
    final result = DuelRoundResult(
      correct: correct,
      timeSeconds: state.timeSeconds,
    );
    final newResults = <DuelRoundResult>[...(state.me?.results ?? []), result];
    final updatedMe = DuelPlayer(
      name: state.me!.name,
      ready: state.me!.ready,
      results: newResults,
    );

    state = state.copyWith(
      isCorrect: correct,
      selectedCountryId: selected?.id ?? -1,
      me: updatedMe,
    );
  }

  Future<void> nextRound() async {
    final nextIndex = state.currentRound + 1;

    if (nextIndex >= state.totalRounds) {
      state = state.copyWith(currentRound: nextIndex);
      return;
    }

    state = state.copyWith(currentRound: nextIndex);
    await _loadOptions();
  }

  // ── Cleanup ───────────────────────────────────────────────────────────

  Future<void> leaveRoom() async {
    _roomSub?.cancel();
    if (state.roomCode != null && state.isHost) {
      await _service.deleteRoom(state.roomCode!);
    }
    state = const DuelState();
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    super.dispose();
  }
}