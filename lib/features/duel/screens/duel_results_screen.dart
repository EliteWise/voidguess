// lib/features/duel/screens/duel_results_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/void_action_button.dart';
import '../providers/duel_provider.dart';

class DuelResultsScreen extends ConsumerWidget {
  const DuelResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duelProvider);
    final me = state.me;
    final players = state.players;

    if (me == null || players.length < 2) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primary,
            strokeWidth: 1.5,
          ),
        ),
      );
    }

    final compareByScore = state.isSpaceGame;
    final rankedPlayers = [...players]
      ..sort((a, b) {
        if (compareByScore) {
          final scoreCompare = b.totalScore.compareTo(a.totalScore);
          if (scoreCompare != 0) return scoreCompare;
        } else {
          final correctCompare = b.correctCount.compareTo(a.correctCount);
          if (correctCompare != 0) return correctCompare;
        }
        return a.avgTime.compareTo(b.avgTime);
      });
    final best = rankedPlayers.first;
    final iWon = compareByScore
        ? me.totalScore == best.totalScore && me.avgTime == best.avgTime
        : me.correctCount == best.correctCount && me.avgTime == best.avgTime;
    final tiedWinners = rankedPlayers.where((player) {
      if (compareByScore) {
        return player.totalScore == best.totalScore &&
            player.avgTime == best.avgTime;
      }
      return player.correctCount == best.correctCount &&
          player.avgTime == best.avgTime;
    }).length;
    final isDraw = tiedWinners > 1 && iWon;

    String resultLabel;
    Color resultColor;
    if (isDraw) {
      resultLabel = ref.tr('draw');
      resultColor = AppTheme.hint;
    } else if (iWon) {
      resultLabel = ref.tr('you_win');
      resultColor = AppTheme.correct;
    } else {
      resultLabel = ref.tr('you_lose');
      resultColor = AppTheme.wrong;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // ── Result label ──────────────────────────────────────────
              Text(
                resultLabel,
                style: AppTheme.inter(
                  color: resultColor,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${ref.tr('multiplayer')} · ${ref.tr(state.selectedGame.labelKey)}',
                style: AppTheme.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // ── Classement ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: AppTheme.neutralRadius,
                  border: Border.all(color: AppTheme.textTertiary, width: 0.5),
                ),
                child: Column(
                  children: rankedPlayers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final player = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == rankedPlayers.length - 1 ? 0 : 12,
                      ),
                      child: _PlayerResultRow(
                        position: index + 1,
                        player: player,
                        isMe: player.id == state.playerId,
                        compareByScore: compareByScore,
                        totalRounds: state.totalRounds,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 32),

              // ── Rematch ───────────────────────────────────────────────
              VoidActionButton(
                onTap: () {
                  ref.read(duelProvider.notifier).leaveRoom();
                  context.go('/duel');
                },
                label: ref.tr('play_again'),
              ),
              const SizedBox(height: 10),

              // ── Home ──────────────────────────────────────────────────
              Pressable(
                onTap: () {
                  ref.read(duelProvider.notifier).leaveRoom();
                  context.go('/');
                },
                child: Container(
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

// ─── Result row ─────────────────────────────────────────────────────────────

class _PlayerResultRow extends StatelessWidget {
  final int position;
  final DuelPlayer player;
  final bool isMe;
  final bool compareByScore;
  final int totalRounds;

  const _PlayerResultRow({
    required this.position,
    required this.player,
    required this.isMe,
    required this.compareByScore,
    required this.totalRounds,
  });

  @override
  Widget build(BuildContext context) {
    final primaryValue = compareByScore
        ? '${player.totalScore}'
        : '${player.correctCount} / $totalRounds';

    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '#$position',
            style: AppTheme.inter(
              color: isMe ? AppTheme.primary : AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            player.name,
            style: AppTheme.inter(
              color: isMe ? AppTheme.primary : AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          primaryValue,
          style: AppTheme.inter(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${player.avgTime.toStringAsFixed(1)}s',
          style: AppTheme.inter(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
