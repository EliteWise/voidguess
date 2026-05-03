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
          icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular), color: AppTheme.textSecondary),
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
                border: Border.all(
                  color: AppTheme.textTertiary,
                  width: 0.5,
                ),
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
              color: AppTheme.primaryDeep.withOpacity(0.4),
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
          style: AppTheme.inter(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppStrings.get('cancel', locale),
              style: AppTheme.inter(color: AppTheme.textSecondary, fontSize: 13),
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
    final bestRun = hive.getBestRun();
    final totalRuns = hive.getTotalRuns();
    final successRate = hive.getSuccessRate();
    final bestScore = hive.getBestScore();
    final bestAvgTime = hive.getBestAvgTime();

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
          if (bestRun == null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.neutralRadius,
                border: Border.all(
                  color: AppTheme.textTertiary,
                  width: 0.5,
                ),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.neutralRadius,
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatCard(
                        label: ref.tr('score'),
                        value: '${bestRun['totalScore']}',
                        unit: 'pts',
                        color: AppTheme.primary,
                      ),
                      Container(
                        width: 0.5,
                        height: 40,
                        color: AppTheme.textTertiary,
                      ),
                      _StatCard(
                        label: ref.tr('found_label'),
                        value: '${bestRun['itemsFound']}',
                        unit: '/ ${bestRun['totalItems']}',
                        color: AppTheme.correct,
                      ),
                      Container(
                        width: 0.5,
                        height: 40,
                        color: AppTheme.textTertiary,
                      ),
                      _StatCard(
                        label: ref.tr('avg_time'),
                        value: '${bestRun['avgTime']}',
                        unit: 's',
                        color: AppTheme.hint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDim,
                      borderRadius: AppTheme.inputRadius,
                    ),
                    child: Text(
                      (bestRun['mode'] as String).toUpperCase(),
                      style: AppTheme.inter(
                        color: AppTheme.primary,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),
          Text(
            ref.tr('global'),
            style: AppTheme.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GlobalCard(
                  label: ref.tr('runs_played'),
                  value: '$totalRuns',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _GlobalCard(
                  label: ref.tr('success_rate'),
                  value: successRate.toStringAsFixed(0),
                  unit: '%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _GlobalCard(
                  label: ref.tr('best_score'),
                  value: '$bestScore',
                  unit: 'pts',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _GlobalCard(
                  label: ref.tr('best_avg_time'),
                  value: bestAvgTime == 9999 ? '--' : '$bestAvgTime',
                  unit: bestAvgTime == 9999 ? null : 's',
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => _confirmResetRank(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: AppTheme.neutralRadius,
                border: Border.all(
                  color: AppTheme.wrong.withOpacity(0.3),
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
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTheme.inter(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              unit,
              style: AppTheme.inter(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.inter(
            color: AppTheme.textSecondary,
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _GlobalCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;

  const _GlobalCard({
    required this.label,
    required this.value,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.neutralRadius,
        border: Border.all(
          color: AppTheme.textTertiary,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
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
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.inter(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
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
    'speed': 'cat_speed',
    'precision': 'cat_precision',
    'runs': 'cat_runs',
    'score': 'cat_score',
    'categories': 'cat_categories',
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

    final categories = [
      'speed',
      'precision',
      'runs',
      'score',
      'categories',
      'secret',
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: categories.map((cat) {
        final items = _achievements.where((a) => a.category == cat).toList();
        final unlockedCount =
            items.where((a) => _unlocked.contains(a.id)).length;
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
                        ? AppTheme.primary.withOpacity(0.25)
                        : AppTheme.textTertiary.withOpacity(0.5),
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
                            achievement.title,  // TODO: multilingue via achievements.json
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
                            _getDescription(achievement, isUnlocked),  // TODO: multilingue
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
      }).toList(),
    );
  }
}