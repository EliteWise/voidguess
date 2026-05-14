import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voidguess/core/l10n/l10n.dart';
import 'package:voidguess/core/theme/app_theme.dart';
import 'package:voidguess/core/widgets/pressable.dart';
import 'package:voidguess/core/widgets/result_stat.dart';
import 'package:voidguess/core/widgets/void_action_button.dart';
import '../providers/gemstone_game_provider.dart';

class GemstoneResultsScreen extends ConsumerWidget {
  final List<GemstoneItemResult> results;
  final int totalScore;
  final int correctCount;
  final int totalItems;

  const GemstoneResultsScreen({
    super.key,
    required this.results,
    required this.totalScore,
    required this.correctCount,
    required this.totalItems,
  });

  int get _avgTime {
    if (results.isEmpty) return 0;
    return results.fold<int>(0, (sum, result) => sum + result.timeSeconds) ~/
        results.length;
  }

  String get _runLabelKey {
    final ratio = totalItems == 0 ? 0 : correctCount / totalItems;
    if (ratio == 1.0) return 'perfect';
    if (ratio >= 0.8) return 'great_job';
    if (ratio >= 0.5) return 'good_effort';
    return 'keep_practicing';
  }

  Color get _runColor {
    final ratio = totalItems == 0 ? 0 : correctCount / totalItems;
    if (ratio == 1.0) return AppTheme.correct;
    if (ratio >= 0.8) return AppTheme.primary;
    if (ratio >= 0.5) return AppTheme.hint;
    return AppTheme.wrong;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                ref.tr('gemstones'),
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
                      value: '$totalScore',
                      unit: 'pts',
                      color: _runColor,
                    ),
                    Container(
                      width: 0.5,
                      height: 40,
                      color: AppTheme.textTertiary,
                    ),
                    ResultStat(
                      label: ref.tr('correct'),
                      value: '$correctCount',
                      unit: '/ $totalItems',
                      color: AppTheme.primary,
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
              ...results.asMap().entries.map((entry) {
                final index = entry.key;
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
                          '${index + 1}',
                          style: AppTheme.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Image.asset(
                          result.assetPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          result.gemstoneName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(
                            color: result.correct
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${result.timeSeconds}s',
                        style: AppTheme.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        result.correct ? '+${result.score}' : '-',
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
                onTap: () => context.go('/gemstone_game'),
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
