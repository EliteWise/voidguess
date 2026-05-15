import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:voidguess/core/l10n/l10n.dart';
import 'package:voidguess/core/theme/app_theme.dart';
import 'package:voidguess/core/widgets/pressable.dart';
import 'package:voidguess/core/widgets/result_stat.dart';
import 'package:voidguess/core/widgets/void_action_button.dart';
import 'package:voidguess/features/space_game/models/space_planet.dart';

class SpaceOrbitGameScreen extends ConsumerStatefulWidget {
  const SpaceOrbitGameScreen({super.key});

  @override
  ConsumerState<SpaceOrbitGameScreen> createState() =>
      _SpaceOrbitGameScreenState();
}

class _SpaceOrbitGameScreenState extends ConsumerState<SpaceOrbitGameScreen> {
  static const int _totalRounds = 10;
  static const int _maxTimeSeconds = 15;

  final Random _random = Random();
  final List<_OrbitRoundResult> _results = [];
  Timer? _tickTimer;
  late _OrbitRound _round;
  int _roundIndex = 0;
  int _timeSeconds = 0;
  int _totalScore = 0;
  SpacePlanet? _selectedPlanet;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _round = _generateRound();
    _startTimer();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isCorrect != null || !mounted) return;
      setState(() => _timeSeconds += 1);
      if (_timeSeconds >= _maxTimeSeconds) {
        _submit(null);
      }
    });
  }

  _OrbitRound _generateRound() {
    final ordered = [...spacePlanets]
      ..sort((a, b) => a.orbitMillionKm.compareTo(b.orbitMillionKm));
    final correctIndex = 1 + _random.nextInt(ordered.length - 2);
    final lower = ordered[correctIndex - 1];
    final upper = ordered[correctIndex + 1];
    final correct = ordered[correctIndex];
    final distractors =
        ordered
            .where(
              (planet) =>
                  planet.id != lower.id &&
                  planet.id != upper.id &&
                  planet.id != correct.id &&
                  !_isBetween(planet, lower, upper),
            )
            .toList()
          ..shuffle(_random);
    final options = [correct, ...distractors.take(3)]..shuffle(_random);

    return _OrbitRound(
      lower: lower,
      upper: upper,
      correct: correct,
      options: options,
    );
  }

  bool _isBetween(SpacePlanet planet, SpacePlanet lower, SpacePlanet upper) {
    return planet.orbitMillionKm > lower.orbitMillionKm &&
        planet.orbitMillionKm < upper.orbitMillionKm;
  }

  int _scoreForAnswer(bool correct) {
    if (!correct) return 0;
    if (_timeSeconds < 3) return 1000;
    if (_timeSeconds < 7) return 700;
    return 400;
  }

  void _submit(SpacePlanet? planet) {
    if (_isCorrect != null) return;
    final correct = planet?.id == _round.correct.id;
    final score = _scoreForAnswer(correct);

    setState(() {
      _selectedPlanet = planet;
      _isCorrect = correct;
      _totalScore += score;
      _results.add(
        _OrbitRoundResult(
          correctPlanet: _round.correct,
          selectedPlanet: planet,
          correct: correct,
          timeSeconds: _timeSeconds,
          score: score,
        ),
      );
    });

    _tickTimer?.cancel();
  }

  void _nextRound() {
    if (_roundIndex >= _totalRounds - 1) {
      setState(() => _roundIndex = _totalRounds);
      return;
    }

    setState(() {
      _roundIndex += 1;
      _round = _generateRound();
      _timeSeconds = 0;
      _selectedPlanet = null;
      _isCorrect = null;
    });
    _startTimer();
  }

  int get _correctCount => _results.where((result) => result.correct).length;

  @override
  Widget build(BuildContext context) {
    if (_roundIndex >= _totalRounds) {
      return _SpaceOrbitSummary(
        totalScore: _totalScore,
        correctCount: _correctCount,
        totalRounds: _totalRounds,
        results: _results,
      );
    }

    final answered = _isCorrect != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '${_roundIndex + 1} / $_totalRounds',
          style: AppTheme.inter(color: AppTheme.textSecondary, fontSize: 13),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Text(
              '$_totalScore pts',
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
                '${_timeSeconds}s',
                style: AppTheme.inter(
                  color: _timeSeconds >= _maxTimeSeconds - 5
                      ? AppTheme.hint
                      : AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 650;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isCompact ? 16 : 28),
                    Text(
                      ref.tr('space_orbit_prompt'),
                      textAlign: TextAlign.center,
                      style: AppTheme.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: isCompact ? 18 : 26),
                    Row(
                      children: [
                        Expanded(child: _OrbitPlanetCard(planet: _round.lower)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OrbitDropZone(
                            round: _round,
                            selectedPlanet: _selectedPlanet,
                            answered: answered,
                            isCorrect: _isCorrect,
                            onAccept: _submit,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _OrbitPlanetCard(planet: _round.upper)),
                      ],
                    ),
                    SizedBox(height: isCompact ? 24 : 36),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isCompact ? 2.4 : 2.2,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _round.options.map((planet) {
                        final disabled =
                            answered || _selectedPlanet?.id == planet.id;
                        return _DraggablePlanetOption(
                          planet: planet,
                          disabled: disabled,
                          onTap: answered ? null : () => _submit(planet),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: isCompact ? 18 : 28),
                    if (answered) ...[
                      _OrbitFeedback(
                        correct: _isCorrect ?? false,
                        correctPlanet: _round.correct,
                        score: _results.last.score,
                      ),
                      const SizedBox(height: 16),
                      VoidActionButton(
                        onTap: _nextRound,
                        label: _roundIndex >= _totalRounds - 1
                            ? ref.tr('space_results')
                            : ref.tr('space_next'),
                      ),
                    ] else
                      SizedBox(
                        height: isCompact ? 116 : 132,
                        child: Center(
                          child: Text(
                            ref.tr('space_drag_hint'),
                            textAlign: TextAlign.center,
                            style: AppTheme.inter(
                              color: AppTheme.textTertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: isCompact ? 18 : 28),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrbitRound {
  final SpacePlanet lower;
  final SpacePlanet upper;
  final SpacePlanet correct;
  final List<SpacePlanet> options;

  const _OrbitRound({
    required this.lower,
    required this.upper,
    required this.correct,
    required this.options,
  });
}

class _OrbitRoundResult {
  final SpacePlanet correctPlanet;
  final SpacePlanet? selectedPlanet;
  final bool correct;
  final int timeSeconds;
  final int score;

  const _OrbitRoundResult({
    required this.correctPlanet,
    required this.selectedPlanet,
    required this.correct,
    required this.timeSeconds,
    required this.score,
  });
}

class _OrbitPlanetCard extends StatelessWidget {
  final SpacePlanet planet;

  const _OrbitPlanetCard({required this.planet});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppTheme.textTertiary, width: 0.5),
      ),
      child: Column(
        children: [
          Expanded(
            child: Image.asset(
              planet.assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            planet.name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTheme.inter(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitDropZone extends ConsumerWidget {
  final _OrbitRound round;
  final SpacePlanet? selectedPlanet;
  final bool answered;
  final bool? isCorrect;
  final ValueChanged<SpacePlanet> onAccept;

  const _OrbitDropZone({
    required this.round,
    required this.selectedPlanet,
    required this.answered,
    required this.isCorrect,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borderColor = !answered
        ? AppTheme.primary.withValues(alpha: 0.55)
        : (isCorrect ?? false)
        ? AppTheme.correct
        : AppTheme.wrong;

    return DragTarget<SpacePlanet>(
      onWillAcceptWithDetails: (_) => !answered,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 156,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hovering
                ? AppTheme.primaryDim
                : AppTheme.surfaceHigh.withValues(alpha: 0.86),
            borderRadius: AppTheme.cardRadius,
            border: Border.all(color: borderColor, width: hovering ? 1.5 : 0.8),
          ),
          child: selectedPlanet == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.arrowCircleDown(PhosphorIconsStyle.regular),
                      color: AppTheme.primary,
                      size: 22,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ref.tr('space_drop_here'),
                      textAlign: TextAlign.center,
                      style: AppTheme.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      child: Image.asset(
                        selectedPlanet!.assetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedPlanet!.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _DraggablePlanetOption extends StatelessWidget {
  final SpacePlanet planet;
  final bool disabled;
  final VoidCallback? onTap;

  const _DraggablePlanetOption({
    required this.planet,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = _PlanetOptionTile(planet: planet, disabled: disabled);
    final child = Pressable(onTap: onTap, child: tile);

    if (disabled) return child;

    return Draggable<SpacePlanet>(
      data: planet,
      ignoringFeedbackSemantics: true,
      feedback: Material(
        color: Colors.transparent,
        child: ExcludeSemantics(
          child: SizedBox(
            width: 160,
            child: _PlanetOptionTile(planet: planet, disabled: false),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _PlanetOptionTile(planet: planet, disabled: false),
      ),
      child: child,
    );
  }
}

class _PlanetOptionTile extends StatelessWidget {
  final SpacePlanet planet;
  final bool disabled;

  const _PlanetOptionTile({required this.planet, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.42 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.neutralRadius,
          border: Border.all(color: AppTheme.textTertiary, width: 0.5),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: Image.asset(planet.assetPath, fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                planet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitFeedback extends ConsumerWidget {
  final bool correct;
  final SpacePlanet correctPlanet;
  final int score;

  const _OrbitFeedback({
    required this.correct,
    required this.correctPlanet,
    required this.score,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = correct ? AppTheme.correct : AppTheme.wrong;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.neutralRadius,
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            correct ? Icons.check_rounded : Icons.close_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              correct
                  ? ref.tr('correct')
                  : '${ref.tr('correct')} : ${correctPlanet.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.inter(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '+$score',
            style: AppTheme.inter(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceOrbitSummary extends ConsumerWidget {
  final int totalScore;
  final int correctCount;
  final int totalRounds;
  final List<_OrbitRoundResult> results;

  const _SpaceOrbitSummary({
    required this.totalScore,
    required this.correctCount,
    required this.totalRounds,
    required this.results,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratio = totalRounds == 0 ? 0 : correctCount / totalRounds;
    final color = ratio == 1
        ? AppTheme.correct
        : ratio >= 0.8
        ? AppTheme.primary
        : ratio >= 0.5
        ? AppTheme.hint
        : AppTheme.wrong;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                ref.tr('space_orbit_title'),
                textAlign: TextAlign.center,
                style: AppTheme.inter(
                  color: color,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: AppTheme.neutralRadius,
                  border: Border.all(color: AppTheme.textTertiary, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ResultStat(
                      label: ref.tr('score'),
                      value: '$totalScore',
                      unit: 'pts',
                      color: color,
                    ),
                    Container(
                      width: 0.5,
                      height: 40,
                      color: AppTheme.textTertiary,
                    ),
                    ResultStat(
                      label: ref.tr('correct'),
                      value: '$correctCount',
                      unit: '/ $totalRounds',
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ...results.asMap().entries.map((entry) {
                final result = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: AppTheme.neutralRadius,
                    border: Border.all(
                      color: result.correct
                          ? AppTheme.correct.withValues(alpha: 0.5)
                          : AppTheme.wrong.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${entry.key + 1}',
                          style: AppTheme.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          result.correctPlanet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        result.selectedPlanet?.name ?? '-',
                        style: AppTheme.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '+${result.score}',
                        style: AppTheme.inter(
                          color: result.correct
                              ? AppTheme.correct
                              : AppTheme.textTertiary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 32),
              VoidActionButton(
                onTap: () => context.go('/space_orbit_game'),
                label: ref.tr('play_again'),
              ),
              const SizedBox(height: 10),
              Pressable(
                onTap: () => context.go('/'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    ref.tr('home'),
                    textAlign: TextAlign.center,
                    style: AppTheme.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
