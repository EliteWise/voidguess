// lib/features/duel/screens/duel_results_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
import '../providers/duel_provider.dart';

class DuelResultsScreen extends ConsumerWidget {
  const DuelResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duelProvider);
    final me = state.me;
    final opp = state.opponent;

    if (me == null || opp == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primary,
            strokeWidth: 1.5,
          ),
        ),
      );
    }

    final meCorrect = me.correctCount;
    final oppCorrect = opp.correctCount;
    final iWon = meCorrect > oppCorrect ||
        (meCorrect == oppCorrect && me.avgTime < opp.avgTime);
    final isDraw = meCorrect == oppCorrect && me.avgTime == opp.avgTime;

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
                ref.tr('duel_flags'),
                style: AppTheme.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // ── Comparatif ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: AppTheme.neutralRadius,
                  border: Border.all(
                    color: AppTheme.textTertiary,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        const SizedBox(width: 80),
                        Expanded(
                          child: Text(
                            me.name,
                            style: AppTheme.inter(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            opp.name,
                            style: AppTheme.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(height: 0.5, color: AppTheme.textTertiary),
                    const SizedBox(height: 16),

                    // Correct
                    _CompareRow(
                      label: ref.tr('correct'),
                      myValue: '$meCorrect / ${state.totalRounds}',
                      oppValue: '$oppCorrect / ${state.totalRounds}',
                      myWins: meCorrect > oppCorrect,
                      oppWins: oppCorrect > meCorrect,
                    ),
                    const SizedBox(height: 12),

                    // Avg time
                    _CompareRow(
                      label: ref.tr('avg_time'),
                      myValue: '${me.avgTime.toStringAsFixed(1)}s',
                      oppValue: '${opp.avgTime.toStringAsFixed(1)}s',
                      myWins: me.avgTime < opp.avgTime,
                      oppWins: opp.avgTime < me.avgTime,
                    ),
                    const SizedBox(height: 12),

                    // Accuracy
                    _CompareRow(
                      label: ref.tr('accuracy'),
                      myValue: '${((meCorrect / state.totalRounds) * 100).round()}%',
                      oppValue: '${((oppCorrect / state.totalRounds) * 100).round()}%',
                      myWins: meCorrect > oppCorrect,
                      oppWins: oppCorrect > meCorrect,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Rematch ───────────────────────────────────────────────
              Pressable(
                onTap: () {
                  ref.read(duelProvider.notifier).leaveRoom();
                  context.go('/duel');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDeep,
                    borderRadius: AppTheme.cardRadius,
                  ),
                  child: Text(
                    ref.tr('play_again'),
                    textAlign: TextAlign.center,
                    style: AppTheme.inter(
                      color: AppTheme.background,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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

// ─── Compare row ────────────────────────────────────────────────────────────

class _CompareRow extends StatelessWidget {
  final String label;
  final String myValue;
  final String oppValue;
  final bool myWins;
  final bool oppWins;

  const _CompareRow({
    required this.label,
    required this.myValue,
    required this.oppValue,
    required this.myWins,
    required this.oppWins,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTheme.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            myValue,
            style: AppTheme.inter(
              color: myWins ? AppTheme.correct : AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            oppValue,
            style: AppTheme.inter(
              color: oppWins ? AppTheme.correct : AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}