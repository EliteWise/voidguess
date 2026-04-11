import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../providers/game_provider.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String category;

  const GameScreen({super.key, required this.category});

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
      _startGame();
    });
  }

  Future<void> _startGame() async {
    await ref.read(gameProvider.notifier).loadItem(widget.category);
    _startTimers();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final repo = ref.read(itemRepositoryProvider);
    final names = await repo.getItemNames(category: widget.category);
    setState(() => _suggestions = names);
  }

  void _startTimers() {
    _revealTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final state = ref.read(gameProvider);
      if (!state.isFinished) {
        ref.read(gameProvider.notifier).revealNextLetter();
        final newState = ref.read(gameProvider);
        if (newState.isLost) {
          _stopTimers();
          context.go('/results', extra: {
            'score': 0,
            'timeSeconds': newState.timeSeconds,
            'itemName': newState.currentItem!.name,
            'usedHint': newState.usedHint,
          });
        }
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
    ref.read(gameProvider.notifier).submitGuess(guess);
    final state = ref.read(gameProvider);
    if (state.isFinished) {
      _stopTimers();
      context.go('/results', extra: {
        'score': state.score,
        'timeSeconds': state.timeSeconds,
        'itemName': state.currentItem!.name,
        'usedHint': state.usedHint,
        'category': widget.category,
        'isLost': state.isLost,
      });
    }
  }

  void _useHint() {
    ref.read(gameProvider.notifier).useHint();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sorti en ${ref.read(gameProvider).currentItem!.year}',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        backgroundColor: AppTheme.hint,
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
          widget.category == 'game' ? 'Jeux vidéo' : 'Films',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _LetterDisplay(letters: state.revealedLetters),
              const SizedBox(height: 48),
              _AutocompleteInput(
                controller: _controller,
                suggestions: _suggestions,
                onSubmit: _submitGuess,
              ),
              const SizedBox(height: 24),
              if (!state.usedHint)
                TextButton.icon(
                  onPressed: _useHint,
                  icon: const Icon(Icons.lightbulb_outline, color: AppTheme.hint),
                  label: const Text(
                    'Indice — année de sortie (÷2 score)',
                    style: TextStyle(color: AppTheme.hint),
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
                color: letter == '_' ? AppTheme.textSecondary : AppTheme.primary,
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