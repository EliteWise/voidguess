// lib/features/duel/screens/duel_countdown_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/duel_provider.dart';

class DuelCountdownScreen extends ConsumerStatefulWidget {
  const DuelCountdownScreen({super.key});

  @override
  ConsumerState<DuelCountdownScreen> createState() => _DuelCountdownScreenState();
}

class _DuelCountdownScreenState extends ConsumerState<DuelCountdownScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(duelProvider.notifier).tickCountdown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duelProvider);

    ref.listen<DuelState>(duelProvider, (prev, next) {
      if (next.phase == DuelPhase.playing) {
        _timer?.cancel();
        context.go('/duel/game');
      }
    });

    return Scaffold(
      body: Center(
        child: Text(
          '${state.countdownValue}',
          style: AppTheme.inter(
            color: AppTheme.textPrimary,
            fontSize: 72,
            fontWeight: FontWeight.w800,
            letterSpacing: -2,
          ),
        ),
      ),
    );
  }
}