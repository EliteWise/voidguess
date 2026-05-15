// lib/features/duel/screens/duel_game_screen.dart

import 'dart:async';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voidguess/core/l10n/l10n.dart';
import '../../../core/provider/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/models/country.dart';
import '../../flag_game/providers/flag_game_provider.dart';
import '../../gemstone_game/models/gemstone.dart';
import '../../space_game/models/space_planet.dart';
import '../providers/duel_provider.dart';

class DuelGameScreen extends ConsumerStatefulWidget {
  const DuelGameScreen({super.key});

  @override
  ConsumerState<DuelGameScreen> createState() => _DuelGameScreenState();
}

class _DuelGameScreenState extends ConsumerState<DuelGameScreen> {
  Timer? _tickTimer;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _stopTimers();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(duelProvider.notifier).tick();

      // Vérifie timeout
      final state = ref.read(duelProvider);
      if (state.isCorrect != null && _feedbackTimer == null) {
        _onFeedback();
      }
    });
  }

  void _stopTimers() {
    _tickTimer?.cancel();
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
  }

  Future<void> _onAnswerSelected(Country country) async {
    _tickTimer?.cancel();
    await ref.read(duelProvider.notifier).submitAnswer(country);
    _onFeedback();
  }

  Future<void> _onGemstoneSelected(Gemstone gemstone) async {
    _tickTimer?.cancel();
    await ref.read(duelProvider.notifier).submitGemstoneAnswer(gemstone);
    _onFeedback();
  }

  Future<void> _onSpaceSubmitted() async {
    _tickTimer?.cancel();
    await ref.read(duelProvider.notifier).submitSpaceAnswer();
    _onFeedback();
  }

  void _onFeedback() {
    final state = ref.read(duelProvider);

    _feedbackTimer = Timer(
      Duration(milliseconds: state.isLastRound ? 800 : 500),
      () async {
        await ref.read(duelProvider.notifier).nextRound();
        final newState = ref.read(duelProvider);
        if (newState.currentRound >= newState.totalRounds) {
          // Dernier round terminé — stop tout, le build affichera le waiting
          _stopTimers();
        } else {
          _startTimer();
        }
      },
    );
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duelProvider);
    final locale = ref.watch(localeProvider);

    ref.listen<DuelState>(duelProvider, (prev, next) {
      if (next.phase == DuelPhase.finished) {
        _stopTimers();
        context.go('/duel/results');
      }
    });

    if (state.currentRound >= state.totalRounds &&
        state.phase == DuelPhase.playing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 1.5,
              ),
              const SizedBox(height: 24),
              Text(
                ref.tr('waiting_finish'),
                style: AppTheme.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isLoading = state.isSpaceGame
        ? state.currentSpaceRound == null
        : state.isGemstoneGame
        ? state.currentGemstone == null || state.gemstoneOptions.isEmpty
        : state.currentCountry == null || state.options.isEmpty;

    if (isLoading) {
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
          '${state.currentRound + 1} / ${state.totalRounds}',
          style: AppTheme.inter(color: AppTheme.textSecondary, fontSize: 13),
        ),
        centerTitle: true,
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
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.correct,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: AppTheme.inter(
                    color: AppTheme.correct,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),

              if (state.isSpaceGame)
                _DuelSpaceRoundView(
                  round: state.currentSpaceRound!,
                  guessMillionKm: state.spaceGuessMillionKm,
                  submittedGuessMillionKm: state.submittedSpaceGuessMillionKm,
                  timeSeconds: state.timeSeconds,
                  answered: state.isCorrect != null,
                  onGuessChanged: (value) =>
                      ref.read(duelProvider.notifier).updateSpaceGuess(value),
                  onSubmit: state.isCorrect == null ? _onSpaceSubmitted : null,
                  estimateLabel: ref.tr('space_estimate'),
                  realLabel: ref.tr('space_real_distance'),
                  differenceLabel: ref.tr('space_difference'),
                  submitLabel: ref.tr('space_validate'),
                )
              else if (state.isGemstoneGame)
                _DuelGemstoneRoundView(
                  gemstone: state.currentGemstone!,
                  options: state.gemstoneOptions,
                  locale: locale,
                  imageToName: state.isCurrentGemstoneImageToName,
                  selectedGemstoneId: state.selectedGemstoneId,
                  answered: state.isCorrect != null,
                  onAnswerSelected: _onGemstoneSelected,
                )
              else if (state.currentRoundType == FlagRoundType.nameToFlag) ...[
                // ── Nom en haut, drapeaux en bas ────────────────────────
                Text(
                  state.currentCountry!.getName(locale).toUpperCase(),
                  style: AppTheme.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  physics: const NeverScrollableScrollPhysics(),
                  children: state.options.map((country) {
                    return _DuelFlagOption(
                      country: country,
                      correctCountry: state.currentCountry!,
                      isSelected: country.id == state.selectedCountryId,
                      answered: state.isCorrect != null,
                      onTap: state.isCorrect == null
                          ? () => _onAnswerSelected(country)
                          : null,
                    );
                  }).toList(),
                ),
              ] else ...[
                // ── Drapeau en haut, noms en bas ────────────────────────
                ClipRRect(
                  borderRadius: AppTheme.neutralRadius,
                  child: SizedBox(
                    width: 160,
                    height: 107,
                    child: CountryFlag.fromCountryCode(
                      state.currentCountry!.code,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: state.options.map((country) {
                    return _DuelNameOption(
                      country: country,
                      locale: locale,
                      correctCountry: state.currentCountry!,
                      isSelected: country.id == state.selectedCountryId,
                      answered: state.isCorrect != null,
                      onTap: state.isCorrect == null
                          ? () => _onAnswerSelected(country)
                          : null,
                    );
                  }).toList(),
                ),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDistance(double value) {
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)} Md km';
  }
  return '${value.round()} M km';
}

class _DuelSpaceRoundView extends StatelessWidget {
  static const double _maxGuessMillionKm = 4500;
  static const double _guessStepMillionKm = 10;

  final DuelSpaceRound round;
  final double guessMillionKm;
  final double? submittedGuessMillionKm;
  final int timeSeconds;
  final bool answered;
  final ValueChanged<double> onGuessChanged;
  final VoidCallback? onSubmit;
  final String estimateLabel;
  final String realLabel;
  final String differenceLabel;
  final String submitLabel;

  const _DuelSpaceRoundView({
    required this.round,
    required this.guessMillionKm,
    required this.submittedGuessMillionKm,
    required this.timeSeconds,
    required this.answered,
    required this.onGuessChanged,
    required this.onSubmit,
    required this.estimateLabel,
    required this.realLabel,
    required this.differenceLabel,
    required this.submitLabel,
  });

  double get _shownGuess => submittedGuessMillionKm ?? guessMillionKm;

  double get _differenceMillionKm {
    return (_shownGuess - round.actualDistanceMillionKm).abs();
  }

  int get _score {
    final ratio = (_differenceMillionKm / _maxGuessMillionKm).clamp(0.0, 1.0);
    return (1000 * (1 - ratio)).round();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _DuelPlanetCard(planet: round.leftPlanet)),
            const SizedBox(width: 14),
            Container(width: 28, height: 1, color: AppTheme.textTertiary),
            const SizedBox(width: 14),
            Expanded(child: _DuelPlanetCard(planet: round.rightPlanet)),
          ],
        ),
        const SizedBox(height: 34),
        _DuelDistancePanel(
          label: estimateLabel,
          value: _formatDistance(guessMillionKm),
          child: Slider(
            min: 0,
            max: _maxGuessMillionKm,
            divisions: (_maxGuessMillionKm / _guessStepMillionKm).round(),
            value: guessMillionKm,
            label: _formatDistance(guessMillionKm),
            onChanged: answered
                ? null
                : (value) {
                    onGuessChanged(
                      (value / _guessStepMillionKm).round() *
                          _guessStepMillionKm,
                    );
                  },
          ),
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: answered
              ? _DuelSpaceResultPanel(
                  key: const ValueKey('space-result'),
                  realLabel: realLabel,
                  differenceLabel: differenceLabel,
                  realDistance: _formatDistance(round.actualDistanceMillionKm),
                  difference: _formatDistance(_differenceMillionKm),
                  score: _score,
                )
              : const SizedBox(key: ValueKey('space-empty'), height: 88),
        ),
        const SizedBox(height: 24),
        Pressable(
          onTap: onSubmit,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: answered ? AppTheme.surface : AppTheme.action,
              borderRadius: AppTheme.chipRadius,
              border: Border.all(color: AppTheme.textTertiary, width: 0.5),
            ),
            child: Text(
              answered ? '$_score pts' : submitLabel,
              textAlign: TextAlign.center,
              style: AppTheme.inter(
                color: answered ? AppTheme.textSecondary : AppTheme.primaryDeep,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DuelPlanetCard extends StatelessWidget {
  final SpacePlanet planet;

  const _DuelPlanetCard({required this.planet});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppTheme.textTertiary, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Image.asset(
              planet.assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            planet.name.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.inter(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _DuelDistancePanel extends StatelessWidget {
  final String label;
  final String value;
  final Widget child;

  const _DuelDistancePanel({
    required this.label,
    required this.value,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: AppTheme.neutralRadius,
        border: Border.all(color: AppTheme.textTertiary, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTheme.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: AppTheme.inter(
                  color: AppTheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DuelSpaceResultPanel extends StatelessWidget {
  final String realLabel;
  final String differenceLabel;
  final String realDistance;
  final String difference;
  final int score;

  const _DuelSpaceResultPanel({
    super.key,
    required this.realLabel,
    required this.differenceLabel,
    required this.realDistance,
    required this.difference,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final color = score >= 850
        ? AppTheme.correct
        : score >= 550
        ? AppTheme.hint
        : AppTheme.wrong;

    return Container(
      height: 88,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.neutralRadius,
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DuelSpaceValue(label: realLabel, value: realDistance),
          ),
          Container(width: 0.5, height: 44, color: AppTheme.textTertiary),
          Expanded(
            child: _DuelSpaceValue(label: differenceLabel, value: difference),
          ),
          Container(width: 0.5, height: 44, color: AppTheme.textTertiary),
          Expanded(
            child: _DuelSpaceValue(
              label: 'Score',
              value: '$score',
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DuelSpaceValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DuelSpaceValue({
    required this.label,
    required this.value,
    this.color = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.inter(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.inter(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DuelGemstoneRoundView extends StatelessWidget {
  final Gemstone gemstone;
  final List<Gemstone> options;
  final String locale;
  final bool imageToName;
  final int? selectedGemstoneId;
  final bool answered;
  final ValueChanged<Gemstone> onAnswerSelected;

  const _DuelGemstoneRoundView({
    required this.gemstone,
    required this.options,
    required this.locale,
    required this.imageToName,
    required this.selectedGemstoneId,
    required this.answered,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (imageToName) {
      return Column(
        children: [
          _DuelLargeGemstoneImage(assetPath: gemstone.assetPath),
          const SizedBox(height: 48),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            physics: const NeverScrollableScrollPhysics(),
            children: options.map((option) {
              return _DuelGemstoneNameOption(
                gemstone: option,
                locale: locale,
                correctGemstone: gemstone,
                isSelected: option.id == selectedGemstoneId,
                answered: answered,
                onTap: answered ? null : () => onAnswerSelected(option),
              );
            }).toList(),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          gemstone.getName(locale).toUpperCase(),
          textAlign: TextAlign.center,
          style: AppTheme.inter(
            color: AppTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 48),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          physics: const NeverScrollableScrollPhysics(),
          children: options.map((option) {
            return _DuelGemstoneImageOption(
              gemstone: option,
              correctGemstone: gemstone,
              isSelected: option.id == selectedGemstoneId,
              answered: answered,
              onTap: answered ? null : () => onAnswerSelected(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DuelLargeGemstoneImage extends StatelessWidget {
  final String assetPath;

  const _DuelLargeGemstoneImage({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      height: 168,
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

class _DuelGemstoneImageOption extends StatelessWidget {
  final Gemstone gemstone;
  final Gemstone correctGemstone;
  final bool isSelected;
  final bool answered;
  final VoidCallback? onTap;

  const _DuelGemstoneImageOption({
    required this.gemstone,
    required this.correctGemstone,
    required this.isSelected,
    required this.answered,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = gemstone.id == correctGemstone.id;
    final showCorrect = answered && isCorrect;
    final showWrong = answered && isSelected && !isCorrect;

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

class _DuelGemstoneNameOption extends StatelessWidget {
  final Gemstone gemstone;
  final String locale;
  final Gemstone correctGemstone;
  final bool isSelected;
  final bool answered;
  final VoidCallback? onTap;

  const _DuelGemstoneNameOption({
    required this.gemstone,
    required this.locale,
    required this.correctGemstone,
    required this.isSelected,
    required this.answered,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = gemstone.id == correctGemstone.id;
    final showCorrect = answered && isCorrect;
    final showWrong = answered && isSelected && !isCorrect;

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

// ─── Flag option ────────────────────────────────────────────────────────────

class _DuelFlagOption extends StatelessWidget {
  final Country country;
  final Country correctCountry;
  final bool isSelected;
  final bool answered;
  final VoidCallback? onTap;

  const _DuelFlagOption({
    required this.country,
    required this.correctCountry,
    required this.isSelected,
    required this.answered,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = country.id == correctCountry.id;
    final showCorrect = answered && isCorrect;
    final showWrong = answered && isSelected && !isCorrect;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
        child: ClipRRect(
          borderRadius: AppTheme.neutralRadius,
          child: Stack(
            children: [
              Positioned.fill(child: CountryFlag.fromCountryCode(country.code)),
              if (showCorrect || showWrong)
                Positioned.fill(
                  child: Container(
                    color: showCorrect
                        ? AppTheme.correct.withValues(alpha: 0.3)
                        : AppTheme.wrong.withValues(alpha: 0.3),
                    child: Center(
                      child: Icon(
                        showCorrect ? Icons.check_rounded : Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Name option ────────────────────────────────────────────────────────────

class _DuelNameOption extends StatelessWidget {
  final Country country;
  final String locale;
  final Country correctCountry;
  final bool isSelected;
  final bool answered;
  final VoidCallback? onTap;

  const _DuelNameOption({
    required this.country,
    required this.locale,
    required this.correctCountry,
    required this.isSelected,
    required this.answered,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = country.id == correctCountry.id;
    final showCorrect = answered && isCorrect;
    final showWrong = answered && isSelected && !isCorrect;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: showCorrect
              ? AppTheme.correct.withValues(alpha: 0.1)
              : showWrong
              ? AppTheme.wrong.withValues(alpha: 0.1)
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
        alignment: Alignment.center,
        child: Text(
          country.getName(locale),
          style: AppTheme.inter(
            color: showCorrect
                ? AppTheme.correct
                : showWrong
                ? AppTheme.wrong
                : AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
