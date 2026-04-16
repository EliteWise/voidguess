import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/pressable.dart';
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
                icon: PhosphorIcons.gameController(PhosphorIconsStyle.regular),
                onTap: () => _showModeSheet(context, 'game'),
              ),
              const SizedBox(height: 12),
              _CategoryButton(
                label: 'Films',
                icon: PhosphorIcons.filmSlate(PhosphorIconsStyle.regular),
                onTap: () => _showModeSheet(context, 'movie'),
              ),
              const Spacer(),
              Pressable(
                onTap: () => context.go('/stats'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: AppTheme.neutralRadius,
                    border: Border.all(
                      color: AppTheme.textTertiary,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.trophy(PhosphorIconsStyle.regular),
                        color: AppTheme.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Stats & Achievements',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
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

  @override
  void initState() {
    super.initState();
    _revealed1 = List.filled(_line1.length, '_');
    _revealed2 = List.filled(_line2.length, '_');
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (int i = 0; i < _line1.length; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() => _revealed1[i] = _line1[i]);
    }
    await Future.delayed(const Duration(milliseconds: 200));
    for (int i = 0; i < _line2.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() => _revealed2[i] = _line2[i]);
    }
  }

  Widget _buildTitleContent({required Color color1, required Color color2}) {
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
                  color: isRevealed ? color1 : AppTheme.textTertiary,
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  decoration: TextDecoration.none,
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
                  color: isRevealed ? color2 : AppTheme.textTertiary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  decoration: TextDecoration.none,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primary,
            AppTheme.primaryDeep,
            AppTheme.primaryDeep,
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: _buildTitleContent(
        color1: Colors.white,
        color2: Colors.white,
      ),
    );
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.45);
    path.lineTo(0, size.height * 0.65);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_DiagonalClipper oldClipper) => false;
}

class _CategoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(1.0, -1.0),
            end: Alignment(-0.5, 1.0),
            colors: [
              AppTheme.primaryDeep.withOpacity(0.08),
              AppTheme.surface,
            ],
          ),
          borderRadius: AppTheme.cardRadius,
          border: Border.all(
            color: AppTheme.textTertiary,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryDim,
                borderRadius: AppTheme.chipRadius,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: AppTheme.primary,
                  size: 20,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Quick · Full · Hardcore',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
              color: AppTheme.textTertiary,
              size: 12,
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
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose your mode',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ModeCard(
                  title: 'Quick',
                  subtitle: '5 guess',
                  description: 'Fast session\n~2 minutes',
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
                  description: 'Full run\n~4 minutes',
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1 ),
            child: Center(
              child: Icon(
                PhosphorIcons.infinity(PhosphorIconsStyle.duotone),
                color: AppTheme.textTertiary,
                size: 22,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ModeCard(
                  title: 'Quick Hard',
                  subtitle: '5 guess',
                  description: 'One mistake\nand it\'s over',
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
                  description: 'One mistake\nand it\'s over',
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
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: AppTheme.chipRadius,
          border: Border.all(
            color: isHardcore
                ? AppTheme.wrong.withOpacity(0.2)
                : AppTheme.textTertiary,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: color.withOpacity(0.5), // même couleur que le titre mais à 50% — lie les deux
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}