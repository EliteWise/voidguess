import 'package:flutter/material.dart';

import 'achievement_unlock_notifications.dart';

class ResultScreenShell extends StatelessWidget {
  final List<String> achievementIds;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const ResultScreenShell({
    super.key,
    required this.achievementIds,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
          AchievementUnlockNotifications(achievementIds: achievementIds),
        ],
      ),
    );
  }
}
