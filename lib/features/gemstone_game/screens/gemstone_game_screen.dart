import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voidguess/core/provider/locale_provider.dart';
import 'package:voidguess/core/theme/app_theme.dart';
import 'package:voidguess/core/widgets/pressable.dart';
import '../models/gemstone.dart';
import '../providers/gemstone_game_provider.dart';

class GemstoneGameScreen extends ConsumerStatefulWidget {
  const GemstoneGameScreen({super.key});

  @override
  ConsumerState<GemstoneGameScreen> createState() => _GemstoneGameScreenState();
}

class _GemstoneGameScreenState extends ConsumerState<GemstoneGameScreen> {
  Timer? _tickTimer;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRun());
  }

  Future<void> _startRun() async {
    await ref.read(gemstoneGameProvider.notifier).startRun();
    _startTimer();
  }

  void _startTimer() {
    _stopTimers();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = ref.read(gemstoneGameProvider);
      if (state.phase == GemstoneGamePhase.playing) {
        ref.read(gemstoneGameProvider.notifier).tick();
        final newState = ref.read(gemstoneGameProvider);
        if (newState.phase == GemstoneGamePhase.feedback) {
          _onFeedback();
        }
      }
    });
  }

  void _stopTimers() {
    _tickTimer?.cancel();
    _feedbackTimer?.cancel();
  }

  Future<void> _onAnswerSelected(Gemstone gemstone) async {
    _stopTimers();
    await ref.read(gemstoneGameProvider.notifier).submitAnswer(gemstone);
    _onFeedback();
  }

  void _onFeedback() {
    final state = ref.read(gemstoneGameProvider);
    if (state.isRunFinished) {
      _feedbackTimer = Timer(const Duration(milliseconds: 800), () {
        context.go(
          '/gemstone_results',
          extra: {
            'results': state.results,
            'totalScore': state.totalScore,
            'correctCount': state.correctCount,
            'totalItems': state.totalItems,
          },
        );
      });
    } else {
      _feedbackTimer = Timer(const Duration(milliseconds: 500), () async {
        await ref.read(gemstoneGameProvider.notifier).nextItem();
        _startTimer();
      });
    }
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gemstoneGameProvider);
    final locale = ref.watch(localeProvider);

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
          style: AppTheme.inter(
            color: AppTheme.textSecondary,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Text(
              '${state.totalScore} pts',
              style: AppTheme.inter(
                color: AppTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${state.timeSeconds}s',
                style: AppTheme.inter(
                  color: AppTheme.hint,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxHeight < 620;
              final roundContent =
                  state.roundType == GemstoneRoundType.nameToImage
                  ? <Widget>[
                      Text(
                        state.correctGemstone!.getName(locale).toUpperCase(),
                        textAlign: TextAlign.center,
                        style: AppTheme.inter(
                          color: AppTheme.textPrimary,
                          fontSize: isCompact ? 24 : 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: isCompact ? 24 : 48),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isCompact ? 1.25 : 1.15,
                        physics: const NeverScrollableScrollPhysics(),
                        children: state.options.map((gemstone) {
                          return _GemstoneImageOption(
                            gemstone: gemstone,
                            phase: state.phase,
                            correctGemstone: state.correctGemstone!,
                            isSelected: gemstone.id == state.selectedGemstoneId,
                            onTap: state.phase == GemstoneGamePhase.playing
                                ? () => _onAnswerSelected(gemstone)
                                : null,
                          );
                        }).toList(),
                      ),
                    ]
                  : <Widget>[
                      _LargeGemstoneImage(
                        assetPath: state.correctGemstone!.assetPath,
                        size: isCompact ? 124 : 168,
                      ),
                      SizedBox(height: isCompact ? 24 : 48),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isCompact ? 2.35 : 2.2,
                        physics: const NeverScrollableScrollPhysics(),
                        children: state.options.map((gemstone) {
                          return _GemstoneNameOption(
                            gemstone: gemstone,
                            locale: locale,
                            phase: state.phase,
                            correctGemstone: state.correctGemstone!,
                            isSelected: gemstone.id == state.selectedGemstoneId,
                            onTap: state.phase == GemstoneGamePhase.playing
                                ? () => _onAnswerSelected(gemstone)
                                : null,
                          );
                        }).toList(),
                      ),
                    ];

              return Column(
                children: [const Spacer(), ...roundContent, const Spacer()],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LargeGemstoneImage extends StatelessWidget {
  final String assetPath;
  final double size;

  const _LargeGemstoneImage({required this.assetPath, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppTheme.textTertiary, width: 0.5),
      ),
      child: Image.asset(assetPath, fit: BoxFit.contain),
    );
  }
}

class _GemstoneImageOption extends StatelessWidget {
  final Gemstone gemstone;
  final GemstoneGamePhase phase;
  final Gemstone correctGemstone;
  final bool isSelected;
  final VoidCallback? onTap;

  const _GemstoneImageOption({
    required this.gemstone,
    required this.phase,
    required this.correctGemstone,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = gemstone.id == correctGemstone.id;
    final showCorrect = phase == GemstoneGamePhase.feedback && isCorrect;
    final showWrong =
        phase == GemstoneGamePhase.feedback && isSelected && !isCorrect;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.neutralRadius,
          border: Border.all(
            color: showCorrect
                ? AppTheme.correct
                : showWrong
                ? AppTheme.wrong
                : AppTheme.textTertiary,
            width: (showCorrect || showWrong) ? 2 : 0.5,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(gemstone.assetPath, fit: BoxFit.contain),
            ),
            if (showCorrect || showWrong)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: (showCorrect ? AppTheme.correct : AppTheme.wrong)
                        .withValues(alpha: 0.18),
                  ),
                  child: Icon(
                    showCorrect ? Icons.check_rounded : Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GemstoneNameOption extends StatelessWidget {
  final Gemstone gemstone;
  final String locale;
  final GemstoneGamePhase phase;
  final Gemstone correctGemstone;
  final bool isSelected;
  final VoidCallback? onTap;

  const _GemstoneNameOption({
    required this.gemstone,
    required this.locale,
    required this.phase,
    required this.correctGemstone,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = gemstone.id == correctGemstone.id;
    final showCorrect = phase == GemstoneGamePhase.feedback && isCorrect;
    final showWrong =
        phase == GemstoneGamePhase.feedback && isSelected && !isCorrect;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: showCorrect
              ? AppTheme.correct.withValues(alpha: 0.10)
              : showWrong
              ? AppTheme.wrong.withValues(alpha: 0.10)
              : AppTheme.surface,
          borderRadius: AppTheme.neutralRadius,
          border: Border.all(
            color: showCorrect
                ? AppTheme.correct
                : showWrong
                ? AppTheme.wrong
                : AppTheme.textTertiary,
            width: (showCorrect || showWrong) ? 2 : 0.5,
          ),
        ),
        child: Text(
          gemstone.getName(locale),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.inter(
            color: showCorrect
                ? AppTheme.correct
                : showWrong
                ? AppTheme.wrong
                : AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
