import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voidguess/core/l10n/l10n.dart';
import 'package:voidguess/core/theme/app_theme.dart';
import 'package:voidguess/core/widgets/pressable.dart';
import 'package:voidguess/core/widgets/result_stat.dart';
import 'package:voidguess/core/widgets/void_action_button.dart';
import 'package:voidguess/data/services/hive_service.dart';
import 'package:voidguess/features/space_game/models/space_round_result.dart';

class SpaceResultsScreen extends ConsumerStatefulWidget {
  final List<SpaceRoundResult> results;
  final int totalScore;
  final int totalItems;

  const SpaceResultsScreen({
    super.key,
    required this.results,
    required this.totalScore,
    required this.totalItems,
  });

  @override
  ConsumerState<SpaceResultsScreen> createState() => _SpaceResultsScreenState();
}

class _SpaceResultsScreenState extends ConsumerState<SpaceResultsScreen> {
  @override
  void initState() {
    super.initState();
    _saveRun();
  }

  Future<void> _saveRun() async {
    final resultMaps = widget.results
        .map(
          (result) => {
            'leftPlanetName': result.leftPlanetName,
            'rightPlanetName': result.rightPlanetName,
            'guessMillionKm': result.guessMillionKm,
            'actualMillionKm': result.actualMillionKm,
            'differenceMillionKm': result.differenceMillionKm,
            'time': result.timeSeconds,
            'score': result.score,
          },
        )
        .toList();

    await HiveService().saveSpaceRun(
      totalScore: widget.totalScore,
      totalItems: widget.totalItems,
      avgTimeSeconds: _avgTime,
      avgDifferenceMillionKm: _avgDifference,
      results: resultMaps,
    );
    await HiveService().checkAndUnlockSpaceAchievements(
      totalScore: widget.totalScore,
      totalItems: widget.totalItems,
      avgTime: _avgTime,
      results: resultMaps,
    );
  }

  int get _avgTime {
    if (widget.results.isEmpty) return 0;
    return widget.results.fold<int>(
          0,
          (sum, result) => sum + result.timeSeconds,
        ) ~/
        widget.results.length;
  }

  double get _avgDifference {
    if (widget.results.isEmpty) return 0;
    return widget.results.fold<double>(
          0,
          (sum, result) => sum + result.differenceMillionKm,
        ) /
        widget.results.length;
  }

  String get _runLabelKey {
    final ratio = widget.totalScore / (widget.totalItems * 1000);
    if (ratio >= 0.9) return 'perfect';
    if (ratio >= 0.75) return 'great_job';
    if (ratio >= 0.5) return 'good_effort';
    return 'keep_practicing';
  }

  Color get _runColor {
    final ratio = widget.totalScore / (widget.totalItems * 1000);
    if (ratio >= 0.9) return AppTheme.correct;
    if (ratio >= 0.75) return AppTheme.primary;
    if (ratio >= 0.5) return AppTheme.hint;
    return AppTheme.wrong;
  }

  String _formatDistance(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)} Md';
    }
    return '${value.round()} M';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                ref.tr(_runLabelKey),
                textAlign: TextAlign.center,
                style: AppTheme.inter(
                  color: _runColor,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ref.tr('space'),
                textAlign: TextAlign.center,
                style: AppTheme.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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
                      value: '${widget.totalScore}',
                      unit: 'pts',
                      color: _runColor,
                    ),
                    Container(
                      width: 0.5,
                      height: 40,
                      color: AppTheme.textTertiary,
                    ),
                    ResultStat(
                      label: ref.tr('avg_time'),
                      value: '$_avgTime',
                      unit: 's',
                      color: AppTheme.primary,
                    ),
                    Container(
                      width: 0.5,
                      height: 40,
                      color: AppTheme.textTertiary,
                    ),
                    ResultStat(
                      label: ref.tr('space_avg_error'),
                      value: _formatDistance(_avgDifference),
                      unit: 'km',
                      color: AppTheme.hint,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                ref.tr('breakdown'),
                style: AppTheme.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.results.asMap().entries.map((entry) {
                final index = entry.key;
                final result = entry.value;
                final color = result.score >= 850
                    ? AppTheme.correct
                    : result.score >= 550
                    ? AppTheme.hint
                    : AppTheme.wrong;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: AppTheme.neutralRadius,
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${index + 1}',
                          style: AppTheme.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${result.leftPlanetName} - ${result.rightPlanetName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.inter(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${ref.tr('space_difference')} ${_formatDistance(result.differenceMillionKm)} km',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${result.timeSeconds}s',
                        style: AppTheme.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '+${result.score}',
                        style: AppTheme.inter(
                          color: color,
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
                onTap: () => context.go('/space_game'),
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
