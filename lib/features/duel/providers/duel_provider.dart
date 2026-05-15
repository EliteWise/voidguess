// lib/features/duel/providers/duel_provider.dart

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../data/repositories/country_repository.dart';
import '../../../data/models/country.dart';
import '../../../data/services/hive_service.dart';
import '../../gemstone_game/models/gemstone.dart';
import '../service/duel_service.dart';
import '../../flag_game/providers/flag_game_provider.dart';
import '../../space_game/models/space_planet.dart';

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

class DuelGameOption {
  final String key;
  final String labelKey;

  const DuelGameOption({required this.key, required this.labelKey});
}

const duelGameFlags = DuelGameOption(key: 'flags', labelKey: 'flags');
const duelGameSpace = DuelGameOption(key: 'space', labelKey: 'space');
const duelGameGemstones = DuelGameOption(
  key: 'gemstones',
  labelKey: 'gemstones',
);
const duelGameOptions = [duelGameFlags, duelGameSpace, duelGameGemstones];

// ─── Player State ───────────────────────────────────────────────────────────

class DuelPlayer {
  final String name;
  final int rankIndex;
  final bool ready;
  final List<DuelRoundResult> results;

  const DuelPlayer({
    required this.name,
    this.rankIndex = 0,
    this.ready = false,
    this.results = const [],
  });

  int get correctCount => results.where((r) => r.correct).length;
  int get totalScore => results.fold(0, (sum, r) => sum + r.score);
  int get totalTime => results.fold(0, (sum, r) => sum + r.timeSeconds);
  double get avgTime => results.isEmpty ? 0 : totalTime / results.length;
}

class DuelRoundResult {
  final bool correct;
  final int timeSeconds;
  final int score;
  final double? differenceMillionKm;

  const DuelRoundResult({
    required this.correct,
    required this.timeSeconds,
    this.score = 0,
    this.differenceMillionKm,
  });
}

class DuelSpaceRound {
  final SpacePlanet leftPlanet;
  final SpacePlanet rightPlanet;

  const DuelSpaceRound({required this.leftPlanet, required this.rightPlanet});

  double get actualDistanceMillionKm {
    return averagePlanetDistanceMillionKm(leftPlanet, rightPlanet);
  }
}

// ─── State ──────────────────────────────────────────────────────────────────

class DuelState {
  final DuelPhase phase;
  final DuelRole? role;
  final String? roomCode;
  final DuelPlayer? me;
  final DuelPlayer? opponent;
  final String? error;
  final String selectedGameKey;

  // Jeu en cours
  final List<Country> countries; // les 10 pays de la run
  final List<Country> options; // les 6 options du round courant
  final List<int> roundTypes; // 0 = nameToFlag, 1 = flagToName
  final List<DuelSpaceRound> spaceRounds;
  final double spaceGuessMillionKm;
  final double? submittedSpaceGuessMillionKm;
  final List<Gemstone> gemstonesRun;
  final List<Gemstone> gemstoneOptions;
  final List<int> gemstoneRoundTypes; // 0 = nameToImage, 1 = imageToName
  final int currentRound;
  final int timeSeconds;
  final bool? isCorrect;
  final int? selectedCountryId;
  final int? selectedGemstoneId;
  final int countdownValue; // 3, 2, 1
  final bool isRunFinished;

  const DuelState({
    this.phase = DuelPhase.idle,
    this.role,
    this.roomCode,
    this.me,
    this.opponent,
    this.error,
    this.selectedGameKey = 'flags',
    this.countries = const [],
    this.options = const [],
    this.roundTypes = const [],
    this.spaceRounds = const [],
    this.spaceGuessMillionKm = 1000,
    this.submittedSpaceGuessMillionKm,
    this.gemstonesRun = const [],
    this.gemstoneOptions = const [],
    this.gemstoneRoundTypes = const [],
    this.currentRound = 0,
    this.timeSeconds = 0,
    this.isCorrect,
    this.selectedCountryId,
    this.selectedGemstoneId,
    this.countdownValue = 3,
    this.isRunFinished = false,
  });

  Country? get currentCountry =>
      currentRound < countries.length ? countries[currentRound] : null;
  DuelSpaceRound? get currentSpaceRound =>
      currentRound < spaceRounds.length ? spaceRounds[currentRound] : null;
  Gemstone? get currentGemstone =>
      currentRound < gemstonesRun.length ? gemstonesRun[currentRound] : null;

  FlagRoundType get currentRoundType =>
      currentRound < roundTypes.length && roundTypes[currentRound] == 1
      ? FlagRoundType.flagToName
      : FlagRoundType.nameToFlag;
  bool get isCurrentGemstoneImageToName =>
      currentRound < gemstoneRoundTypes.length &&
      gemstoneRoundTypes[currentRound] == 1;

  bool get isHost => role == DuelRole.host;
  bool get opponentJoined => opponent != null;
  bool get bothReady => (me?.ready ?? false) && (opponent?.ready ?? false);
  bool get isSpaceGame => selectedGameKey == duelGameSpace.key;
  bool get isGemstoneGame => selectedGameKey == duelGameGemstones.key;
  int get totalRounds {
    if (isSpaceGame) return spaceRounds.length;
    if (isGemstoneGame) return gemstonesRun.length;
    return countries.length;
  }

  bool get isLastRound => currentRound >= totalRounds - 1;
  DuelGameOption get selectedGame => duelGameOptions.firstWhere(
    (game) => game.key == selectedGameKey,
    orElse: () => duelGameFlags,
  );

  DuelState copyWith({
    DuelPhase? phase,
    DuelRole? role,
    String? roomCode,
    DuelPlayer? me,
    DuelPlayer? opponent,
    String? error,
    String? selectedGameKey,
    List<Country>? countries,
    List<Country>? options,
    List<int>? roundTypes,
    List<DuelSpaceRound>? spaceRounds,
    double? spaceGuessMillionKm,
    double? submittedSpaceGuessMillionKm,
    List<Gemstone>? gemstonesRun,
    List<Gemstone>? gemstoneOptions,
    List<int>? gemstoneRoundTypes,
    int? currentRound,
    int? timeSeconds,
    bool? isCorrect,
    int? selectedCountryId,
    int? selectedGemstoneId,
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
      selectedGameKey: selectedGameKey ?? this.selectedGameKey,
      countries: countries ?? this.countries,
      options: options ?? this.options,
      roundTypes: roundTypes ?? this.roundTypes,
      spaceRounds: spaceRounds ?? this.spaceRounds,
      spaceGuessMillionKm: spaceGuessMillionKm ?? this.spaceGuessMillionKm,
      submittedSpaceGuessMillionKm:
          submittedSpaceGuessMillionKm ?? this.submittedSpaceGuessMillionKm,
      gemstonesRun: gemstonesRun ?? this.gemstonesRun,
      gemstoneOptions: gemstoneOptions ?? this.gemstoneOptions,
      gemstoneRoundTypes: gemstoneRoundTypes ?? this.gemstoneRoundTypes,
      currentRound: currentRound ?? this.currentRound,
      timeSeconds: timeSeconds ?? this.timeSeconds,
      isCorrect: isCorrect ?? this.isCorrect,
      selectedCountryId: selectedCountryId ?? this.selectedCountryId,
      selectedGemstoneId: selectedGemstoneId ?? this.selectedGemstoneId,
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
      // Génère les données nécessaires à chaque jeu pour que l'hôte puisse
      // encore changer de mode dans le lobby sans recréer la room.
      final allCountries = await _countryRepo.getCountries();
      allCountries.shuffle();
      final selectedCountries = allCountries.take(10).toList();
      final countryIds = selectedCountries.map((c) => c.id).toList();
      final roundTypes = List.generate(10, (i) => i % 2); // alternance
      final spaceRounds = _generateSpaceRounds();
      final gemstoneRun = _generateGemstoneRun();
      final gemstoneRoundTypes = List.generate(10, (i) => i % 2);

      final code = await _service.createRoom(
        playerName: playerName,
        playerRankIndex: HiveService().getCurrentRankIndex(),
        gameKey: state.selectedGameKey,
        countryIds: countryIds,
        roundTypes: roundTypes,
        spaceRounds: spaceRounds
            .map(
              (round) => {
                'left': round.leftPlanet.id,
                'right': round.rightPlanet.id,
              },
            )
            .toList(),
        gemstoneIds: gemstoneRun.map((gemstone) => gemstone.id).toList(),
        gemstoneRoundTypes: gemstoneRoundTypes,
      );

      state = state.copyWith(
        phase: DuelPhase.lobby,
        role: DuelRole.host,
        roomCode: code,
        me: DuelPlayer(
          name: playerName,
          rankIndex: HiveService().getCurrentRankIndex(),
        ),
        countries: selectedCountries,
        roundTypes: roundTypes,
        spaceRounds: spaceRounds,
        gemstonesRun: gemstoneRun,
        gemstoneRoundTypes: gemstoneRoundTypes,
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
        playerRankIndex: HiveService().getCurrentRankIndex(),
      );

      if (!success) {
        state = state.copyWith(error: 'Room not found or full');
        return false;
      }

      state = state.copyWith(
        phase: DuelPhase.lobby,
        role: DuelRole.guest,
        roomCode: code.toUpperCase(),
        me: DuelPlayer(
          name: playerName,
          rankIndex: HiveService().getCurrentRankIndex(),
        ),
      );

      _listenToRoom(code.toUpperCase());
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to join room');
      return false;
    }
  }

  List<DuelSpaceRound> _generateSpaceRounds() {
    final rounds = <DuelSpaceRound>[];
    final randomPlanets = [...spacePlanets];

    while (rounds.length < 10) {
      randomPlanets.shuffle();
      final left = randomPlanets[0];
      final right = randomPlanets[1];
      final duplicate = rounds.any(
        (round) =>
            (round.leftPlanet.id == left.id &&
                round.rightPlanet.id == right.id) ||
            (round.leftPlanet.id == right.id &&
                round.rightPlanet.id == left.id),
      );
      if (!duplicate) {
        rounds.add(DuelSpaceRound(leftPlanet: left, rightPlanet: right));
      }
    }

    return rounds;
  }

  List<Gemstone> _generateGemstoneRun() {
    final pool = [...gemstones]..shuffle();
    return pool.take(10).toList();
  }

  // ── Toggle ready ──────────────────────────────────────────────────────

  Future<void> toggleReady(AudioPlayer audio) async {
    if (state.roomCode == null || state.me == null) return;

    final newReady = !(state.me!.ready);
    final playerId = state.isHost ? 'player_a' : 'player_b';

    await _service.setReady(
      code: state.roomCode!,
      playerId: playerId,
      ready: newReady,
    );

    await audio.setSource(AssetSource('audio/1v1ready.wav'));
    await audio.resume();
  }

  Future<void> selectGame(String gameKey) async {
    if (!state.isHost || state.roomCode == null) return;
    if (!duelGameOptions.any((game) => game.key == gameKey)) return;

    state = state.copyWith(selectedGameKey: gameKey);
    await _service.setSelectedGame(state.roomCode!, gameKey);
  }

  // ── Écouter les changements Firebase ──────────────────────────────────

  void _listenToRoom(String code) {
    _roomSub?.cancel();
    _roomSub = _service.watchRoom(code).listen((data) async {
      if (data == null) return;

      final status = data['status'] as String;
      final selectedGameKey =
          data['game_key'] as String? ?? state.selectedGameKey;

      // Parse opponent
      DuelPlayer? opponent;
      final oppNameKey = state.isHost ? 'player_b_name' : 'player_a_name';
      final oppRankKey = state.isHost
          ? 'player_b_rank_index'
          : 'player_a_rank_index';
      final oppReadyKey = state.isHost ? 'player_b_ready' : 'player_a_ready';
      final oppResultsKey = state.isHost
          ? 'player_b_results'
          : 'player_a_results';

      if (data[oppNameKey] != null) {
        opponent = DuelPlayer(
          name: data[oppNameKey] as String? ?? 'Player',
          rankIndex: data[oppRankKey] as int? ?? 0,
          ready: data[oppReadyKey] as bool? ?? false,
          results: _parseResults(data[oppResultsKey]),
        );
      }

      // Parse my ready state
      final myReadyKey = state.isHost ? 'player_a_ready' : 'player_b_ready';
      final myRankKey = state.isHost
          ? 'player_a_rank_index'
          : 'player_b_rank_index';
      final myReady = data[myReadyKey] as bool? ?? false;

      final updatedMe = DuelPlayer(
        name: state.me?.name ?? 'Player',
        rankIndex: data[myRankKey] as int? ?? state.me?.rankIndex ?? 0,
        ready: myReady,
        results: state.me?.results ?? [],
      );

      // Charge les données de jeu si guest (première fois)
      if (state.role == DuelRole.guest && state.countries.isEmpty) {
        final countryIds = List<int>.from(data['country_ids'] ?? []);
        final roundTypes = List<int>.from(data['round_types'] ?? []);
        final allCountries = await _countryRepo.getCountries();
        final selected = countryIds
            .map((id) => allCountries.firstWhere((c) => c.id == id))
            .toList();
        final spaceRounds = _parseSpaceRounds(data['space_rounds']);
        final gemstoneIds = List<int>.from(data['gemstone_ids'] ?? []);
        final gemstoneRoundTypes = List<int>.from(
          data['gemstone_round_types'] ?? [],
        );
        final selectedGemstones = gemstoneIds
            .map((id) => gemstones.firstWhere((gemstone) => gemstone.id == id))
            .toList();
        state = state.copyWith(
          countries: selected,
          roundTypes: roundTypes,
          spaceRounds: spaceRounds,
          gemstonesRun: selectedGemstones,
          gemstoneRoundTypes: gemstoneRoundTypes,
        );
      }

      // Update state based on status
      switch (status) {
        case 'waiting':
          state = state.copyWith(
            phase: DuelPhase.lobby,
            me: updatedMe,
            opponent: opponent,
            selectedGameKey: selectedGameKey,
          );
          break;

        case 'countdown':
          if (state.phase != DuelPhase.countdown) {
            state = state.copyWith(
              phase: DuelPhase.countdown,
              me: updatedMe,
              opponent: opponent,
              selectedGameKey: selectedGameKey,
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
              selectedGameKey: selectedGameKey,
            );
            await _loadOptions();
          }
          break;

        case 'finished':
          state = state.copyWith(
            phase: DuelPhase.finished,
            me: updatedMe,
            opponent: opponent,
            selectedGameKey: selectedGameKey,
          );
          break;
      }

      // Détecte quand les deux joueurs ont fini
      if (status == 'playing' && state.isHost) {
        final myResultsCount = state.me?.results.length ?? 0;
        final oppResultsCount = _parseResults(data[oppResultsKey]);

        if (myResultsCount >= state.totalRounds &&
            oppResultsCount.length >= state.totalRounds) {
          await _service.setStatus(code, 'finished');
        }
      }

      // Auto-start countdown
      if (status == 'waiting' &&
          state.isHost &&
          updatedMe.ready &&
          (opponent?.ready ?? false)) {
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
        score: map['score'] as int? ?? 0,
        differenceMillionKm: (map['differenceMillionKm'] as num?)?.toDouble(),
      );
    }).toList();
  }

  List<DuelSpaceRound> _parseSpaceRounds(dynamic roundsRaw) {
    if (roundsRaw == null) return [];
    final list = roundsRaw as List;
    return list.map((roundRaw) {
      final map = roundRaw as Map<String, dynamic>;
      final leftId = map['left'] as int;
      final rightId = map['right'] as int;
      return DuelSpaceRound(
        leftPlanet: spacePlanets.firstWhere((planet) => planet.id == leftId),
        rightPlanet: spacePlanets.firstWhere((planet) => planet.id == rightId),
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
    if (state.isSpaceGame) {
      if (state.currentSpaceRound == null) return;
      state = DuelState(
        phase: state.phase,
        role: state.role,
        roomCode: state.roomCode,
        me: state.me,
        opponent: state.opponent,
        selectedGameKey: state.selectedGameKey,
        countries: state.countries,
        options: state.options,
        roundTypes: state.roundTypes,
        spaceRounds: state.spaceRounds,
        gemstonesRun: state.gemstonesRun,
        gemstoneOptions: state.gemstoneOptions,
        gemstoneRoundTypes: state.gemstoneRoundTypes,
        currentRound: state.currentRound,
        timeSeconds: 0,
        countdownValue: state.countdownValue,
      );
      return;
    }

    if (state.isGemstoneGame) {
      if (state.currentGemstone == null) return;
      final distractors =
          gemstones
              .where((item) => item.id != state.currentGemstone!.id)
              .toList()
            ..shuffle();
      final options = [state.currentGemstone!, ...distractors.take(5)]
        ..shuffle();
      state = DuelState(
        phase: state.phase,
        role: state.role,
        roomCode: state.roomCode,
        me: state.me,
        opponent: state.opponent,
        selectedGameKey: state.selectedGameKey,
        countries: state.countries,
        options: state.options,
        roundTypes: state.roundTypes,
        spaceRounds: state.spaceRounds,
        gemstonesRun: state.gemstonesRun,
        gemstoneOptions: options,
        gemstoneRoundTypes: state.gemstoneRoundTypes,
        currentRound: state.currentRound,
        timeSeconds: 0,
        countdownValue: state.countdownValue,
      );
      return;
    }

    if (state.currentCountry == null) return;
    final options = await _countryRepo.getOptions(
      correct: state.currentCountry!,
    );
    state = DuelState(
      phase: state.phase,
      role: state.role,
      roomCode: state.roomCode,
      me: state.me,
      opponent: state.opponent,
      selectedGameKey: state.selectedGameKey,
      countries: state.countries,
      roundTypes: state.roundTypes,
      spaceRounds: state.spaceRounds,
      gemstonesRun: state.gemstonesRun,
      gemstoneRoundTypes: state.gemstoneRoundTypes,
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
    final maxTime = state.isSpaceGame ? 30 : 15;
    if (newTime >= maxTime) {
      if (state.isSpaceGame) {
        submitSpaceAnswer();
      } else if (state.isGemstoneGame) {
        submitGemstoneAnswer(null);
      } else {
        submitAnswer(null); // timeout
      }
      return;
    }
    state = state.copyWith(timeSeconds: newTime);
  }

  void updateSpaceGuess(double guessMillionKm) {
    if (!state.isSpaceGame || state.isCorrect != null) return;
    state = state.copyWith(spaceGuessMillionKm: guessMillionKm);
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
      score: correct ? _calculateFastAnswerScore() : 0,
    );

    // Update local
    final result = DuelRoundResult(
      correct: correct,
      timeSeconds: state.timeSeconds,
      score: correct ? _calculateFastAnswerScore() : 0,
    );
    final newResults = <DuelRoundResult>[...(state.me?.results ?? []), result];
    final updatedMe = DuelPlayer(
      name: state.me!.name,
      rankIndex: state.me!.rankIndex,
      ready: state.me!.ready,
      results: newResults,
    );

    state = state.copyWith(
      isCorrect: correct,
      selectedCountryId: selected?.id ?? -1,
      me: updatedMe,
    );
  }

  Future<void> submitGemstoneAnswer(Gemstone? selected) async {
    if (state.phase != DuelPhase.playing) return;
    if (state.isCorrect != null) return;
    if (state.currentGemstone == null) return;

    final correct =
        selected != null && selected.id == state.currentGemstone!.id;
    final playerId = state.isHost ? 'player_a' : 'player_b';
    final score = correct ? _calculateFastAnswerScore() : 0;

    await _service.submitRoundResult(
      code: state.roomCode!,
      playerId: playerId,
      roundIndex: state.currentRound,
      correct: correct,
      timeSeconds: state.timeSeconds,
      score: score,
    );

    final result = DuelRoundResult(
      correct: correct,
      timeSeconds: state.timeSeconds,
      score: score,
    );
    final updatedMe = DuelPlayer(
      name: state.me!.name,
      rankIndex: state.me!.rankIndex,
      ready: state.me!.ready,
      results: [...(state.me?.results ?? []), result],
    );

    state = state.copyWith(
      isCorrect: correct,
      selectedGemstoneId: selected?.id ?? -1,
      me: updatedMe,
    );
  }

  Future<void> submitSpaceAnswer() async {
    if (state.phase != DuelPhase.playing) return;
    if (state.isCorrect != null) return;
    if (state.currentSpaceRound == null) return;

    final guess = state.spaceGuessMillionKm;
    final difference =
        (guess - state.currentSpaceRound!.actualDistanceMillionKm).abs();
    final score = _calculateSpaceScore(difference);
    final playerId = state.isHost ? 'player_a' : 'player_b';

    await _service.submitRoundResult(
      code: state.roomCode!,
      playerId: playerId,
      roundIndex: state.currentRound,
      correct: score >= 850,
      timeSeconds: state.timeSeconds,
      score: score,
      differenceMillionKm: difference,
    );

    final result = DuelRoundResult(
      correct: score >= 850,
      timeSeconds: state.timeSeconds,
      score: score,
      differenceMillionKm: difference,
    );
    final updatedMe = DuelPlayer(
      name: state.me!.name,
      rankIndex: state.me!.rankIndex,
      ready: state.me!.ready,
      results: [...(state.me?.results ?? []), result],
    );

    state = state.copyWith(
      isCorrect: score >= 850,
      submittedSpaceGuessMillionKm: guess,
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

  int _calculateFastAnswerScore() {
    final time = state.timeSeconds;
    if (time < 3) return 1000;
    if (time < 7) return 700;
    if (time < 15) return 400;
    return 0;
  }

  int _calculateSpaceScore(double differenceMillionKm) {
    const maxGuessMillionKm = 4500.0;
    final ratio = (differenceMillionKm / maxGuessMillionKm).clamp(0.0, 1.0);
    return (1000 * (1 - ratio)).round();
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
