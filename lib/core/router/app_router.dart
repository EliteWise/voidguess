import 'package:go_router/go_router.dart';
import '../../features/achievements/screens/stats_screen.dart';
import '../../features/duel/screens/duel_countdown_screen.dart';
import '../../features/duel/screens/duel_game_screen.dart';
import '../../features/duel/screens/duel_lobby_screen.dart';
import '../../features/duel/screens/duel_menu_screen.dart';
import '../../features/duel/screens/duel_results_screen.dart';
import '../../features/flag_game/providers/flag_game_provider.dart';
import '../../features/flag_game/screens/flag_game_screen.dart';
import '../../features/flag_game/screens/flag_results_screen.dart';
import '../../features/game/providers/game_provider.dart';
import '../../screens/home_screen.dart';
import '../../features/game/screens/game_screen.dart';
import '../../features/results/screens/results_screen.dart';

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
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final mode = extra['mode'] as RunMode? ?? RunMode.quickNormal;
        final category = extra['category'] as String? ?? 'game';
        return GameScreen(mode: mode, category: category);
      },
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final rawResults = extra['itemResults'] as List<ItemResult>? ?? [];
        return ResultsScreen(
          itemResults: rawResults,
          totalScore: extra['totalScore'] as int? ?? 0,
          itemsFound: extra['itemsFound'] as int? ?? 0,
          totalItems: extra['totalItems'] as int? ?? 0,
          mode: extra['mode'] as RunMode? ?? RunMode.quickNormal,
          category: extra['category'] as String? ?? 'game',
          isHardcoreFail: extra['isHardcoreFail'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: '/stats',
      builder: (context, state) => const StatsScreen(),
    ),
    GoRoute(
      path: '/flag_game',
      builder: (context, state) => const FlagGameScreen(),
    ),
    GoRoute(
      path: '/flag_results',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final results = extra['results'] as List<FlagItemResult>? ?? [];
        return FlagResultsScreen(
          results: results,
          totalScore: extra['totalScore'] as int? ?? 0,
          correctCount: extra['correctCount'] as int? ?? 0,
          totalItems: extra['totalItems'] as int? ?? 0,
        );
      },
    ),
    GoRoute(
      path: '/duel',
      builder: (context, state) => const DuelMenuScreen(),
    ),
    GoRoute(
      path: '/duel/lobby',
      builder: (context, state) => const DuelLobbyScreen(),
    ),
    GoRoute(
      path: '/duel/countdown',
      builder: (context, state) => const DuelCountdownScreen(),
    ),
    GoRoute(
      path: '/duel/game',
      builder: (context, state) => const DuelGameScreen(),
    ),
    GoRoute(
      path: '/duel/results',
      builder: (context, state) => const DuelResultsScreen(),
    ),
  ],
);