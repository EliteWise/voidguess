import 'package:flutter/material.dart';

import '../../data/models/achievement.dart';
import '../../data/repositories/achievement_repository.dart';
import 'achievement_notification.dart';

class AchievementUnlockNotifications extends StatefulWidget {
  final List<String> achievementIds;
  final String title;
  final AchievementRepository? repository;

  const AchievementUnlockNotifications({
    super.key,
    required this.achievementIds,
    this.title = 'Achievement unlocked',
    this.repository,
  });

  @override
  State<AchievementUnlockNotifications> createState() =>
      _AchievementUnlockNotificationsState();
}

class _AchievementUnlockNotificationsState
    extends State<AchievementUnlockNotifications> {
  late Future<List<Achievement>> _achievementsFuture;
  final Set<String> _dismissedIds = {};

  @override
  void initState() {
    super.initState();
    _achievementsFuture = _loadAchievements();
  }

  @override
  void didUpdateWidget(AchievementUnlockNotifications oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameIds(oldWidget.achievementIds, widget.achievementIds)) {
      _dismissedIds.clear();
      _achievementsFuture = _loadAchievements();
    }
  }

  Future<List<Achievement>> _loadAchievements() async {
    if (widget.achievementIds.isEmpty) return const [];

    final achievements = await (widget.repository ?? AchievementRepository())
        .getAchievements();
    return widget.achievementIds
        .map((id) => _findAchievementById(achievements, id))
        .whereType<Achievement>()
        .toList();
  }

  Achievement? _findAchievementById(List<Achievement> achievements, String id) {
    for (final achievement in achievements) {
      if (achievement.id == id) return achievement;
    }
    return null;
  }

  bool _sameIds(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  void _dismiss(String id) {
    setState(() {
      _dismissedIds.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Achievement>>(
      future: _achievementsFuture,
      builder: (context, snapshot) {
        final achievements =
            snapshot.data
                ?.where(
                  (achievement) => !_dismissedIds.contains(achievement.id),
                )
                .toList() ??
            const <Achievement>[];

        if (achievements.isEmpty) return const SizedBox.shrink();

        return IgnorePointer(
          ignoring: false,
          child: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final achievement in achievements) ...[
                    AchievementNotification(
                      title: widget.title,
                      achievementName: achievement.title,
                      description: achievement.description,
                      onDismiss: () => _dismiss(achievement.id),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
