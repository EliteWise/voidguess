// lib/features/duel/screens/duel_lobby_screen.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:voidguess/core/l10n/l10n.dart';
import 'package:voidguess/core/widgets/rank_emblem.dart';
import 'package:voidguess/core/widgets/void_action_button.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
import '../providers/duel_provider.dart';

class DuelLobbyScreen extends ConsumerStatefulWidget {
  const DuelLobbyScreen({super.key});

  @override
  ConsumerState<DuelLobbyScreen> createState() => _DuelLobbyScreenState();
}

class _DuelLobbyScreenState extends ConsumerState<DuelLobbyScreen> {
  final audio = AudioPlayer();

  @override
  void dispose() {
    audio.setReleaseMode(ReleaseMode.stop);
    audio.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duelProvider);

    // Navigation automatique selon la phase
    ref.listen<DuelState>(duelProvider, (prev, next) {
      if (next.phase == DuelPhase.countdown) {
        context.go('/duel/countdown');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // ── Back / Leave ──────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Pressable(
                  onTap: () {
                    ref.read(duelProvider.notifier).leaveRoom();
                    context.go('/duel');
                  },
                  child: Text(
                    ref.tr('leave'),
                    style: AppTheme.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── Room code ─────────────────────────────────────────────
              Text(
                ref.tr('room_code'),
                style: AppTheme.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Pressable(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: state.roomCode ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ref.tr('code_copied'),
                        style: AppTheme.inter(
                          color: AppTheme.background,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: AppTheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.inputRadius,
                      ),
                    ),
                  );
                },
                child: Text(
                  state.roomCode ?? '...',
                  style: AppTheme.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ref.tr('tap_to_copy'),
                style: AppTheme.inter(
                  color: AppTheme.textTertiary,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 48),

              _GameSelectionCard(
                gameLabel: ref.tr(state.selectedGame.labelKey),
                selectedGameLabel: ref.tr('selected_game'),
                availableLabel: ref.tr('available_now'),
                hostOnlyLabel: ref.tr('host_only_selection'),
                isHost: state.isHost,
                onTap: () => ref
                    .read(duelProvider.notifier)
                    .selectGame(duelGameFlags.key),
              ),

              const SizedBox(height: 24),

              // ── Players ───────────────────────────────────────────────
              _PlayerRow(
                rankIndex: state.me?.rankIndex ?? 0,
                label: state.me?.name ?? 'You',
                ready: state.me?.ready ?? false,
                isMe: true,
                youLabel: ref.tr('you'),
              ),
              const SizedBox(height: 12),
              state.opponentJoined
                  ? _PlayerRow(
                      rankIndex: state.opponent!.rankIndex,
                      label: state.opponent!.name,
                      ready: state.opponent!.ready,
                      youLabel: ref.tr('you'),
                      isMe: false,
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: AppTheme.neutralRadius,
                        border: Border.all(
                          color: AppTheme.textTertiary,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        ref.tr('waiting_opponent'),
                        textAlign: TextAlign.center,
                        style: AppTheme.inter(
                          color: AppTheme.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ),

              const SizedBox(height: 32),

              // ── Ready button ──────────────────────────────────────────
              if (state.opponentJoined)
                VoidActionButton(
                  onTap: () =>
                      ref.read(duelProvider.notifier).toggleReady(audio),
                  label: (state.me?.ready ?? false)
                      ? ref.tr('ready_done')
                      : ref.tr('ready'),
                  backgroundColor: (state.me?.ready ?? false)
                      ? AppTheme.correct
                      : AppTheme.action,
                  accentColor: (state.me?.ready ?? false)
                      ? AppTheme.background
                      : AppTheme.primaryDeep,
                ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameSelectionCard extends StatelessWidget {
  final String gameLabel;
  final String selectedGameLabel;
  final String availableLabel;
  final String hostOnlyLabel;
  final bool isHost;
  final VoidCallback onTap;

  const _GameSelectionCard({
    required this.gameLabel,
    required this.selectedGameLabel,
    required this.availableLabel,
    required this.hostOnlyLabel,
    required this.isHost,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: isHost ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.neutralRadius,
          border: Border.all(
            color: AppTheme.primaryDeep.withValues(alpha: 0.35),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryDim,
                borderRadius: AppTheme.chipRadius,
              ),
              child: Center(
                child: Icon(
                  PhosphorIcons.flag(PhosphorIconsStyle.regular),
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedGameLabel,
                    style: AppTheme.inter(
                      color: AppTheme.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    gameLabel,
                    style: AppTheme.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 112,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    availableLabel,
                    style: AppTheme.inter(
                      color: AppTheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  if (!isHost) ...[
                    const SizedBox(height: 4),
                    Text(
                      hostOnlyLabel,
                      style: AppTheme.inter(
                        color: AppTheme.textTertiary,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final int rankIndex;
  final String label;
  final bool ready;
  final bool isMe;
  final String youLabel;

  const _PlayerRow({
    required this.rankIndex,
    required this.label,
    required this.ready,
    required this.isMe,
    required this.youLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.neutralRadius,
        border: Border.all(
          color: ready
              ? AppTheme.correct.withOpacity(0.5)
              : AppTheme.textTertiary,
          width: ready ? 1 : 0.5,
        ),
      ),
      child: Row(
        children: [
          RankEmblem(rankIndex: rankIndex, size: 24),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.inter(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            Text(
              youLabel,
              style: AppTheme.inter(color: AppTheme.textTertiary, fontSize: 12),
            ),
          ],
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ready ? AppTheme.correct : AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
