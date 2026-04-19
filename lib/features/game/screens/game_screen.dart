import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
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
    _controller.clear();
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
          child: CircularProgressIndicator(
            color: AppTheme.primary,
            strokeWidth: 1.5,
          ),
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
            fontSize: 13,
            letterSpacing: 1,
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
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
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
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
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
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.wrong.withOpacity(0.08),
                    borderRadius: AppTheme.inputRadius,
                    border: Border.all(
                      color: AppTheme.wrong.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: const Text(
                    'HARDCORE',
                    style: TextStyle(
                      color: AppTheme.wrong,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              _LetterDisplay(letters: state.revealedLetters),
              const SizedBox(height: 48),
              TextField(
                controller: _controller,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  decoration: TextDecoration.none,
                ),
                decoration: InputDecoration(
                  hintText: 'Guess the title...',
                  hintStyle: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceHigh,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.inputRadius,
                    borderSide: const BorderSide(
                      color: AppTheme.textTertiary,
                      width: 0.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppTheme.inputRadius,
                    borderSide: const BorderSide(
                      color: AppTheme.textTertiary,
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppTheme.inputRadius,
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                      color: AppTheme.primary,
                      size: 18,
                    ),
                    onPressed: () => _submitGuess(_controller.text),
                  ),
                ),
                onSubmitted: _submitGuess,
              ),
              const SizedBox(height: 20),
              if (!state.usedHint)
                GestureDetector(
                  onTap: () {
                    ref.read(gameProvider.notifier).useHint();
                    final repo = ref.read(itemRepositoryProvider);
                    final randomHint = repo.getRandomHints(state.currentItem!.hint);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Released in ${state.currentItem!.year} ~ Ref: $randomHint',
                          style: const TextStyle(
                            color: AppTheme.background,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: AppTheme.hint,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.inputRadius,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.hint.withOpacity(0.06),
                      borderRadius: AppTheme.neutralRadius,
                      border: Border.all(
                        color: AppTheme.hint.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.lightbulb(PhosphorIconsStyle.regular),
                          color: AppTheme.hint,
                          size: 14,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Hint — release year  (÷2 score)',
                          style: TextStyle(
                            color: AppTheme.hint,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
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
      shape: RoundedRectangleBorder(borderRadius: AppTheme.neutralRadius),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              found ? 'Found !' : 'Missed !',
              style: TextStyle(
                color: found ? AppTheme.correct : AppTheme.wrong,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              itemName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RecapStat(
                  label: 'Score',
                  value: '+$score',
                  color: found ? AppTheme.correct : AppTheme.wrong,
                ),
                _RecapStat(
                  label: 'Time',
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
              child: Pressable(
                onTap: onNext,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: AppTheme.cardRadius,
                  ),
                  child: const Text(
                    'Next',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.background,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              )
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
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            letterSpacing: 0.5,
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
      spacing: 8,
      runSpacing: 16,
      children: letters.map((letter) {
        if (letter == ' ') return const SizedBox(width: 20);
        final isRevealed = letter != '_';
        return Container(
          width: 30,
          height: 38,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isRevealed ? AppTheme.primary : AppTheme.textTertiary,
                width: isRevealed ? 2 : 1,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            isRevealed ? letter.toUpperCase() : '',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              decoration: TextDecoration.none,
            ),
          ),
        );
      }).toList(),
    );
  }
}