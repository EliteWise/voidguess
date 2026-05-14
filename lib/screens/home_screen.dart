import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:voidguess/core/l10n/app_strings.dart';
import 'package:voidguess/core/l10n/l10n.dart';
import 'package:voidguess/core/provider/locale_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/pressable.dart';
import '../core/widgets/rank_emblem.dart';
import '../core/widgets/update_banner.dart';
import '../core/widgets/void_action_button.dart';
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

  final audio = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadRank();
    _backgroundSong();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPlayerName());
  }

  @override
  void dispose() {
    audio.dispose();
    super.dispose();
  }

  void _backgroundSong() async {
    await audio.setSource(AssetSource('audio/home_page.wav'));
    await audio.setVolume(1.0);
    await audio.setReleaseMode(ReleaseMode.loop);
    await audio.resume();
  }

  void _checkPlayerName() {
    final name = HiveService().getPlayerName();
    if (name.isEmpty) {
      _showNameDialog();
    }
  }

  void _showNameDialog() {
    final controller = TextEditingController();
    final locale = ref.read(localeProvider);
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
                AppStrings.get('choose_name', locale),
                style: AppTheme.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.get('shown_to_opponents', locale),
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
                  hintText: AppStrings.get('enter_name', locale),
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
              VoidActionButton(
                onTap: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    HiveService().setPlayerName(name);
                    Navigator.of(dialogContext).pop();
                  }
                },
                label: AppStrings.get('continue_btn', locale),
                padding: const EdgeInsets.symmetric(vertical: 14),
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

  void _stopSong() {
    audio.stop();
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Pressable(
                                onTap: () => _stopSong(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: AppTheme.inputRadius,
                                    border: Border.all(
                                      color: AppTheme.textTertiary,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: PhosphorIcon(
                                    PhosphorIcons.musicNote(
                                      PhosphorIconsStyle.thin,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Pressable(
                                onTap: () => _toggleLocale(locale),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
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
                          ],
                        ),
                        const Spacer(),
                        const UpdateBanner(),
                        const _AnimatedTitle(),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: _SoloGameTile(
                                label: ref.tr('video_games'),
                                subtitle: ref.tr('mode_subtitle_compact'),
                                icon: PhosphorIcons.gameController(
                                  PhosphorIconsStyle.regular,
                                ),
                                onTap: () => _showModeSheet(context, 'game'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SoloGameTile(
                                label: ref.tr('movies'),
                                subtitle: ref.tr('mode_subtitle_compact'),
                                icon: PhosphorIcons.filmSlate(
                                  PhosphorIconsStyle.regular,
                                ),
                                onTap: () => _showModeSheet(context, 'movie'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _SoloGameTile(
                                label: ref.tr('flags'),
                                subtitle: ref.tr('solo_ranked_compact'),
                                icon: PhosphorIcons.flag(
                                  PhosphorIconsStyle.regular,
                                ),
                                onTap: () => _showFlagSheet(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SoloGameTile(
                                label: ref.tr('space'),
                                subtitle: ref.tr('space_subtitle_compact'),
                                icon: PhosphorIcons.rocketLaunch(
                                  PhosphorIconsStyle.regular,
                                ),
                                onTap: () => context.go('/space_game'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _SoloGameTile(
                                label: ref.tr('gemstones'),
                                subtitle: ref.tr('gemstones_subtitle_compact'),
                                icon: PhosphorIcons.diamond(
                                PhosphorIconsStyle.regular,
                              ),
                              onTap: () => context.go('/gemstone_game'),
                            ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SoloGameTile(
                                label: 'Olympus',
                                subtitle: 'Soon',
                                icon: PhosphorIcons.shield(
                                  PhosphorIconsStyle.regular,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 14),
                        _MultiplayerButton(
                          label: ref.tr('multiplayer'),
                          subtitle: ref.tr('multiplayer_subtitle'),
                          onTap: () => context.go('/duel'),
                        ),
                        const Spacer(),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: RankEmblem(
                                  rankIndex: _rankIndex,
                                  size: 24,
                                ),
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
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 20,
                            ),
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
                                  PhosphorIcons.trophy(
                                    PhosphorIconsStyle.regular,
                                  ),
                                  color: AppTheme.textSecondary,
                                  size: 16,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  ref.tr('stats_achievements'),
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
              ),
            );
          },
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
      child: _buildTitleContent(color1: Colors.white, color2: Colors.white),
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

class _SoloGameTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final String subtitle;

  const _SoloGameTile({
    required this.label,
    required this.icon,
    this.onTap,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 90,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(1.0, -1.0),
          end: const Alignment(-0.5, 1.0),
          colors: [
            AppTheme.primaryDeep.withValues(alpha: 0.08),
            AppTheme.surface,
          ],
        ),
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppTheme.textTertiary, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.primaryDim,
              borderRadius: AppTheme.chipRadius,
            ),
            child: Center(
              child: Icon(icon, color: AppTheme.primary, size: 17),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
            color: AppTheme.textTertiary,
            size: 11,
          ),
        ],
      ),
    );
    return Pressable(onTap: onTap, child: content);
  }
}

class _MultiplayerButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MultiplayerButton({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(1.0, -1.0),
            end: const Alignment(-1.0, 1.0),
            colors: [
              AppTheme.primary.withValues(alpha: 0.32),
              AppTheme.primaryDeep.withValues(alpha: 0.7),
              AppTheme.textTertiary.withValues(alpha: 0.55),
            ],
          ),
          borderRadius: AppTheme.cardRadius,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: AppTheme.cardRadius,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: AppTheme.chipRadius,
                  border: Border.all(
                    color: AppTheme.primaryDeep.withValues(alpha: 0.55),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    PhosphorIcons.sword(PhosphorIconsStyle.bold),
                    color: AppTheme.primary,
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: AppTheme.inter(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryDeep.withValues(alpha: 0.18),
                            borderRadius: AppTheme.inputRadius,
                          ),
                          child: Text(
                            '1v1',
                            style: AppTheme.inter(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
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
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.correct,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                color: AppTheme.primary,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSheet extends ConsumerWidget {
  final String category;

  const _ModeSheet({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            ref.tr('choose_mode'),
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
                  title: ref.tr('quick'),
                  subtitle: ref.tr('items_5'),
                  description: ref.tr('fast_session'),
                  isHardcore: false,
                  isRanked: false,
                  isDoubleVP: false,
                  onTap: () {
                    Navigator.pop(context);
                    context.go(
                      '/game',
                      extra: {
                        'mode': RunMode.quickNormal,
                        'category': category,
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeCard(
                  title: ref.tr('full'),
                  subtitle: ref.tr('items_10'),
                  description: ref.tr('full_run'),
                  isHardcore: false,
                  isRanked: true,
                  isDoubleVP: false,
                  onTap: () {
                    Navigator.pop(context);
                    context.go(
                      '/game',
                      extra: {'mode': RunMode.fullNormal, 'category': category},
                    );
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
                  title: ref.tr('quick_hard'),
                  subtitle: ref.tr('items_5'),
                  description: ref.tr('one_mistake'),
                  isHardcore: true,
                  isRanked: false,
                  isDoubleVP: false,
                  onTap: () {
                    Navigator.pop(context);
                    context.go(
                      '/game',
                      extra: {
                        'mode': RunMode.quickHardcore,
                        'category': category,
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeCard(
                  title: ref.tr('full_hard'),
                  subtitle: ref.tr('items_10'),
                  description: ref.tr('one_mistake'),
                  isHardcore: true,
                  isRanked: true,
                  isDoubleVP: true,
                  onTap: () {
                    Navigator.pop(context);
                    context.go(
                      '/game',
                      extra: {
                        'mode': RunMode.fullHardcore,
                        'category': category,
                      },
                    );
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

class _FlagSheet extends ConsumerWidget {
  const _FlagSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            ref.tr('flags'),
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
                border: Border.all(color: AppTheme.textTertiary, width: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ref.tr('solo'),
                          style: AppTheme.inter(
                            color: AppTheme.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ref.tr('solo_ranked'),
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
