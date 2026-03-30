import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../data/models/item.dart';
import '../../../data/repositories/game_repository.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository();
});

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final repository = ref.watch(itemRepositoryProvider);
  return GameNotifier(repository);
});

class GameState {
  final Item? currentItem;
  final List<String> revealedLetters;
  final bool isFinished;
  final bool usedHint;
  final int timeSeconds;
  final int score;
  final bool isLoading;
  final bool isLost;

  const GameState({
    this.currentItem,
    this.revealedLetters = const [],
    this.isFinished = false,
    this.usedHint = false,
    this.timeSeconds = 0,
    this.score = 0,
    this.isLoading = true,
    this.isLost = false,
  });

  GameState copyWith({
    Item? currentItem,
    List<String>? revealedLetters,
    bool? isFinished,
    bool? usedHint,
    int? timeSeconds,
    int? score,
    bool? isLoading,
    bool? isLost,
  }) {
    return GameState(
      currentItem: currentItem ?? this.currentItem,
      revealedLetters: revealedLetters ?? this.revealedLetters,
      isFinished: isFinished ?? this.isFinished,
      usedHint: usedHint ?? this.usedHint,
      timeSeconds: timeSeconds ?? this.timeSeconds,
      score: score ?? this.score,
      isLoading: isLoading ?? this.isLoading,
      isLost: isLost ?? this.isLost,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  final ItemRepository _repository;

  GameNotifier(this._repository) : super(const GameState());

  Future<void> loadItem(String category) async {
    state = state.copyWith(isLoading: true);
    final item = await _repository.getRandomItem(category: category);
    final letters = _buildInitialLetters(item.name);
    state = state.copyWith(
      currentItem: item,
      revealedLetters: letters,
      isLoading: false,
      isFinished: false,
      isLost: false,
      usedHint: false,
      score: 0,
      timeSeconds: 0,
    );
  }

  // Construit la liste : lettre visible ou '_'
  List<String> _buildInitialLetters(String name) {
    return name.split('').map((char) {
      if (char == ' ') return ' ';
      return '_';
    }).toList();
  }

  // Révèle une lettre aléatoire non encore révélée
  void revealNextLetter() {
    if (state.currentItem == null) return;
    final name = state.currentItem!.name;
    final letters = List<String>.from(state.revealedLetters);

    final hiddenIndexes = <int>[];
    for (int i = 0; i < letters.length; i++) {
      if (letters[i] == '_') hiddenIndexes.add(i);
    }

    if (hiddenIndexes.isEmpty) return;
    hiddenIndexes.shuffle();
    final index = hiddenIndexes.first;
    letters[index] = name[index];
    state = state.copyWith(revealedLetters: letters);

    // Si plus aucune lettre cachée → perdu
    final remaining = letters.where((l) => l == '_').length;
    if (remaining == 0) {
      state = state.copyWith(isLost: true, isFinished: true);
    }
  }

  void useHint() {
    state = state.copyWith(usedHint: true);
  }

  void tick() {
    state = state.copyWith(timeSeconds: state.timeSeconds + 1);
  }

  void submitGuess(String guess) {
    if (state.currentItem == null) return;
    final correct = guess.trim().toLowerCase() ==
        state.currentItem!.name.trim().toLowerCase();
    if (correct) {
      final score = _calculateScore();
      state = state.copyWith(isFinished: true, score: score);
    }
  }

  int _calculateScore() {
    int score = 1000;
    score -= state.timeSeconds * 50;
    if (state.usedHint) score = (score / 2).round();
    return score.clamp(0, 1000);
  }
}