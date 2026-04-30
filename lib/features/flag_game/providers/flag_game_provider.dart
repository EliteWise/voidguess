import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/provider/locale_provider.dart';
import '../../../data/models/country.dart';
import '../../../data/repositories/country_repository.dart';

// ─── Providers ──────────────────────────────────────────────────────────────

final countryRepositoryProvider = Provider<CountryRepository>((ref) {
  return CountryRepository();
});

final flagGameProvider = StateNotifierProvider<FlagGameNotifier, FlagGameState>((ref) {
  final repository = ref.watch(countryRepositoryProvider);
  return FlagGameNotifier(repository, ref);
});

enum FlagRoundType { nameToFlag, flagToName }

// ─── Result par item ────────────────────────────────────────────────────────

class FlagItemResult {
  final String countryName;
  final String countryCode;
  final bool correct;
  final int timeSeconds;
  final int score;

  const FlagItemResult({
    required this.countryName,
    required this.countryCode,
    required this.correct,
    required this.timeSeconds,
    required this.score,
  });
}

// ─── State ──────────────────────────────────────────────────────────────────

enum FlagGamePhase { waiting, playing, feedback, finished }

class FlagGameState {
  final FlagGamePhase phase;
  final Country? correctCountry;
  final List<Country> options;
  final int currentItemIndex;
  final List<FlagItemResult> results;
  final bool? isCorrect;       // null = pas encore répondu
  final int timeSeconds;
  final List<int> usedCountryIds;
  final bool isLoading;
  final bool isRunFinished;
  final int? selectedCountryId;

  const FlagGameState({
    this.phase = FlagGamePhase.waiting,
    this.correctCountry,
    this.options = const [],
    this.currentItemIndex = 0,
    this.results = const [],
    this.isCorrect,
    this.timeSeconds = 0,
    this.usedCountryIds = const [],
    this.isLoading = true,
    this.isRunFinished = false,
    this.selectedCountryId,
  });

  // Nombre total d'items par run — fixe à 10
  int get totalItems => 10;

  // Score total de la run
  int get totalScore => results.fold(0, (sum, r) => sum + r.score);

  // Nombre de bonnes réponses
  int get correctCount => results.where((r) => r.correct).length;

  FlagRoundType get roundType => currentItemIndex % 2 == 0 ? FlagRoundType.nameToFlag : FlagRoundType.flagToName;

  FlagGameState copyWith({
    FlagGamePhase? phase,
    Country? correctCountry,
    List<Country>? options,
    int? currentItemIndex,
    List<FlagItemResult>? results,
    bool? isCorrect,
    int? timeSeconds,
    List<int>? usedCountryIds,
    bool? isLoading,
    bool? isRunFinished,
    int? selectedCountryId,
  }) {
    return FlagGameState(
      phase: phase ?? this.phase,
      correctCountry: correctCountry ?? this.correctCountry,
      options: options ?? this.options,
      currentItemIndex: currentItemIndex ?? this.currentItemIndex,
      results: results ?? this.results,
      isCorrect: isCorrect ?? this.isCorrect,
      timeSeconds: timeSeconds ?? this.timeSeconds,
      usedCountryIds: usedCountryIds ?? this.usedCountryIds,
      isLoading: isLoading ?? this.isLoading,
      isRunFinished: isRunFinished ?? this.isRunFinished,
      selectedCountryId: selectedCountryId ?? this.selectedCountryId,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class FlagGameNotifier extends StateNotifier<FlagGameState> {
  final CountryRepository _repository;
  final Ref _ref;

  FlagGameNotifier(this._repository, this._ref) : super(const FlagGameState());

  // Démarre une nouvelle run
  Future<void> startRun() async {
    state = const FlagGameState(isLoading: true);
    state = state.copyWith(
      currentItemIndex: 0,
      results: [],
      usedCountryIds: [],
      isRunFinished: false,
    );
    await _loadNextItem();
  }

  // Charge le prochain item
  Future<void> _loadNextItem() async {
    state = state.copyWith(isLoading: true);

    // Récupère un pays random pas encore utilisé dans la run
    final correct = await _repository.getRandomCountry(
      excludeIds: state.usedCountryIds,
    );

    // Récupère les 6 options (bon pays + 5 distracteurs)
    final options = await _repository.getOptions(correct: correct);

    state = state.copyWith(
      phase: FlagGamePhase.playing,
      correctCountry: correct,
      options: options,
      isCorrect: null,
      timeSeconds: 0,
      isLoading: false,
      // Ajoute le pays courant aux utilisés pour ne pas le revoir
      usedCountryIds: [...state.usedCountryIds, correct.id],
    );
  }

  // Appelé chaque seconde par le timer dans le screen
  void tick() {
    if (state.phase != FlagGamePhase.playing) return;

    final newTime = state.timeSeconds + 1;

    // Timer écoulé — 15 secondes max
    if (newTime >= 15) {
      _handleAnswer(correct: false, selectedId: -1);
      return;
    }

    state = state.copyWith(timeSeconds: newTime);
  }

  // L'user a cliqué sur un drapeau
  Future<void> submitAnswer(Country selected) async {
    if (state.phase != FlagGamePhase.playing) return;

    final correct = selected.id == state.correctCountry!.id;
    _handleAnswer(correct: correct, selectedId: selected.id);
  }

  void _handleAnswer({required bool correct, required int selectedId}) {
    final score = correct ? _calculateScore() : 0;

    final locale = _ref.read(localeProvider);

    final result = FlagItemResult(
      countryName: state.correctCountry!.getName(locale),
      correct: correct,
      timeSeconds: state.timeSeconds,
      countryCode: state.correctCountry!.code,
      score: score,
    );

    final newResults = [...state.results, result];
    final isLast = state.currentItemIndex >= state.totalItems - 1;

    state = state.copyWith(
      phase: FlagGamePhase.feedback,
      isCorrect: correct,
      selectedCountryId: selectedId,
      results: newResults,
      isRunFinished: isLast,
    );
  }

  // Appelé après le feedback (0.5s) pour passer à l'item suivant
  Future<void> nextItem() async {
    if (state.isRunFinished) return;
    state = state.copyWith(
      currentItemIndex: state.currentItemIndex + 1,
    );
    await _loadNextItem();
  }

  // Score basé sur la rapidité
  int _calculateScore() {
    final t = state.timeSeconds;
    if (t < 3) return 1000;
    if (t < 7) return 700;
    if (t < 15) return 400;
    return 0;
  }
}

