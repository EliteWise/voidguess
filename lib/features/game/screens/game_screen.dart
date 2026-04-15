import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/game_provider.dart';

class GameScreen extends ConsumerStatefulWidget {
  final RunMode mode;
  final String category;

  const GameScreen({super.key, required this.mode, required this.category});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _revealTimer;
  Timer? _tickTimer;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRun();
    });
  }

  Future<void> _startRun() async {
    await ref.read(gameProvider.notifier).startRun(
      mode: widget.mode,
      category: widget.category,
    );
    _startTimers();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final repo = ref.read(itemRepositoryProvider);
    final names = await repo.getItemNames(category: widget.category);
    setState(() => _suggestions = names);
  }

  void _startTimers() {
    _stopTimers();
    _revealTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final state = ref.read(gameProvider);
      if (!state.isFinished) {
        ref.read(gameProvider.notifier).revealNextLetter();
        final newState = ref.read(gameProvider);
        if (newState.showingItemRecap) _onItemEnd();
      }
    });

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = ref.read(gameProvider);
      if (!state.isFinished) {
        ref.read(gameProvider.notifier).tick();
      }
    });
  }

  void _stopTimers() {
    _revealTimer?.cancel();
    _tickTimer?.cancel();
  }

  void _submitGuess(String guess) {
    if (guess.trim().isEmpty) return;
    ref.read(gameProvider.notifier).submitGuess(guess);
    _controller.clear();
    final state = ref.read(gameProvider);
    if (state.showingItemRecap) _onItemEnd();
  }

  void _onItemEnd() {
    _stopTimers();
    final state = ref.read(gameProvider);
    if (state.isRunFinished) {
      context.go('/results', extra: {
        'itemResults': state.itemResults,
        'totalScore': state.totalScore,
        'itemsFound': state.itemsFound,
        'totalItems': state.totalItems,
        'mode': state.runMode,
        'category': widget.category,
        'isHardcoreFail': state.isLost && state.runMode.isHardcore,
      });
    } else {
      _showItemRecap(state);
    }
  }

  void _showItemRecap(GameState state) {
    final found = !state.isLost;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ItemRecapDialog(
        itemName: state.currentItem!.name,
        score: state.score,
        timeSeconds: state.timeSeconds,
        found: found,
        current: state.currentItemIndex + 1,
        total: state.totalItems,
        onNext: () {
          Navigator.of(context).pop();
          ref.read(gameProvider.notifier).nextItem().then((_) {
            _startTimers();
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _stopTimers();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          '${state.currentItemIndex + 1} / ${state.totalItems}',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${state.timeSeconds}s',
                style: const TextStyle(
                  color: AppTheme.hint,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Text(
              '${state.totalScore} pts',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              if (state.runMode.isHardcore)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.wrong.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.wrong.withOpacity(0.4),
                    ),
                  ),
                  child: const Text(
                    'HARDCORE',
                    style: TextStyle(
                      color: AppTheme.wrong,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              _LetterDisplay(letters: state.revealedLetters),
              const SizedBox(height: 48),
              _AutocompleteInput(
                key: ValueKey(state.currentItemIndex),
                controller: _controller,
                suggestions: _suggestions,
                onSubmit: _submitGuess,
              ),
              const SizedBox(height: 24),
              if (!state.usedHint)
                TextButton.icon(
                  onPressed: () {
                    ref.read(gameProvider.notifier).useHint();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Sorti en ${state.currentItem!.year}',
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                        backgroundColor: AppTheme.hint,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.hint,
                    size: 16,
                  ),
                  label: const Text(
                    'Indice — année de sortie (÷2 score)',
                    style: TextStyle(color: AppTheme.hint, fontSize: 13),
                  ),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRecapDialog extends StatelessWidget {
  final String itemName;
  final int score;
  final int timeSeconds;
  final bool found;
  final int current;
  final int total;
  final VoidCallback onNext;

  const _ItemRecapDialog({
    required this.itemName,
    required this.score,
    required this.timeSeconds,
    required this.found,
    required this.current,
    required this.total,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              found ? 'Trouvé !' : 'Raté !',
              style: TextStyle(
                color: found ? AppTheme.correct : AppTheme.wrong,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              itemName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RecapStat(
                  label: 'Score',
                  value: '+$score pts',
                  color: found ? AppTheme.correct : AppTheme.wrong,
                ),
                _RecapStat(
                  label: 'Temps',
                  value: '${timeSeconds}s',
                ),
                _RecapStat(
                  label: 'Item',
                  value: '$current/$total',
                  color: AppTheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                child: const Text('Suivant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecapStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RecapStat({
    required this.label,
    required this.value,
    this.color = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _LetterDisplay extends StatelessWidget {
  final List<String> letters;

  const _LetterDisplay({required this.letters});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 12,
      children: letters.map((letter) {
        if (letter == ' ') return const SizedBox(width: 16);
        return Container(
          width: 32,
          height: 40,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: letter == '_'
                    ? AppTheme.textSecondary
                    : AppTheme.primary,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            letter == '_' ? '' : letter.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AutocompleteInput extends StatelessWidget {
  final TextEditingController controller;
  final List<String> suggestions;
  final Function(String) onSubmit;

  const _AutocompleteInput({
    super.key,
    required this.controller,
    required this.suggestions,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.length < 2) return const [];
        return suggestions.where((s) => s
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: onSubmit,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Devine le titre...',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send, color: AppTheme.primary),
              onPressed: () => onSubmit(controller.text),
            ),
          ),
          onSubmitted: onSubmit,
        );
      },
    );
  }
}