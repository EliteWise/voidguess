import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/hive_service.dart';

class Achievement {
  final String id;
  final String title;
  final String description;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
  });
}

const List<Achievement> allAchievements = [
  Achievement(
    id: 'speed_5s',
    title: 'Speed run',
    description: 'Deviner en moins de 5 secondes',
  ),
  Achievement(
    id: 'no_hint_10',
    title: 'Série parfaite',
    description: '10 bonnes réponses sans indice',
  ),
  Achievement(
    id: 'first_letter',
    title: '1ère lettre',
    description: 'Deviner avec seulement 1 lettre révélée',
  ),
  Achievement(
    id: 'perfect_score',
    title: 'Perfect',
    description: 'Obtenir 1000 pts',
  ),
  Achievement(
    id: 'veteran_100',
    title: 'Vétéran',
    description: '100 parties jouées',
  ),
  Achievement(
    id: 'both_categories',
    title: 'Encyclopédiste',
    description: 'Deviner dans les deux catégories',
  ),
];

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hive = HiveService();
    final unlocked = hive.getUnlocked();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Succès',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${unlocked.length}/${allAchievements.length}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: allAchievements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final achievement = allAchievements[index];
          final isUnlocked = unlocked.contains(achievement.id);
          return _AchievementCard(
            achievement: achievement,
            isUnlocked: isUnlocked,
          );
        },
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? AppTheme.primary : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppTheme.primary.withOpacity(0.2)
                  : AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isUnlocked ? Icons.emoji_events : Icons.lock_outline,
              color: isUnlocked ? AppTheme.primary : AppTheme.textSecondary,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            const Icon(Icons.check_circle, color: AppTheme.correct, size: 20),
        ],
      ),
    );
  }
}