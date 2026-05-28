// lib/features/duel/providers/duel_provider.dart

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../data/repositories/country_repository.dart';
import '../../../data/models/country.dart';
import '../../../data/services/hive_service.dart';
import '../../flag_game/models/flag_round.dart';
import '../../gemstone_game/models/gemstone.dart';
import '../../gemstone_game/models/gemstone_round.dart';
import '../../shared/game_scoring.dart';
import '../service/duel_service.dart';
import '../../flag_game/providers/flag_game_provider.dart';
import '../../space_game/models/space_distance_round.dart';
import '../../space_game/models/space_orbit_round.dart';
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
const duelGameSpaceOrbit = DuelGameOption(
  key: 'space_orbit',
  labelKey: 'space_orbit_game',
);
const duelGameGemstones = DuelGameOption(
  key: 'gemstones',
  labelKey: 'gemstones',
);
const duelGameOptions = [
  duelGameFlags,
  duelGameSpace,
  duelGameSpaceOrbit,
  duelGameGemstones,
];

// ─── Player State ───────────────────────────────────────────────────────────

class DuelPlayer {
  final String id;
  final String name;
  final int rankIndex;
  final bool ready;
  final List<DuelRoundResult> results;

  const DuelPlayer({
    required this.id,
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

// ─── State ──────────────────────────────────────────────────────────────────

class DuelState {
  final DuelPhase phase;
  final DuelRole? role;
  final String? playerId;
  final String? roomCode;
  final DuelPlayer? me;
  final DuelPlayer? opponent;
  final List<DuelPlayer> players;
  final String? error;
  final String selectedGameKey;

  // Jeu en cours
  final List<Country> countries; // les 10 pays de la run
  final List<Country> options; // les 6 options du round courant
  final List<int> roundTypes; // 0 = nameToFlag, 1 = flagToName
  final List<SpaceDistanceRound> spaceRounds;
  final List<SpaceOrbitRound> orbitRounds;
  final double spaceGuessMillionKm;
  final double? submittedSpaceGuessMillionKm;
  final List<Gemstone> gemstonesRun;
  final List<Gemstone> gemstoneOptions;
  final List<int> gemstoneRoundTypes; // 0 = nameToImage, 1 = imageToName
  final int currentRound;
  final int timeSeconds;
  final bool? isCorrect;
  final int? selectedCountryId;
  final int? selectedOrbitPlanetId;
  final int? selectedGemstoneId;
  final int countdownValue; // 3, 2, 1
  final bool isRunFinished;

  const DuelState({
    this.phase = DuelPhase.idle,
    this.role,
    this.playerId,
    this.roomCode,
    this.me,
    this.opponent,
    this.players = const [],
    this.error,
    this.selectedGameKey = 'flags',
    this.countries = const [],
    this.options = const [],
    this.roundTypes = const [],
    this.spaceRounds = const [],
    this.orbitRounds = const [],
    this.spaceGuessMillionKm = 1000,
    this.submittedSpaceGuessMillionKm,
    this.gemstonesRun = const [],
    this.gemstoneOptions = const [],
    this.gemstoneRoundTypes = const [],
    this.currentRound = 0,
    this.timeSeconds = 0,
    this.isCorrect,
    this.selectedCountryId,
    this.selectedOrbitPlanetId,
    this.selectedGemstoneId,
    this.countdownValue = 3,
    this.isRunFinished = false,
  });

  Country? get currentCountry =>
      currentRound < countries.length ? countries[currentRound] : null;
  SpaceDistanceRound? get currentSpaceRound =>
      currentRound < spaceRounds.length ? spaceRounds[currentRound] : null;
  SpaceOrbitRound? get currentOrbitRound =>
      currentRound < orbitRounds.length ? orbitRounds[currentRound] : null;
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
  List<DuelPlayer> get opponents =>
      players.where((player) => player.id != playerId).toList();
  bool get opponentJoined => players.length >= 2;
  bool get roomIsFull => players.length >= maxDuelPlayers;
  bool get allReady =>
      players.length >= 2 && players.every((player) => player.ready);
  bool get bothReady => allReady;
  bool get isSpaceGame => selectedGameKey == duelGameSpace.key;
  bool get isSpaceOrbitGame => selectedGameKey == duelGameSpaceOrbit.key;
  bool get isGemstoneGame => selectedGameKey == duelGameGemstones.key;
  int get totalRounds {
    if (isSpaceGame) return spaceRounds.length;
    if (isSpaceOrbitGame) return orbitRounds.length;
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
    String? playerId,
    String? roomCode,
    DuelPlayer? me,
    DuelPlayer? opponent,
    List<DuelPlayer>? players,
    String? error,
    String? selectedGameKey,
    List<Country>? countries,
    List<Country>? options,
    List<int>? roundTypes,
    List<SpaceDistanceRound>? spaceRounds,
    List<SpaceOrbitRound>? orbitRounds,
    double? spaceGuessMillionKm,
    double? submittedSpaceGuessMillionKm,
    List<Gemstone>? gemstonesRun,
    List<Gemstone>? gemstoneOptions,
    List<int>? gemstoneRoundTypes,
    int? currentRound,
    int? timeSeconds,
    bool? isCorrect,
    int? selectedCountryId,
    int? selectedOrbitPlanetId,
    int? selectedGemstoneId,
    int? countdownValue,
    bool? isRunFinished,
  }) {
    return DuelState(
      phase: phase ?? this.phase,
      role: role ?? this.role,
      playerId: playerId ?? this.playerId,
      roomCode: roomCode ?? this.roomCode,
      me: me ?? this.me,
      opponent: opponent ?? this.opponent,
      players: players ?? this.players,
      error: error ?? this.error,
      selectedGameKey: selectedGameKey ?? this.selectedGameKey,
      countries: countries ?? this.countries,
      options: options ?? this.options,
      roundTypes: roundTypes ?? this.roundTypes,
      spaceRounds: spaceRounds ?? this.spaceRounds,
      orbitRounds: orbitRounds ?? this.orbitRounds,
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
      selectedOrbitPlanetId:
          selectedOrbitPlanetId ?? this.selectedOrbitPlanetId,
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
      final playerId = DateTime.now().microsecondsSinceEpoch.toString();
      final rankIndex = HiveService().getCurrentRankIndex();
      // Génère les données nécessaires à chaque jeu pour que l'hôte puisse
      // encore changer de mode dans le lobby sans recréer la room.
      final allCountries = await _countryRepo.getCountries();
      allCountries.shuffle();
      final selectedCountries = allCountries.take(10).toList();
      final countryIds = selectedCountries.map((c) => c.id).toList();
      final roundTypes = buildAlternatingFlagRoundTypes();
      final spaceRounds = generateSpaceDistanceRounds();
      final orbitRounds = generateSpaceOrbitRounds();
      final gemstoneRun = generateGemstoneRun();
      final gemstoneRoundTypes = buildAlternatingGemstoneRoundTypes();

      final code = await _service.createRoom(
        playerId: playerId,
        playerName: playerName,
        playerRankIndex: rankIndex,
        gameKey: state.selectedGameKey,
        countryIds: countryIds,
        roundTypes: roundTypes,
        spaceRounds: spaceRounds.asMap().entries.map((entry) {
          final spaceRound = entry.value;
          final orbitRound = orbitRounds[entry.key];
          return {
            'left': spaceRound.leftPlanet.id,
            'right': spaceRound.rightPlanet.id,
            'orbit_lower': orbitRound.lowerPlanet.id,
            'orbit_upper': orbitRound.upperPlanet.id,
            'orbit_correct': orbitRound.correctPlanet.id,
            'orbit_options': orbitRound.options
                .map((planet) => planet.id)
                .toList(),
          };
        }).toList(),
        gemstoneIds: gemstoneRun.map((gemstone) => gemstone.id).toList(),
        gemstoneRoundTypes: gemstoneRoundTypes,
      );

      state = state.copyWith(
        phase: DuelPhase.lobby,
        role: DuelRole.host,
        playerId: playerId,
        roomCode: code,
        me: DuelPlayer(id: playerId, name: playerName, rankIndex: rankIndex),
        players: [
          DuelPlayer(id: playerId, name: playerName, rankIndex: rankIndex),
        ],
        countries: selectedCountries,
        roundTypes: roundTypes,
        spaceRounds: spaceRounds,
        orbitRounds: orbitRounds,
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
      final rankIndex = HiveService().getCurrentRankIndex();
      final playerId = await _service.joinRoom(
        code: code.toUpperCase(),
        playerName: playerName,
        playerRankIndex: rankIndex,
      );

      if (playerId == null) {
        state = state.copyWith(error: 'Room not found or full');
        return false;
      }

      state = state.copyWith(
        phase: DuelPhase.lobby,
        role: DuelRole.guest,
        playerId: playerId,
        roomCode: code.toUpperCase(),
        me: DuelPlayer(id: playerId, name: playerName, rankIndex: rankIndex),
      );

      _listenToRoom(code.toUpperCase());
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to join room');
      return false;
    }
  }

  // ── Toggle ready ──────────────────────────────────────────────────────

  Future<void> toggleReady(AudioPlayer audio) async {
    if (state.roomCode == null || state.me == null) return;

    final newReady = !(state.me!.ready);
    final playerId = state.playerId;
    if (playerId == null) return;

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

    final roomCode = state.roomCode!;
    final previousGameKey = state.selectedGameKey;
    state = state.copyWith(
      selectedGameKey: gameKey,
      me: state.me == null
          ? null
          : DuelPlayer(
              id: state.me!.id,
              name: state.me!.name,
              rankIndex: state.me!.rankIndex,
              ready: false,
              results: state.me!.results,
            ),
      opponent: state.opponent == null
          ? null
          : DuelPlayer(
              id: state.opponent!.id,
              name: state.opponent!.name,
              rankIndex: state.opponent!.rankIndex,
              ready: false,
              results: state.opponent!.results,
            ),
      players: state.players
          .map(
            (player) => DuelPlayer(
              id: player.id,
              name: player.name,
              rankIndex: player.rankIndex,
              ready: false,
              results: player.results,
            ),
          )
          .toList(),
      error: null,
    );

    try {
      await _service.setSelectedGame(roomCode, gameKey);
    } catch (e) {
      state = state.copyWith(
        selectedGameKey: previousGameKey,
        error: 'Failed to select game',
      );
    }
  }

  // ── Écouter les changements Supabase ──────────────────────────────────

  void _listenToRoom(String code) {
    _roomSub?.cancel();
    _roomSub = _service.watchRoom(code).listen((data) async {
      if (data == null) return;

      final status = data['status'] as String;
      final selectedGameKey =
          data['game_key'] as String? ?? state.selectedGameKey;

      final players = _parsePlayers(data['players']);
      final updatedMe = players.firstWhere(
        (player) => player.id == state.playerId,
        orElse: () =>
            state.me ?? DuelPlayer(id: state.playerId ?? '', name: 'Player'),
      );
      final opponents = players
          .where((player) => player.id != state.playerId)
          .toList();
      final opponent = opponents.isEmpty ? null : opponents.first;

      // Charge les données de jeu si guest (première fois)
      if (state.role == DuelRole.guest && state.countries.isEmpty) {
        final countryIds = List<int>.from(data['country_ids'] ?? []);
        final roundTypes = List<int>.from(data['round_types'] ?? []);
        final allCountries = await _countryRepo.getCountries();
        final selected = countryIds
            .map((id) => allCountries.firstWhere((c) => c.id == id))
            .toList();
        final spaceRounds = _parseSpaceRounds(data['space_rounds']);
        final orbitRounds = _parseOrbitRounds(data['space_rounds']);
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
          orbitRounds: orbitRounds,
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
            players: players,
            selectedGameKey: selectedGameKey,
          );
          break;

        case 'countdown':
          if (state.phase != DuelPhase.countdown) {
            state = state.copyWith(
              phase: DuelPhase.countdown,
              me: updatedMe,
              opponent: opponent,
              players: players,
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
              players: players,
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
            players: players,
            selectedGameKey: selectedGameKey,
          );
          break;
      }

      // Détecte quand tous les joueurs ont fini
      if (status == 'playing' && state.isHost) {
        final allFinished =
            players.length >= 2 &&
            players.every(
              (player) => player.results.length >= state.totalRounds,
            );
        if (allFinished) {
          await _service.setStatus(code, 'finished');
        }
      }

      // Auto-start countdown
      if (status == 'waiting' &&
          state.isHost &&
          players.length >= 2 &&
          players.every((player) => player.ready)) {
        await _service.setStatus(code, 'countdown');
      }
    });
  }

  List<DuelPlayer> _parsePlayers(dynamic playersRaw) {
    if (playersRaw == null) return [];
    final list = playersRaw as List;
    return list.map((rawPlayer) {
      final map = rawPlayer as Map<String, dynamic>;
      return DuelPlayer(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? 'Player',
        rankIndex:
            (map['rankIndex'] as int?) ?? (map['rank_index'] as int?) ?? 0,
        ready: map['ready'] as bool? ?? false,
        results: _parseResults(map['results']),
      );
    }).toList();
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

  List<SpaceDistanceRound> _parseSpaceRounds(dynamic roundsRaw) {
    if (roundsRaw == null) return [];
    final list = roundsRaw as List;
    return list.map((roundRaw) {
      final map = roundRaw as Map<String, dynamic>;
      final leftId = map['left'] as int;
      final rightId = map['right'] as int;
      return SpaceDistanceRound(
        leftPlanet: spacePlanets.firstWhere((planet) => planet.id == leftId),
        rightPlanet: spacePlanets.firstWhere((planet) => planet.id == rightId),
      );
    }).toList();
  }

  List<SpaceOrbitRound> _parseOrbitRounds(dynamic roundsRaw) {
    if (roundsRaw == null) return [];
    final list = roundsRaw as List;
    final parsed = <SpaceOrbitRound>[];

    for (final roundRaw in list) {
      final map = roundRaw as Map<String, dynamic>;
      final lowerId = map['orbit_lower'] as int?;
      final upperId = map['orbit_upper'] as int?;
      final correctId = map['orbit_correct'] as int?;
      final optionIdsRaw = map['orbit_options'];
      if (lowerId == null ||
          upperId == null ||
          correctId == null ||
          optionIdsRaw == null) {
        continue;
      }

      final optionIds = List<int>.from(optionIdsRaw as List);
      parsed.add(
        SpaceOrbitRound(
          lowerPlanet: spacePlanets.firstWhere(
            (planet) => planet.id == lowerId,
          ),
          upperPlanet: spacePlanets.firstWhere(
            (planet) => planet.id == upperId,
          ),
          correctPlanet: spacePlanets.firstWhere(
            (planet) => planet.id == correctId,
          ),
          options: optionIds
              .map((id) => spacePlanets.firstWhere((planet) => planet.id == id))
              .toList(),
        ),
      );
    }

    return parsed;
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
        playerId: state.playerId,
        roomCode: state.roomCode,
        me: state.me,
        opponent: state.opponent,
        players: state.players,
        selectedGameKey: state.selectedGameKey,
        countries: state.countries,
        options: state.options,
        roundTypes: state.roundTypes,
        spaceRounds: state.spaceRounds,
        orbitRounds: state.orbitRounds,
        gemstonesRun: state.gemstonesRun,
        gemstoneOptions: state.gemstoneOptions,
        gemstoneRoundTypes: state.gemstoneRoundTypes,
        currentRound: state.currentRound,
        timeSeconds: 0,
        countdownValue: state.countdownValue,
      );
      return;
    }

    if (state.isSpaceOrbitGame) {
      if (state.currentOrbitRound == null) return;
      state = DuelState(
        phase: state.phase,
        role: state.role,
        playerId: state.playerId,
        roomCode: state.roomCode,
        me: state.me,
        opponent: state.opponent,
        players: state.players,
        selectedGameKey: state.selectedGameKey,
        countries: state.countries,
        options: state.options,
        roundTypes: state.roundTypes,
        spaceRounds: state.spaceRounds,
        orbitRounds: state.orbitRounds,
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
      final options = buildGemstoneOptions(correct: state.currentGemstone!);
      state = DuelState(
        phase: state.phase,
        role: state.role,
        playerId: state.playerId,
        roomCode: state.roomCode,
        me: state.me,
        opponent: state.opponent,
        players: state.players,
        selectedGameKey: state.selectedGameKey,
        countries: state.countries,
        options: state.options,
        roundTypes: state.roundTypes,
        spaceRounds: state.spaceRounds,
        orbitRounds: state.orbitRounds,
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
      playerId: state.playerId,
      roomCode: state.roomCode,
      me: state.me,
      opponent: state.opponent,
      players: state.players,
      selectedGameKey: state.selectedGameKey,
      countries: state.countries,
      roundTypes: state.roundTypes,
      spaceRounds: state.spaceRounds,
      orbitRounds: state.orbitRounds,
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
      } else if (state.isSpaceOrbitGame) {
        submitOrbitAnswer(null);
      } else if (state.isGemstoneGame) {
        submitGemstoneAnswer(null);
      } else {
        submitAnswer(null); // timeout
      }
      return;
    }
    state = state.copyWith(timeSeconds: newTime);
  }

  Future<void> submitOrbitAnswer(SpacePlanet? selected) async {
    if (state.phase != DuelPhase.playing) return;
    if (state.isCorrect != null) return;
    if (state.currentOrbitRound == null) return;

    final correct =
        selected != null &&
        selected.id == state.currentOrbitRound!.correctPlanet.id;
    final playerId = state.playerId;
    if (playerId == null) return;
    final score = spaceOrbitScoreForAnswer(
      correct: correct,
      timeSeconds: state.timeSeconds,
    );

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
      id: state.me!.id,
      name: state.me!.name,
      rankIndex: state.me!.rankIndex,
      ready: state.me!.ready,
      results: [...(state.me?.results ?? []), result],
    );

    state = state.copyWith(
      isCorrect: correct,
      selectedOrbitPlanetId: selected?.id ?? -1,
      me: updatedMe,
    );
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
    final playerId = state.playerId;
    if (playerId == null) return;

    // Envoie le résultat à Supabase
    await _service.submitRoundResult(
      code: state.roomCode!,
      playerId: playerId,
      roundIndex: state.currentRound,
      correct: correct,
      timeSeconds: state.timeSeconds,
      score: correct ? fastAnswerScore(state.timeSeconds) : 0,
    );

    // Update local
    final result = DuelRoundResult(
      correct: correct,
      timeSeconds: state.timeSeconds,
      score: correct ? fastAnswerScore(state.timeSeconds) : 0,
    );
    final newResults = <DuelRoundResult>[...(state.me?.results ?? []), result];
    final updatedMe = DuelPlayer(
      id: state.me!.id,
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
    final playerId = state.playerId;
    if (playerId == null) return;
    final score = correct ? fastAnswerScore(state.timeSeconds) : 0;

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
      id: state.me!.id,
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
    final score = spaceDistanceScore(difference);
    final playerId = state.playerId;
    if (playerId == null) return;

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
      id: state.me!.id,
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
