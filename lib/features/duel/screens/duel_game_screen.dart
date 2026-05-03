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

  void _onAnswerSelected(Country country) {
    _tickTimer?.cancel();
    ref.read(duelProvider.notifier).submitAnswer(country);
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

    if (state.currentRound >= state.totalRounds && state.phase == DuelPhase.playing) {
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
              const SizedBox(height: 8),
              Text(
                '${state.opponent?.results.length ?? 0} / ${state.totalRounds}',
                style: AppTheme.inter(
                  color: AppTheme.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.currentCountry == null || state.options.isEmpty) {
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
          style: AppTheme.inter(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
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

              if (state.currentRoundType == FlagRoundType.nameToFlag) ...[
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
              Positioned.fill(
                child: CountryFlag.fromCountryCode(country.code),
              ),
              if (showCorrect || showWrong)
                Positioned.fill(
                  child: Container(
                    color: showCorrect
                        ? AppTheme.correct.withOpacity(0.3)
                        : AppTheme.wrong.withOpacity(0.3),
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
              ? AppTheme.correct.withOpacity(0.1)
              : showWrong
              ? AppTheme.wrong.withOpacity(0.1)
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