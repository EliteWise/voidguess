import 'dart:async';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:voidguess/core/provider/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
import '../providers/flag_game_provider.dart';

class FlagGameScreen extends ConsumerStatefulWidget {
  const FlagGameScreen({super.key});

  @override
  ConsumerState<FlagGameScreen> createState() => _FlagGameScreenState();
}

class _FlagGameScreenState extends ConsumerState<FlagGameScreen> {
  Timer? _tickTimer;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRun());
  }

  Future<void> _startRun() async {
    await ref.read(flagGameProvider.notifier).startRun();
    _startTimer();
  }

  void _startTimer() {
    _stopTimers();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = ref.read(flagGameProvider);
      if (state.phase == FlagGamePhase.playing) {
        ref.read(flagGameProvider.notifier).tick();
        // Vérifie si le timer a expiré
        final newState = ref.read(flagGameProvider);
        if (newState.phase == FlagGamePhase.feedback) {
          _onFeedback();
        }
      }
    });
  }

  void _stopTimers() {
    _tickTimer?.cancel();
    _feedbackTimer?.cancel();
  }

  Future<void> _onAnswerSelected(country) async {
    _stopTimers();
    await ref.read(flagGameProvider.notifier).submitAnswer(country);
    _onFeedback();
  }

  void _onFeedback() {
    final state = ref.read(flagGameProvider);

    if (state.isRunFinished) {
      // Délai feedback puis navigate vers results
      _feedbackTimer = Timer(const Duration(milliseconds: 800), () {
        context.go('/flag_results', extra: {
          'results': state.results,
          'totalScore': state.totalScore,
          'correctCount': state.correctCount,
          'totalItems': state.totalItems,
        });
      });
    } else {
      // Délai feedback puis item suivant
      _feedbackTimer = Timer(const Duration(milliseconds: 500), () async {
        await ref.read(flagGameProvider.notifier).nextItem();
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
    final state = ref.watch(flagGameProvider);
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
                letterSpacing: 0.5,
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
          child: Column(
            children: [
              const Spacer(),
              // ── Nom du pays ─────────────────────────────────────────────
              Text(
                state.correctCountry!.getName(locale).toUpperCase(),
                style: AppTheme.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // ── Grille 2x3 de drapeaux ──────────────────────────────────
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                physics: const NeverScrollableScrollPhysics(),
                children: state.options.map((country) {
                  return _FlagOption(
                    country: country,
                    phase: state.phase,
                    correctCountry: state.correctCountry!,
                    isSelected: country.id == state.selectedCountryId,
                    onTap: state.phase == FlagGamePhase.playing
                        ? () => _onAnswerSelected(country)
                        : null,
                  );
                }).toList(),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widget drapeau ──────────────────────────────────────────────────────────

class _FlagOption extends StatelessWidget {
  final country;
  final FlagGamePhase phase;
  final correctCountry;
  final bool isSelected;
  final VoidCallback? onTap;

  const _FlagOption({
    required this.country,
    required this.phase,
    required this.correctCountry,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = country.id == correctCountry.id;
    final showCorrect = phase == FlagGamePhase.feedback && isCorrect;
    final showWrong = phase == FlagGamePhase.feedback && isSelected && !isCorrect;

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