import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/achievement.dart';
import '../../../data/services/hive_service.dart';
import '../../../data/repositories/achievement_repository.dart';

class _AchievementsTab extends StatefulWidget {
  const _AchievementsTab();

  @override
  State<_AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<_AchievementsTab> {
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

  @override
  Widget build(BuildContext context) {
    if (_achievements.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    final categories = ['speed', 'precision', 'runs', 'score', 'categories', 'secret'];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: categories.map((cat) {
        final items = _achievements.where((a) => a.category == cat).toList();
        final unlockedCount = items.where((a) => _unlocked.contains(a.id)).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cat.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '$unlockedCount/${items.length}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            ...items.map((achievement) {
              final isUnlocked = _unlocked.contains(achievement.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnlocked
                        ? AppTheme.primary.withOpacity(0.4)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? AppTheme.primary.withOpacity(0.15)
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                        color: isUnlocked ? AppTheme.primary : AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: TextStyle(
                              color: isUnlocked
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            achievement.description,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUnlocked)
                      const Icon(Icons.check_circle, color: AppTheme.correct, size: 18),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Stats & Succès',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _TabPill(
                    label: 'Stats',
                    selected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  _TabPill(
                    label: 'Succès',
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
            color: selected
                ? AppTheme.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Meilleure run',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          if (bestRun == null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Aucune run terminée pour l\'instant.',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatCard(
                        label: 'Score',
                        value: '${bestRun['totalScore']}',
                        unit: 'pts',
                        color: AppTheme.primary,
                      ),
                      _StatCard(
                        label: 'Trouvés',
                        value: '${bestRun['itemsFound']}',
                        unit: '/ ${bestRun['totalItems']}',
                        color: AppTheme.correct,
                      ),
                      _StatCard(
                        label: 'Temps moyen',
                        value: '${bestRun['avgTime']}',
                        unit: 's',
                        color: AppTheme.hint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bestRun['mode'] as String,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'Global',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GlobalCard(
                  label: 'Runs joués',
                  value: '$totalRuns',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlobalCard(
                  label: 'Taux réussite',
                  value: '${successRate.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GlobalCard(
                  label: 'Meilleur score',
                  value: '$bestScore pts',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlobalCard(
                  label: 'Meilleur temps moyen',
                  value: bestAvgTime == 9999 ? '--' : '${bestAvgTime}s',
                ),
              ),
            ],
          ),
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
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _GlobalCard extends StatelessWidget {
  final String label;
  final String value;

  const _GlobalCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}