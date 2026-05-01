import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:voidguess/core/provider/locale_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/pressable.dart';
import '../core/widgets/rank_emblem.dart';
import '../core/widgets/update_banner.dart';
import '../features/game/providers/game_provider.dart';
import '../data/services/hive_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _rankIndex = 0;
  int _vpInRank = 0;

  @override
  void initState() {
    super.initState();
    _loadRank();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPlayerName());
  }

  void _checkPlayerName() {
    final name = HiveService().getPlayerName();
    if (name.isEmpty) {
      _showNameDialog();
    }
  }

  void _showNameDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.neutralRadius),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose a name',
                style: AppTheme.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This will be shown to opponents',
                style: AppTheme.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                textAlign: TextAlign.center,
                maxLength: 16,
                style: AppTheme.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: AppTheme.inter(
                    color: AppTheme.textTertiary,
                    fontSize: 15,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.inputRadius,
                    borderSide: const BorderSide(
                      color: AppTheme.textTertiary,
                      width: 0.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppTheme.inputRadius,
                    borderSide: const BorderSide(
                      color: AppTheme.textTertiary,
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppTheme.inputRadius,
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1,
                    ),
                  ),
                ),
                onSubmitted: (_) {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    HiveService().setPlayerName(name);
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
              const SizedBox(height: 20),
              Pressable(
                onTap: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    HiveService().setPlayerName(name);
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDeep,
                    borderRadius: AppTheme.cardRadius,
                  ),
                  child: Text(
                    'Continue',
                    textAlign: TextAlign.center,
                    style: AppTheme.inter(
                      color: AppTheme.background,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadRank() {
    final hive = HiveService();
    setState(() {
      _rankIndex = hive.getCurrentRankIndex();
      _vpInRank = hive.getVPInCurrentRank();
    });
  }

  void _showModeSheet(BuildContext context, String category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ModeSheet(category: category),
    ).then((_) => _loadRank());
  }

  static const List<Color> _rankColors = [
    Color(0xFF444458),
    Color(0xFFCD7F32),
    Color(0xFFC0C0C0),
    Color(0xFFFFD700),
    Color(0xFF00E5CC),
    Color(0xFF4FC3F7),
    Color(0xFF9B59B6),
    Color(0xFFFF1744),
  ];

  void _toggleLocale(lang) {
    final newLocale = lang == 'fr' ? 'en' : 'fr';
    ref.read(localeProvider.notifier).state = newLocale;
    Hive.box('stats').put('locale', newLocale);
  }

  void _showFlagSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _FlagSheet(),
    ).then((_) => _loadRank());
  }

  @override
  Widget build(BuildContext context) {
    final rankName = HiveService.rankNames[_rankIndex];
    final rankColor = _rankColors[_rankIndex];
    final isVoidMaster = _rankIndex >= HiveService.rankNames.length - 1;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Pressable(
                  onTap: () => _toggleLocale(locale),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: AppTheme.inputRadius,
                      border: Border.all(
                        color: AppTheme.textTertiary,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      locale.toUpperCase(),
                      style: AppTheme.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const UpdateBanner(),
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
              const SizedBox(height: 12),
              _CategoryButton(
                label: 'Flags',
                icon: PhosphorIcons.flag(PhosphorIconsStyle.regular),
                subtitle: 'Solo · 1v1',
                onTap: () => _showFlagSheet(context),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: RankEmblem(rankIndex: _rankIndex, size: 24),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isVoidMaster
                          ? '$rankName  $_vpInRank VP'
                          : '$rankName  $_vpInRank / 10 VP',
                      style: AppTheme.inter(
                        color: rankColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
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
                      Text(
                        'Stats & Achievements',
                        style: AppTheme.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
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
                style: AppTheme.inter(
                  color: isRevealed ? color1 : AppTheme.textTertiary,
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ).copyWith(decoration: TextDecoration.none),
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
                style: AppTheme.inter(
                  color: isRevealed ? color2 : AppTheme.textTertiary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ).copyWith(decoration: TextDecoration.none),
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
  final String subtitle;

  const _CategoryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.subtitle = 'Quick · Full · Hardcore',
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(1.0, -1.0),
            end: const Alignment(-0.5, 1.0),
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
                    style: AppTheme.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
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
          Text(
            'Choose your mode',
            style: AppTheme.inter(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ModeCard(
                  title: 'Quick',
                  subtitle: '5 items',
                  description: 'Fast session\n~2 minutes',
                  isHardcore: false,
                  isRanked: false,
                  isDoubleVP: false,
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
                  subtitle: '10 items',
                  description: 'Full run\n~4 minutes',
                  isHardcore: false,
                  isRanked: true,
                  isDoubleVP: false,
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Icon(
                PhosphorIcons.infinity(PhosphorIconsStyle.duotone),
                color: AppTheme.textTertiary,
                size: 20,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ModeCard(
                  title: 'Quick Hard',
                  subtitle: '5 items',
                  description: 'One mistake\nand it\'s over',
                  isHardcore: true,
                  isRanked: false,
                  isDoubleVP: false,
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
                  subtitle: '10 items',
                  description: 'One mistake\nand it\'s over',
                  isHardcore: true,
                  isRanked: true,
                  isDoubleVP: true,
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
  final bool isRanked;
  final bool isDoubleVP;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isHardcore,
    required this.isRanked,
    required this.isDoubleVP,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.inter(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTheme.inter(
                        color: color.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                if (isRanked)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.shield(PhosphorIconsStyle.fill),
                        color: isDoubleVP
                            ? AppTheme.wrong.withOpacity(0.6)
                            : AppTheme.primary.withOpacity(0.4),
                        size: 10,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isDoubleVP ? '×2 VP' : 'RANKED',
                        style: AppTheme.inter(
                          color: isDoubleVP
                              ? AppTheme.wrong.withOpacity(0.6)
                              : AppTheme.primary.withOpacity(0.4),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: AppTheme.inter(
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

class _FlagSheet extends StatelessWidget {
  const _FlagSheet();

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
          Text(
            'Flags',
            style: AppTheme.inter(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Pressable(
            onTap: () {
              Navigator.pop(context);
              context.go('/flag_game');
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: AppTheme.chipRadius,
                border: Border.all(
                  color: AppTheme.textTertiary,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solo',
                          style: AppTheme.inter(
                            color: AppTheme.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '10 flags · Ranked',
                          style: AppTheme.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.shield(PhosphorIconsStyle.fill),
                        color: AppTheme.primary.withOpacity(0.4),
                        size: 10,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'RANKED',
                        style: AppTheme.inter(
                          color: AppTheme.primary.withOpacity(0.4),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Pressable(
            onTap: () {
              Navigator.pop(context);
              context.go('/duel');
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: AppTheme.chipRadius,
                border: Border.all(
                  color: AppTheme.primaryDeep.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1v1',
                          style: AppTheme.inter(
                            color: AppTheme.primaryDeep,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '10 flags · Challenge a friend',
                          style: AppTheme.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    PhosphorIcons.sword(PhosphorIconsStyle.regular),
                    color: AppTheme.primaryDeep.withOpacity(0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}