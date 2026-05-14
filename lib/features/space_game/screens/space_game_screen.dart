import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:voidguess/core/l10n/l10n.dart';
import 'package:voidguess/core/theme/app_theme.dart';
import 'package:voidguess/core/widgets/pressable.dart';
import 'package:voidguess/core/widgets/void_action_button.dart';
import 'package:voidguess/features/space_game/models/space_round_result.dart';

class SpaceGameScreen extends ConsumerStatefulWidget {
  const SpaceGameScreen({super.key});

  @override
  ConsumerState<SpaceGameScreen> createState() => _SpaceGameScreenState();
}

class _SpaceGameScreenState extends ConsumerState<SpaceGameScreen> {
  static const int _totalRounds = 10;
  static const int _maxTimeSeconds = 30;
  static const double _maxGuessMillionKm = 4500;
  static const double _guessStepMillionKm = 10;

  final Random _random = Random();
  final List<SpaceRoundResult> _results = [];
  Timer? _tickTimer;
  late _Planet _leftPlanet;
  late _Planet _rightPlanet;
  double _guessMillionKm = 1000;
  int _roundIndex = 0;
  int _totalScore = 0;
  int _timeSeconds = 0;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _pickPair();
    _startTimer();
  }

  double get _actualDistanceMillionKm {
    return (_leftPlanet.orbitMillionKm - _rightPlanet.orbitMillionKm).abs();
  }

  double get _differenceMillionKm {
    return (_guessMillionKm - _actualDistanceMillionKm).abs();
  }

  int get _roundScore {
    final ratio = (_differenceMillionKm / _maxGuessMillionKm).clamp(0.0, 1.0);
    return (1000 * (1 - ratio)).round();
  }

  bool get _isFinished {
    return _showResult && _roundIndex >= _totalRounds - 1;
  }

  void _pickPair() {
    final planets = [..._planets]..shuffle(_random);
    _leftPlanet = planets[0];
    _rightPlanet = planets[1];
    _guessMillionKm = 1000;
    _timeSeconds = 0;
    _showResult = false;
  }

  void _startTimer() {
    _stopTimer();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_showResult || !mounted) return;
      setState(() => _timeSeconds += 1);
      if (_timeSeconds >= _maxTimeSeconds) {
        _submit();
      }
    });
  }

  void _stopTimer() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  void _submit() {
    if (_showResult) return;
    final result = SpaceRoundResult(
      leftPlanetName: _leftPlanet.name,
      rightPlanetName: _rightPlanet.name,
      guessMillionKm: _guessMillionKm,
      actualMillionKm: _actualDistanceMillionKm,
      differenceMillionKm: _differenceMillionKm,
      timeSeconds: _timeSeconds,
      score: _roundScore,
    );
    setState(() {
      _showResult = true;
      _results.add(result);
      _totalScore += _roundScore;
    });
    _stopTimer();
  }

  void _nextRound() {
    if (_isFinished) {
      context.go(
        '/space_results',
        extra: {
          'results': List<SpaceRoundResult>.unmodifiable(_results),
          'totalScore': _totalScore,
          'totalItems': _totalRounds,
        },
      );
      return;
    }
    setState(() {
      _roundIndex += 1;
      _pickPair();
    });
    _startTimer();
  }

  String _formatDistance(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)} Md km';
    }
    return '${value.round()} M km';
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRound = _roundIndex + 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '$currentRound / $_totalRounds',
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
            child: Pressable(
              onTap: () => context.go('/'),
              child: Icon(
                PhosphorIcons.x(PhosphorIconsStyle.bold),
                color: AppTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(18),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
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
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 620;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: isCompact ? 16 : 28),
                      Text(
                        ref.tr('space_distance_prompt'),
                        textAlign: TextAlign.center,
                        style: AppTheme.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: isCompact ? 18 : 28),
                      Row(
                        children: [
                          Expanded(
                            child: _PlanetCard(
                              planet: _leftPlanet,
                              height: isCompact ? 136 : 178,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 28,
                            height: 1,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _PlanetCard(
                              planet: _rightPlanet,
                              height: isCompact ? 136 : 178,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isCompact ? 24 : 44),
                      _DistancePanel(
                        guessLabel: ref.tr('space_estimate'),
                        value: _formatDistance(_guessMillionKm),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            activeTrackColor: AppTheme.primary,
                            inactiveTrackColor: AppTheme.textTertiary,
                            thumbColor: AppTheme.primary,
                            overlayColor: AppTheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            valueIndicatorColor: AppTheme.primary,
                            valueIndicatorTextStyle: AppTheme.inter(
                              color: AppTheme.background,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Slider(
                            min: 0,
                            max: _maxGuessMillionKm,
                            divisions:
                                (_maxGuessMillionKm / _guessStepMillionKm)
                                    .round(),
                            value: _guessMillionKm,
                            label: _formatDistance(_guessMillionKm),
                            onChanged: _showResult
                                ? null
                                : (value) {
                                    setState(() {
                                      _guessMillionKm =
                                          (value / _guessStepMillionKm)
                                              .round() *
                                          _guessStepMillionKm;
                                    });
                                  },
                          ),
                        ),
                      ),
                      SizedBox(height: isCompact ? 12 : 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _showResult
                            ? _ResultPanel(
                                key: const ValueKey('result'),
                                realLabel: ref.tr('space_real_distance'),
                                differenceLabel: ref.tr('space_difference'),
                                realDistance: _formatDistance(
                                  _actualDistanceMillionKm,
                                ),
                                difference: _formatDistance(
                                  _differenceMillionKm,
                                ),
                                score: _roundScore,
                                color: _roundScore >= 850
                                    ? AppTheme.correct
                                    : _roundScore >= 550
                                    ? AppTheme.hint
                                    : AppTheme.wrong,
                              )
                            : const SizedBox(
                                key: ValueKey('empty'),
                                height: 90,
                              ),
                      ),
                      const Spacer(),
                      SizedBox(height: isCompact ? 16 : 24),
                      VoidActionButton(
                        onTap: _showResult ? _nextRound : _submit,
                        label: _showResult
                            ? (_isFinished
                                  ? ref.tr('space_results')
                                  : ref.tr('space_next'))
                            : ref.tr('space_validate'),
                        letterSpacing: 0.5,
                      ),
                      if (_isFinished) ...[
                        const SizedBox(height: 14),
                        Text(
                          '${ref.tr('space_finished')} · $_totalScore pts · $_totalRounds ${ref.tr('space_rounds')}',
                          textAlign: TextAlign.center,
                          style: AppTheme.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      SizedBox(height: isCompact ? 18 : 28),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlanetCard extends StatelessWidget {
  final _Planet planet;
  final double height;

  const _PlanetCard({required this.planet, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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

class _DistancePanel extends StatelessWidget {
  final String guessLabel;
  final String value;
  final Widget child;

  const _DistancePanel({
    required this.guessLabel,
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
                guessLabel,
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

class _ResultPanel extends StatelessWidget {
  final String realLabel;
  final String differenceLabel;
  final String realDistance;
  final String difference;
  final int score;
  final Color color;

  const _ResultPanel({
    super.key,
    required this.realLabel,
    required this.differenceLabel,
    required this.realDistance,
    required this.difference,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.neutralRadius,
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ResultValue(label: realLabel, value: realDistance),
          ),
          Container(width: 0.5, height: 44, color: AppTheme.textTertiary),
          Expanded(
            child: _ResultValue(label: differenceLabel, value: difference),
          ),
          Container(width: 0.5, height: 44, color: AppTheme.textTertiary),
          Expanded(
            child: _ResultValue(label: 'Score', value: '$score', color: color),
          ),
        ],
      ),
    );
  }
}

class _ResultValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultValue({
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

class _Planet {
  final String name;
  final String assetPath;
  final double orbitMillionKm;

  const _Planet({
    required this.name,
    required this.assetPath,
    required this.orbitMillionKm,
  });
}

const List<_Planet> _planets = [
  _Planet(
    name: 'Mercure',
    assetPath: 'assets/planets/mercury.png',
    orbitMillionKm: 57.9,
  ),
  _Planet(
    name: 'Vénus',
    assetPath: 'assets/planets/venus.png',
    orbitMillionKm: 108.2,
  ),
  _Planet(
    name: 'Terre',
    assetPath: 'assets/planets/earth.png',
    orbitMillionKm: 149.6,
  ),
  _Planet(
    name: 'Mars',
    assetPath: 'assets/planets/mars.png',
    orbitMillionKm: 227.9,
  ),
  _Planet(
    name: 'Jupiter',
    assetPath: 'assets/planets/jupiter.png',
    orbitMillionKm: 778.6,
  ),
  _Planet(
    name: 'Saturne',
    assetPath: 'assets/planets/saturn.png',
    orbitMillionKm: 1433.5,
  ),
  _Planet(
    name: 'Uranus',
    assetPath: 'assets/planets/uranus.png',
    orbitMillionKm: 2872.5,
  ),
  _Planet(
    name: 'Neptune',
    assetPath: 'assets/planets/neptune.png',
    orbitMillionKm: 4495.1,
  ),
];
