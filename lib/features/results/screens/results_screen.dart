import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/services/hive_service.dart';
import '../../game/providers/game_provider.dart';

class ResultsScreen extends StatefulWidget {
  final List<ItemResult> itemResults;
  final int totalScore;
  final int itemsFound;
  final int totalItems;
  final RunMode mode;
  final String category;
  final bool isHardcoreFail;

  const ResultsScreen({
    super.key,
    required this.itemResults,
    required this.totalScore,
    required this.itemsFound,
    required this.totalItems,
    required this.mode,
    required this.category,
    required this.isHardcoreFail,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _vpGained = 0;

  @override
  void initState() {
    super.initState();
    _saveRun();
  }

  Future<void> _saveRun() async {
    final avgTime = widget.itemResults.isEmpty
        ? 0
        : widget.itemResults.fold<int>(0, (sum, r) => sum + r.timeSeconds) ~/
        widget.itemResults.length;

    final itemResultsMaps = widget.itemResults.map((r) => {
      'score': r.score,
      'time': r.timeSeconds,
      'found': r.found,
      'lettersRevealed': r.lettersRevealed,
    }).toList();

    await HiveService().saveRun(
      totalScore: widget.totalScore,
      itemsFound: widget.itemsFound,
      totalItems: widget.totalItems,
      avgTimeSeconds: avgTime,
      mode: widget.mode.name,
      category: widget.category,
      itemResults: itemResultsMaps,
    );

    await HiveService().checkAndUnlockAchievements(
      totalScore: widget.totalScore,
      itemsFound: widget.itemsFound,
      totalItems: widget.totalItems,
      avgTime: avgTime,
      usedHint: widget.itemResults.any((r) => r.usedHint),
      isHardcore: widget.mode.isHardcore,
      category: widget.category,
      itemResults: itemResultsMaps,
    );

    if (widget.totalItems == 10) {
      final vp = await HiveService().updateRank(
          widget.totalScore, widget.mode.isHardcore);
      setState(() {
        _vpGained = vp;
      });
    }
  }

  void _share() {
    final text =
        'Void Guess · ${widget.mode.label} · ${widget.itemsFound}/${widget.totalItems} found · ${widget.totalScore} pts! Can you do better?';

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Result copied to clipboard!',
            style: TextStyle(color: AppTheme.background, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.inputRadius),
        ),
      );
    } else {
      Share.share(text);
    }
  }

  String get _runLabel {
    if (widget.isHardcoreFail) return 'Run over.';
    if (widget.itemsFound == widget.totalItems) return 'Perfect run.';
    if (widget.itemsFound >= widget.totalItems * 0.7) return 'Well played.';
    if (widget.itemsFound >= widget.totalItems * 0.4) return 'Not bad...';
    return 'Rough one.';
  }

  Color get _runColor {
    if (widget.isHardcoreFail) return AppTheme.wrong;
    if (widget.itemsFound == widget.totalItems) return AppTheme.correct;
    if (widget.itemsFound >= widget.totalItems * 0.7) return AppTheme.primary;
    if (widget.itemsFound >= widget.totalItems * 0.4) return AppTheme.hint;
    return AppTheme.wrong;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                _runLabel,
                style: TextStyle(
                  color: _runColor,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                widget.mode.label.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              if (widget.totalItems == 10) ...[
                const SizedBox(height: 8),
                Text(
                  _vpGained > 0 ? '+$_vpGained VP' : '$_vpGained VP',
                  style: TextStyle(
                    color: _vpGained > 0 ? AppTheme.correct : _vpGained < 0
                        ? AppTheme.wrong
                        : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                ),
                    textAlign: TextAlign.center,
                ),
              ],
              // Score global
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: AppTheme.neutralRadius,
                  border: Border.all(
                    color: AppTheme.textTertiary,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _GlobalStat(
                      label: 'Score',
                      value: '${widget.totalScore}',
                      unit: 'pts',
                      color: _runColor,
                    ),
                    Container(width: 0.5, height: 40, color: AppTheme.textTertiary),
                    _GlobalStat(
                      label: 'Found',
                      value: '${widget.itemsFound}',
                      unit: '/ ${widget.totalItems}',
                      color: AppTheme.primary,
                    ),
                    Container(width: 0.5, height: 40, color: AppTheme.textTertiary),
                    _GlobalStat(
                      label: 'Avg time',
                      value: widget.itemResults.isEmpty
                          ? '0'
                          : '${widget.itemResults.fold<int>(0, (s, r) => s + r.timeSeconds) ~/ widget.itemResults.length}',
                      unit: 's',
                      color: AppTheme.hint,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Label détail
              const Text(
                'BREAKDOWN',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Détail par item
              ...widget.itemResults.asMap().entries.map((entry) {
                final i = entry.key;
                final result = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: AppTheme.neutralRadius,
                    border: Border.all(
                      color: result.found
                          ? AppTheme.correct.withOpacity(0.2)
                          : AppTheme.wrong.withOpacity(0.15),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          result.name,
                          style: TextStyle(
                            color: result.found
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${result.timeSeconds}s',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        result.found ? '+${result.score}' : '+0',
                        style: TextStyle(
                          color: result.found ? AppTheme.correct : AppTheme.wrong,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 32),

              // Bouton rejouer
              Pressable(
                onTap: () => context.go('/game', extra: {
                  'mode': widget.mode,
                  'category': widget.category,
                }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDeep,
                    borderRadius: AppTheme.cardRadius,
                  ),
                  child: const Text(
                    'Play again',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.background,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Bouton partager
              Pressable(
                onTap: _share,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: AppTheme.chipRadius,
                    border: Border.all(
                      color: AppTheme.textTertiary,
                      width: 0.5,
                    ),
                  ),
                  child: const Text(
                    'Share result',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Bouton accueil
              Pressable(
                onTap: () => context.go('/'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: const Text(
                    'Home',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      letterSpacing: 0.5,
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

class _GlobalStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _GlobalStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              unit,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}