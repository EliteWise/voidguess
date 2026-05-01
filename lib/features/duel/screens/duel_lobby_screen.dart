// lib/features/duel/screens/duel_lobby_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
import '../providers/duel_provider.dart';

class DuelLobbyScreen extends ConsumerStatefulWidget {
  const DuelLobbyScreen({super.key});

  @override
  ConsumerState<DuelLobbyScreen> createState() => _DuelLobbyScreenState();
}

class _DuelLobbyScreenState extends ConsumerState<DuelLobbyScreen> {

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
                    '← Leave',
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
                'Room code',
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
                        'Code copied!',
                        style: AppTheme.inter(
                          color: AppTheme.background,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: AppTheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: AppTheme.inputRadius),
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
                'Tap to copy',
                style: AppTheme.inter(
                  color: AppTheme.textTertiary,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 48),

              // ── Players ───────────────────────────────────────────────
              _PlayerRow(
                label: state.me?.name ?? 'You',
                ready: state.me?.ready ?? false,
                isMe: true,
              ),
              const SizedBox(height: 12),
              state.opponentJoined
                  ? _PlayerRow(
                label: state.opponent!.name,
                ready: state.opponent!.ready,
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
                  'Waiting for opponent...',
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
                Pressable(
                  onTap: () => ref.read(duelProvider.notifier).toggleReady(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: (state.me?.ready ?? false)
                          ? AppTheme.correct
                          : AppTheme.primaryDeep,
                      borderRadius: AppTheme.cardRadius,
                    ),
                    child: Text(
                      (state.me?.ready ?? false) ? 'Ready!' : 'Ready',
                      textAlign: TextAlign.center,
                      style: AppTheme.inter(
                        color: AppTheme.background,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final String label;
  final bool ready;
  final bool isMe;

  const _PlayerRow({
    required this.label,
    required this.ready,
    required this.isMe,
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
          color: ready ? AppTheme.correct.withOpacity(0.5) : AppTheme.textTertiary,
          width: ready ? 1 : 0.5,
        ),
      ),
      child: Row(
        children: [
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
              '(you)',
              style: AppTheme.inter(
                color: AppTheme.textTertiary,
                fontSize: 12,
              ),
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