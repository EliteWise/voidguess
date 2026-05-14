import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/provider/locale_provider.dart';
import '../models/gemstone.dart';

final gemstoneGameProvider =
    StateNotifierProvider<GemstoneGameNotifier, GemstoneGameState>((ref) {
      return GemstoneGameNotifier(ref);
    });

enum GemstoneRoundType { nameToImage, imageToName }

enum GemstoneGamePhase { waiting, playing, feedback }

class GemstoneItemResult {
  final String gemstoneName;
  final String assetPath;
  final bool correct;
  final int timeSeconds;
  final int score;

  const GemstoneItemResult({
    required this.gemstoneName,
    required this.assetPath,
    required this.correct,
    required this.timeSeconds,
    required this.score,
  });
}

class GemstoneGameState {
  final GemstoneGamePhase phase;
  final Gemstone? correctGemstone;
  final List<Gemstone> options;
  final int currentItemIndex;
  final List<GemstoneItemResult> results;
  final bool? isCorrect;
  final int timeSeconds;
  final List<int> usedGemstoneIds;
  final bool isLoading;
  final bool isRunFinished;
  final int? selectedGemstoneId;

  const GemstoneGameState({
    this.phase = GemstoneGamePhase.waiting,
    this.correctGemstone,
    this.options = const [],
    this.currentItemIndex = 0,
    this.results = const [],
    this.isCorrect,
    this.timeSeconds = 0,
    this.usedGemstoneIds = const [],
    this.isLoading = true,
    this.isRunFinished = false,
    this.selectedGemstoneId,
  });

  int get totalItems => 10;

  int get totalScore => results.fold(0, (sum, result) => sum + result.score);

  int get correctCount => results.where((result) => result.correct).length;

  GemstoneRoundType get roundType => currentItemIndex.isEven
      ? GemstoneRoundType.nameToImage
      : GemstoneRoundType.imageToName;

  GemstoneGameState copyWith({
    GemstoneGamePhase? phase,
    Gemstone? correctGemstone,
    List<Gemstone>? options,
    int? currentItemIndex,
    List<GemstoneItemResult>? results,
    bool? isCorrect,
    int? timeSeconds,
    List<int>? usedGemstoneIds,
    bool? isLoading,
    bool? isRunFinished,
    int? selectedGemstoneId,
  }) {
    return GemstoneGameState(
      phase: phase ?? this.phase,
      correctGemstone: correctGemstone ?? this.correctGemstone,
      options: options ?? this.options,
      currentItemIndex: currentItemIndex ?? this.currentItemIndex,
      results: results ?? this.results,
      isCorrect: isCorrect ?? this.isCorrect,
      timeSeconds: timeSeconds ?? this.timeSeconds,
      usedGemstoneIds: usedGemstoneIds ?? this.usedGemstoneIds,
      isLoading: isLoading ?? this.isLoading,
      isRunFinished: isRunFinished ?? this.isRunFinished,
      selectedGemstoneId: selectedGemstoneId ?? this.selectedGemstoneId,
    );
  }
}

class GemstoneGameNotifier extends StateNotifier<GemstoneGameState> {
  final Ref _ref;
  final Random _random = Random();

  GemstoneGameNotifier(this._ref) : super(const GemstoneGameState());

  Future<void> startRun() async {
    state = const GemstoneGameState(isLoading: true);
    _loadNextItem();
  }

  void _loadNextItem() {
    final available = gemstones
        .where((gemstone) => !state.usedGemstoneIds.contains(gemstone.id))
        .toList();
    final pool = available.isEmpty ? [...gemstones] : available;
    final correct = pool[_random.nextInt(pool.length)];
    final distractors =
        gemstones.where((gemstone) => gemstone.id != correct.id).toList()
          ..shuffle(_random);
    final options = [correct, ...distractors.take(5)]..shuffle(_random);

    state = state.copyWith(
      phase: GemstoneGamePhase.playing,
      correctGemstone: correct,
      options: options,
      isCorrect: null,
      timeSeconds: 0,
      isLoading: false,
      selectedGemstoneId: null,
      usedGemstoneIds: [...state.usedGemstoneIds, correct.id],
    );
  }

  void tick() {
    if (state.phase != GemstoneGamePhase.playing) return;

    final newTime = state.timeSeconds + 1;
    if (newTime >= 15) {
      _handleAnswer(correct: false, selectedId: -1);
      return;
    }
    state = state.copyWith(timeSeconds: newTime);
  }

  Future<void> submitAnswer(Gemstone selected) async {
    if (state.phase != GemstoneGamePhase.playing) return;
    _handleAnswer(
      correct: selected.id == state.correctGemstone!.id,
      selectedId: selected.id,
    );
  }

  void _handleAnswer({required bool correct, required int selectedId}) {
    final locale = _ref.read(localeProvider);
    final score = correct ? _calculateScore() : 0;
    final result = GemstoneItemResult(
      gemstoneName: state.correctGemstone!.getName(locale),
      assetPath: state.correctGemstone!.assetPath,
      correct: correct,
      timeSeconds: state.timeSeconds,
      score: score,
    );
    final isLast = state.currentItemIndex >= state.totalItems - 1;

    state = state.copyWith(
      phase: GemstoneGamePhase.feedback,
      isCorrect: correct,
      selectedGemstoneId: selectedId,
      results: [...state.results, result],
      isRunFinished: isLast,
    );
  }

  Future<void> nextItem() async {
    if (state.isRunFinished) return;
    state = state.copyWith(currentItemIndex: state.currentItemIndex + 1);
    _loadNextItem();
  }

  int _calculateScore() {
    final time = state.timeSeconds;
    if (time < 3) return 1000;
    if (time < 7) return 700;
    if (time < 15) return 400;
    return 0;
  }
}
