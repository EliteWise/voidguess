import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../features/game/providers/game_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showModeSheet(BuildContext context, String category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ModeSheet(category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const _AnimatedTitle(),
              const SizedBox(height: 64),
              _CategoryButton(
                label: 'Jeux vidéo',
                emoji: '🎮',
                onTap: () => _showModeSheet(context, 'game'),
              ),
              const SizedBox(height: 12),
              _CategoryButton(
                label: 'Films',
                emoji: '🎬',
                onTap: () => _showModeSheet(context, 'movie'),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/stats'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Stats & Succès',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

class _AnimatedTitle extends StatefulWidget {
  const _AnimatedTitle();

  @override
  State<_AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<_AnimatedTitle> {
  static const String _line1 = 'VOID';
  static const String _line2 = 'GUESS';

  List<String> _revealed1 = [];
  List<String> _revealed2 = [];
  bool _contentVisible = false;

  @override
  void initState() {
    super.initState();
    _revealed1 = List.filled(_line1.length, '_');
    _revealed2 = List.filled(_line2.length, '_');
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Révèle VOID lettre par lettre
    for (int i = 0; i < _line1.length; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() => _revealed1[i] = _line1[i]);
    }

    await Future.delayed(const Duration(milliseconds: 200));

    // Révèle GUESS lettre par lettre
    for (int i = 0; i < _line2.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() => _revealed2[i] = _line2[i]);
    }

    await Future.delayed(const Duration(milliseconds: 300));

    // Apparition du contenu
    if (!mounted) return;
    setState(() => _contentVisible = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _revealed1.map((letter) {
            final isRevealed = letter != '_';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                letter,
                style: TextStyle(
                  color: isRevealed ? AppTheme.primary : AppTheme.textSecondary.withOpacity(0.4),
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _revealed2.map((letter) {
            final isRevealed = letter != '_';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                letter,
                style: TextStyle(
                  color: isRevealed ? AppTheme.textPrimary : AppTheme.textSecondary.withOpacity(0.4),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final String label;
  final String emoji;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.label,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Quick · Full · Hardcore',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSheet extends StatelessWidget {
  final String category;

  const _ModeSheet({required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Choisis ton mode',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ModeCard(
                  title: 'Quick',
                  subtitle: '5 guess',
                  description: 'Session rapide\n~1 minute',
                  isHardcore: false,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/game', extra: {
                      'mode': RunMode.quickNormal,
                      'category': category,
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeCard(
                  title: 'Full',
                  subtitle: '10 guess',
                  description: 'Run complet\n~3 minutes',
                  isHardcore: false,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/game', extra: {
                      'mode': RunMode.fullNormal,
                      'category': category,
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModeCard(
                  title: 'Quick Hard',
                  subtitle: '5 guess',
                  description: 'Une erreur\net c\'est fini',
                  isHardcore: true,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/game', extra: {
                      'mode': RunMode.quickHardcore,
                      'category': category,
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeCard(
                  title: 'Full Hard',
                  subtitle: '10 guess',
                  description: 'Une erreur\net c\'est fini',
                  isHardcore: true,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/game', extra: {
                      'mode': RunMode.fullHardcore,
                      'category': category,
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final bool isHardcore;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isHardcore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isHardcore ? AppTheme.wrong : AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}