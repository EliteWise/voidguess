// lib/features/duel/screens/duel_menu_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voidguess/core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/services/hive_service.dart';
import '../providers/duel_provider.dart';

class DuelMenuScreen extends ConsumerStatefulWidget {
  const DuelMenuScreen({super.key});

  @override
  ConsumerState<DuelMenuScreen> createState() => _DuelMenuScreenState();
}

class _DuelMenuScreenState extends ConsumerState<DuelMenuScreen> {
  final _codeController = TextEditingController();
  bool _isJoining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final name = HiveService().getPlayerName();
    await ref.read(duelProvider.notifier).createRoom(name);
    if (mounted) context.go('/duel/lobby');
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = ref.tr('enter_code'));
      return;
    }

    setState(() {
      _isJoining = true;
      _error = null;
    });

    final name = HiveService().getPlayerName();
    final success = await ref.read(duelProvider.notifier).joinRoom(code, name);

    if (!mounted) return;

    if (success) {
      context.go('/duel/lobby');
    } else {
      setState(() {
        _isJoining = false;
        _error = ref.tr('room_not_found');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // ── Back button ───────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Pressable(
                  onTap: () => context.go('/'),
                  child: Text(
                    ref.tr('back'),
                    style: AppTheme.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── Title ─────────────────────────────────────────────────
              Text(
                '1v1',
                style: AppTheme.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ref.tr('flags'),
                style: AppTheme.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 48),

              // ── Create room ───────────────────────────────────────────
              Pressable(
                onTap: _createRoom,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDeep,
                    borderRadius: AppTheme.cardRadius,
                  ),
                  child: Text(
                    ref.tr('create_room'),
                    textAlign: TextAlign.center,
                    style: AppTheme.inter(
                      color: AppTheme.background,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Separator ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: Container(height: 0.5, color: AppTheme.textTertiary)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      ref.tr('or'),
                      style: AppTheme.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(child: Container(height: 0.5, color: AppTheme.textTertiary)),
                ],
              ),

              const SizedBox(height: 24),

              // ── Join room ─────────────────────────────────────────────
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: AppTheme.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: 'VG-XXXX',
                  hintStyle: AppTheme.inter(
                    color: AppTheme.textTertiary,
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.neutralRadius,
                    borderSide: BorderSide(
                      color: _error != null ? AppTheme.wrong : AppTheme.textTertiary,
                      width: 0.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppTheme.neutralRadius,
                    borderSide: BorderSide(
                      color: _error != null ? AppTheme.wrong : AppTheme.textTertiary,
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppTheme.neutralRadius,
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1,
                    ),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: AppTheme.inter(
                    color: AppTheme.wrong,
                    fontSize: 12,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              Pressable(
                onTap: _isJoining ? null : _joinRoom,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: AppTheme.chipRadius,
                    border: Border.all(
                      color: AppTheme.textTertiary,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _isJoining ? ref.tr('joining') : ref.tr('join_room'),
                    textAlign: TextAlign.center,
                    style: AppTheme.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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