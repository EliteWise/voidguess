import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../data/models/item.dart';
import '../../../data/repositories/item_repository.dart'; // ← correct

enum RunMode { quickNormal, quickHardcore, fullNormal, fullHardcore }

extension RunModeExtension on RunMode {
  int get totalItems => name.startsWith('quick') ? 5 : 10;
  bool get isHardcore => name.endsWith('Hardcore');
  String get label {
    switch (this) {
      case RunMode.quickNormal: return 'Quick — Normal';
      case RunMode.quickHardcore: return 'Quick — Hardcore';
      case RunMode.fullNormal: return 'Full — Normal';
      case RunMode.fullHardcore: return 'Full — Hardcore';
    }
  }
}

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository();
});

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final repository = ref.watch(itemRepositoryProvider);
  return GameNotifier(repository);
});

class ItemResult {
  final String name;
  final int score;
  final int timeSeconds;
  final bool found;
  final int lettersRevealed;
  final bool usedHint;

  const ItemResult({
    required this.name,
    required this.score,
    required this.timeSeconds,
    required this.found,
    required this.lettersRevealed,
    required this.usedHint
  });
}

class GameState {
  final Item? currentItem;
  final List<String> revealedLetters;
  final bool isFinished;
  final bool isLost;
  final bool usedHint;
  final int timeSeconds;
  final int score;
  final bool isLoading;

  // Run
  final RunMode runMode;
  final String category;
  final int currentItemIndex;
  final List<ItemResult> itemResults;
  final bool isRunFinished;
  final bool showingItemRecap;

  const GameState({
    this.currentItem,
    this.revealedLetters = const [],
    this.isFinished = false,
    this.isLost = false,
    this.usedHint = false,
    this.timeSeconds = 0,
    this.score = 0,
    this.isLoading = true,
    this.runMode = RunMode.quickNormal,
    this.category = 'game',
    this.currentItemIndex = 0,
    this.itemResults = const [],
    this.isRunFinished = false,
    this.showingItemRecap = false,
  });

  int get totalItems => runMode.totalItems;
  int get totalScore => itemResults.fold(0, (sum, r) => sum + r.score);
  int get itemsFound => itemResults.where((r) => r.found).length;

  GameState copyWith({
    Item? currentItem,
    List<String>? revealedLetters,
    bool? isFinished,
    bool? isLost,
    bool? usedHint,
    int? timeSeconds,
    int? score,
    bool? isLoading,
    RunMode? runMode,
    String? category,
    int? currentItemIndex,
    List<ItemResult>? itemResults,
    bool? isRunFinished,
    bool? showingItemRecap,
  }) {
    return GameState(
      currentItem: currentItem ?? this.currentItem,
      revealedLetters: revealedLetters ?? this.revealedLetters,
      isFinished: isFinished ?? this.isFinished,
      isLost: isLost ?? this.isLost,
      usedHint: usedHint ?? this.usedHint,
      timeSeconds: timeSeconds ?? this.timeSeconds,
      score: score ?? this.score,
      isLoading: isLoading ?? this.isLoading,
      runMode: runMode ?? this.runMode,
      category: category ?? this.category,
      currentItemIndex: currentItemIndex ?? this.currentItemIndex,
      itemResults: itemResults ?? this.itemResults,
      isRunFinished: isRunFinished ?? this.isRunFinished,
      showingItemRecap: showingItemRecap ?? this.showingItemRecap,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  final ItemRepository _repository;

  GameNotifier(this._repository) : super(const GameState());

  Future<void> startRun({
    required RunMode mode,
    required String category,
  }) async {
    state = const GameState(isLoading: true);
    state = state.copyWith(
      runMode: mode,
      category: category,
      currentItemIndex: 0,
      itemResults: [],
      isRunFinished: false,
    );
    await _loadNextItem();
  }

  Future<void> _loadNextItem() async {
    state = state.copyWith(isLoading: true);
    final item = await _repository.getRandomItem(category: state.category);
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
      showingItemRecap: false,
    );
  }

  List<String> _buildInitialLetters(String name) {
    return name.split('').map((char) {
      if (char == ' ') return ' ';
      return '_';
    }).toList();
  }

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

    final remaining = letters.where((l) => l == '_').length;
    if (remaining == 0) {
      _handleItemEnd(found: false);
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
      _handleItemEnd(found: true);
    } else {
      if (state.runMode.isHardcore) {
        _handleItemEnd(found: false, forceRunEnd: true);
      } else {
        _handleItemEnd(found: false);
      }
    }
  }

  void _handleItemEnd({required bool found, bool forceRunEnd = false}) {
    final score = found ? _calculateScore() : 0;
    final lettersRevealed = state.revealedLetters
        .where((l) => l != '_' && l != ' ')
        .length;

    final result = ItemResult(
      name: state.currentItem!.name,
      score: score,
      timeSeconds: state.timeSeconds,
      found: found,
      lettersRevealed: lettersRevealed,
      usedHint: state.usedHint,
    );

    final newResults = [...state.itemResults, result];
    final isLastItem = state.currentItemIndex >= state.totalItems - 1;
    final shouldEndRun = forceRunEnd || isLastItem;

    state = state.copyWith(
      isFinished: true,
      isLost: !found,
      score: score,
      itemResults: newResults,
      showingItemRecap: true,
      isRunFinished: shouldEndRun,
    );
  }

  Future<void> nextItem() async {
    if (state.isRunFinished) return;
    state = state.copyWith(
      currentItemIndex: state.currentItemIndex + 1,
    );
    await _loadNextItem();
  }

  int _calculateScore() {
    final totalLetters = state.currentItem!.name
        .split('')
        .where((c) => c != ' ')
        .length;

    final revealedLetters = state.revealedLetters
        .where((l) => l != '_' && l != ' ')
        .length;

    final hiddenAtGuess = totalLetters - revealedLetters;

    double ratio = hiddenAtGuess / totalLetters;
    int score = (1000 * ratio).round();

    if (state.usedHint) score = (score / 2).round();
    return score.clamp(0, 1000);
  }
}