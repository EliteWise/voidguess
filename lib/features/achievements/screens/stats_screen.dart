import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:voidguess/core/l10n/app_strings.dart';
import 'package:voidguess/core/l10n/l10n.dart';
import 'package:voidguess/core/provider/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/achievement.dart';
import '../../../data/services/hive_service.dart';
import '../../../data/repositories/achievement_repository.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular),
            color: AppTheme.textSecondary,
          ),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          ref.tr('stats_achievements'),
          style: AppTheme.inter(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.neutralRadius,
                border: Border.all(color: AppTheme.textTertiary, width: 0.5),
              ),
              child: Row(
                children: [
                  _TabPill(
                    label: ref.tr('stats_label'),
                    selected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  _TabPill(
                    label: ref.tr('achievements_label'),
                    selected: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _selectedIndex == 0
                ? const _StatsTab()
                : const _AchievementsTab(),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryDim : Colors.transparent,
            borderRadius: AppTheme.neutralRadius,
            border: selected
                ? Border.all(
                    color: AppTheme.primaryDeep.withValues(alpha: 0.4),
                    width: 0.5,
                  )
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.inter(
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: selected ? 0.3 : 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  Future<void> _confirmResetRank(BuildContext context, WidgetRef ref) async {
    final locale = ref.read(localeProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.neutralRadius),
        title: Text(
          AppStrings.get('reset_rank_title', locale),
          style: AppTheme.inter(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          AppStrings.get('reset_rank_desc', locale),
          style: AppTheme.inter(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppStrings.get('cancel', locale),
              style: AppTheme.inter(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppStrings.get('reset', locale),
              style: AppTheme.inter(
                color: AppTheme.wrong,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HiveService().resetRank();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hive = HiveService();
    final totalRuns = hive.getTotalRuns();
    final successRate = hive.getSuccessRate();
    final bestScore = hive.getBestScore();
    final bestAvgTime = hive.getBestAvgTime();
    final bestRuns = _buildBestRuns(ref, hive);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ref.tr('best_run'),
            style: AppTheme.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (bestRuns.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.neutralRadius,
                border: Border.all(color: AppTheme.textTertiary, width: 0.5),
              ),
              child: Text(
                ref.tr('no_runs'),
                style: AppTheme.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            _BestRunsPanel(
              runs: bestRuns,
              scoreLabel: ref.tr('score'),
              defaultProgressLabel: ref.tr('correct'),
              timeLabel: ref.tr('time'),
            ),

          const SizedBox(height: 28),

          _GlobalCard(label: ref.tr('runs_played'), value: '$totalRuns'),

          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => _confirmResetRank(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: AppTheme.neutralRadius,
                border: Border.all(
                  color: AppTheme.wrong.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                ref.tr('reset_rank'),
                textAlign: TextAlign.center,
                style: AppTheme.inter(
                  color: AppTheme.wrong,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<_BestRunSummary> _buildBestRuns(WidgetRef ref, HiveService hive) {
    final summaries = <_BestRunSummary>[];
    final bestTitleRun = hive.getBestRun();
    final bestFlagRun = _bestByScore(hive.getFlagRuns());
    final bestSpaceRun = _bestByScore(hive.getSpaceRuns());
    final bestGemstoneRun = _bestByScore(hive.getGemstoneRuns());

    if (bestTitleRun != null) {
      summaries.add(
        _BestRunSummary(
          label: ref.tr('cat_guess'),
          score: bestTitleRun['totalScore'] as int? ?? 0,
          progressValue: bestTitleRun['itemsFound'] as int? ?? 0,
          progressTotal: bestTitleRun['totalItems'] as int? ?? 0,
          avgTime: bestTitleRun['avgTime'] as int? ?? 0,
        ),
      );
    }
    if (bestFlagRun != null) {
      summaries.add(
        _BestRunSummary(
          label: ref.tr('flags'),
          score: bestFlagRun['totalScore'] as int? ?? 0,
          progressValue: bestFlagRun['correctCount'] as int? ?? 0,
          progressTotal: bestFlagRun['totalItems'] as int? ?? 0,
          avgTime: bestFlagRun['avgTime'] as int? ?? 0,
        ),
      );
    }
    if (bestSpaceRun != null) {
      summaries.add(
        _BestRunSummary(
          label: ref.tr('space'),
          score: bestSpaceRun['totalScore'] as int? ?? 0,
          progressValue: null,
          progressTotal: null,
          avgTime: bestSpaceRun['avgTime'] as int? ?? 0,
          secondaryLabel: ref.tr('space_avg_error'),
          secondaryValue:
              '${((bestSpaceRun['avgDifference'] as num?) ?? 0).round()} M km',
        ),
      );
    }
    if (bestGemstoneRun != null) {
      summaries.add(
        _BestRunSummary(
          label: ref.tr('gemstones'),
          score: bestGemstoneRun['totalScore'] as int? ?? 0,
          progressValue: bestGemstoneRun['correctCount'] as int? ?? 0,
          progressTotal: bestGemstoneRun['totalItems'] as int? ?? 0,
          avgTime: bestGemstoneRun['avgTime'] as int? ?? 0,
        ),
      );
    }

    return summaries;
  }

  Map<String, dynamic>? _bestByScore(List<Map> runs) {
    if (runs.isEmpty) return null;
    runs.sort(
      (a, b) => ((b['totalScore'] as int?) ?? 0).compareTo(
        (a['totalScore'] as int?) ?? 0,
      ),
    );
    return Map<String, dynamic>.from(runs.first);
  }
}

class _BestRunSummary {
  final String label;
  final int score;
  final int? progressValue;
  final int? progressTotal;
  final int avgTime;
  final String? secondaryLabel;
  final String? secondaryValue;

  const _BestRunSummary({
    required this.label,
    required this.score,
    required this.progressValue,
    required this.progressTotal,
    required this.avgTime,
    this.secondaryLabel,
    this.secondaryValue,
  });
}

class _BestRunsPanel extends StatelessWidget {
  final List<_BestRunSummary> runs;
  final String scoreLabel;
  final String defaultProgressLabel;
  final String timeLabel;

  const _BestRunsPanel({
    required this.runs,
    required this.scoreLabel,
    required this.defaultProgressLabel,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final best = [...runs]..sort((a, b) => b.score.compareTo(a.score));
    final topRun = best.first;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(
          color: AppTheme.textTertiary.withValues(alpha: 0.85),
          width: 0.5,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BestRunsPanelPainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.background.withValues(alpha: 0.72),
                        borderRadius: AppTheme.inputRadius,
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.16),
                          width: 0.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          PhosphorIcons.chartLineUp(PhosphorIconsStyle.regular),
                          color: AppTheme.primary,
                          size: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topRun.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.inter(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            scoreLabel,
                            style: AppTheme.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${topRun.score}',
                      style: AppTheme.inter(
                        color: AppTheme.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'pts',
                      style: AppTheme.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...runs.map((run) {
                  return _BestRunLine(
                    run: run,
                    scoreLabel: scoreLabel,
                    defaultProgressLabel: defaultProgressLabel,
                    timeLabel: timeLabel,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BestRunsPanelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45
      ..color = AppTheme.textTertiary.withValues(alpha: 0.14);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.primaryDeep.withValues(alpha: 0.22);
    final pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.primary.withValues(alpha: 0.28);

    for (double x = 24; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 22; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = [
      Offset(size.width * 0.08, size.height * 0.78),
      Offset(size.width * 0.25, size.height * 0.58),
      Offset(size.width * 0.43, size.height * 0.66),
      Offset(size.width * 0.61, size.height * 0.36),
      Offset(size.width * 0.82, size.height * 0.48),
      Offset(size.width * 0.94, size.height * 0.28),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, linePaint);
    for (final point in points) {
      canvas.drawCircle(point, 2.4, pointPaint);
    }

    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          AppTheme.primaryDeep.withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);
  }

  @override
  bool shouldRepaint(_BestRunsPanelPainter oldDelegate) => false;
}

class _BestRunLine extends StatelessWidget {
  final _BestRunSummary run;
  final String scoreLabel;
  final String defaultProgressLabel;
  final String timeLabel;

  const _BestRunLine({
    required this.run,
    required this.scoreLabel,
    required this.defaultProgressLabel,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = run.progressValue != null && run.progressTotal != null
        ? '${run.progressValue}/${run.progressTotal}'
        : run.secondaryValue ?? '--';
    final progressLabel = run.progressValue != null
        ? defaultProgressLabel
        : run.secondaryLabel ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryDeep.withValues(alpha: 0.85),
              borderRadius: AppTheme.inputRadius,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              run.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.inter(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: _InlineMetric(
              label: scoreLabel,
              value: '${run.score}',
              color: AppTheme.primary,
            ),
          ),
          Expanded(
            flex: 3,
            child: _InlineMetric(
              label: progressLabel,
              value: progress,
              color: AppTheme.correct,
            ),
          ),
          Expanded(
            flex: 2,
            child: _InlineMetric(
              label: timeLabel,
              value: '${run.avgTime}s',
              color: AppTheme.hint,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InlineMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.inter(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.inter(color: AppTheme.textSecondary, fontSize: 8),
        ),
      ],
    );
  }
}

class _GlobalCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;

  const _GlobalCard({required this.label, required this.value, this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.neutralRadius,
        border: Border.all(color: AppTheme.textTertiary, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTheme.inter(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          if (unit != null) ...[
            const SizedBox(width: 3),
            Text(
              unit!,
              style: AppTheme.inter(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.inter(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _AchievementsTab extends ConsumerStatefulWidget {
  const _AchievementsTab();

  @override
  ConsumerState<_AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends ConsumerState<_AchievementsTab> {
  final _repo = AchievementRepository();
  List<Achievement> _achievements = [];
  List<String> _unlocked = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final achievements = await _repo.getAchievements();
    final unlocked = HiveService().getUnlocked();
    setState(() {
      _achievements = achievements;
      _unlocked = unlocked;
    });
  }

  String _getDescription(Achievement achievement, bool isUnlocked) {
    if (achievement.category == 'secret' && !isUnlocked) {
      return achievement.description
          .split('')
          .map((c) => c == ' ' ? ' ' : '_')
          .join();
    }
    return achievement.description;
  }

  static const _categoryKeys = {
    'guess': 'cat_guess',
    'flags': 'cat_flags',
    'space': 'cat_space',
    'gemstones': 'cat_gemstones',
    'secret': 'cat_secret',
  };

  @override
  Widget build(BuildContext context) {
    if (_achievements.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primary,
          strokeWidth: 1.5,
        ),
      );
    }

    const categories = ['guess', 'flags', 'space', 'gemstones', 'secret'];
    final totalUnlocked = _achievements
        .where((achievement) => _unlocked.contains(achievement.id))
        .length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              '$totalUnlocked/${_achievements.length}',
              style: AppTheme.inter(
                color: AppTheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        ...categories.map((cat) {
          final items = _achievements.where((a) => a.category == cat).toList()
            ..sort((a, b) {
              final aUnlocked = _unlocked.contains(a.id);
              final bUnlocked = _unlocked.contains(b.id);
              if (aUnlocked == bUnlocked) return 0;
              return aUnlocked ? -1 : 1;
            });
          final unlockedCount = items
              .where((a) => _unlocked.contains(a.id))
              .length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ref.tr(_categoryKeys[cat]!),
                      style: AppTheme.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$unlockedCount/${items.length}',
                      style: AppTheme.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              ...items.map((achievement) {
                final isUnlocked = _unlocked.contains(achievement.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUnlocked ? AppTheme.surface : AppTheme.background,
                    borderRadius: AppTheme.neutralRadius,
                    border: Border.all(
                      color: isUnlocked
                          ? AppTheme.primary.withValues(alpha: 0.25)
                          : AppTheme.textTertiary.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? AppTheme.primaryDim
                              : AppTheme.surface,
                          borderRadius: AppTheme.inputRadius,
                        ),
                        child: Icon(
                          isUnlocked
                              ? PhosphorIcons.trophy(PhosphorIconsStyle.regular)
                              : PhosphorIcons.lock(PhosphorIconsStyle.regular),
                          color: isUnlocked
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement
                                  .title, // TODO: multilingue via achievements.json
                              style: AppTheme.inter(
                                color: isUnlocked
                                    ? AppTheme.textPrimary
                                    : AppTheme.textTertiary,
                                fontSize: 14,
                                fontWeight: isUnlocked
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getDescription(
                                achievement,
                                isUnlocked,
                              ), // TODO: multilingue
                              style: AppTheme.inter(
                                color: isUnlocked
                                    ? AppTheme.textSecondary
                                    : AppTheme.textTertiary,
                                fontSize: 11,
                                letterSpacing:
                                    achievement.category == 'secret' &&
                                        !isUnlocked
                                    ? 2
                                    : 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUnlocked)
                        Icon(
                          PhosphorIcons.checkCircle(PhosphorIconsStyle.regular),
                          color: AppTheme.correct,
                          size: 16,
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }
}
