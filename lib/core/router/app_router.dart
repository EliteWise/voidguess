import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../screens/home_screen.dart';
import '../../features/game/screens/game_screen.dart';
import '../../features/results/screens/results_screen.dart';
import '../../features/achievements/screens/achievements_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) {
        final category = state.uri.queryParameters['category'] ?? 'game';
        return GameScreen(category: category);
      },
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ResultsScreen(
          score: extra['score'] as int,
          timeSeconds: extra['timeSeconds'] as int,
          itemName: extra['itemName'] as String,
          usedHint: extra['usedHint'] as bool,
          category: extra['category'] as String,
        );
      },
    ),
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsScreen(),
    ),
  ],
);