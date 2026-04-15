import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
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
  @override
  void initState() {
    super.initState();
    _saveRun();
  }

  Future<void> _saveRun() async {
    final avgTime = widget.itemResults.isEmpty
        ? 0
        : widget.itemResults.fold<int>(
        0, (sum, r) => sum + r.timeSeconds) ~/
        widget.itemResults.length;

    await HiveService().saveRun(
      totalScore: widget.totalScore,
      itemsFound: widget.itemsFound,
      totalItems: widget.totalItems,
      avgTimeSeconds: avgTime,
      mode: widget.mode.name,
      category: widget.category,
    );

    await HiveService().checkAndUnlockAchievements(
      totalScore: widget.totalScore,
      itemsFound: widget.itemsFound,
      totalItems: widget.totalItems,
      avgTime: avgTime,
      usedHint: widget.itemResults.any((r) => false),
    );
  }

  void _share() {
    final text =
        'VoidGuessr — ${widget.mode.label} · ${widget.itemsFound}/${widget.totalItems} trouvés · ${widget.totalScore} pts ! Peux-tu faire mieux ?';

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Résultat copié dans le presse-papiers !'),
        ),
      );
    } else {
      Share.share(text);
    }
  }

  String get _runLabel {
    if (widget.isHardcoreFail) return 'Run terminé !';
    if (widget.itemsFound == widget.totalItems) return 'Run parfait !';
    if (widget.itemsFound >= widget.totalItems * 0.7) return 'Bien joué !';
    if (widget.itemsFound >= widget.totalItems * 0.4) return 'Pas mal...';
    return 'Dur dur...';
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
              const SizedBox(height: 40),
              Text(
                _runLabel,
                style: TextStyle(
                  color: _runColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.mode.label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Score global
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
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
                    _GlobalStat(
                      label: 'Trouvés',
                      value: '${widget.itemsFound}',
                      unit: '/ ${widget.totalItems}',
                      color: AppTheme.primary,
                    ),
                    _GlobalStat(
                      label: 'Temps moyen',
                      value: widget.itemResults.isEmpty
                          ? '0'
                          : '${widget.itemResults.fold<int>(0, (s, r) => s + r.timeSeconds) ~/ widget.itemResults.length}',
                      unit: 's',
                      color: AppTheme.hint,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Détail par item
              const Text(
                'Détail',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.itemResults.asMap().entries.map((entry) {
                final i = entry.key;
                final result = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: result.found
                          ? AppTheme.correct.withOpacity(0.3)
                          : AppTheme.wrong.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${result.timeSeconds}s',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        result.found ? '+${result.score}' : '+0',
                        style: TextStyle(
                          color: result.found
                              ? AppTheme.correct
                              : AppTheme.wrong,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(
                  '/game',
                  extra: {
                    'mode': widget.mode,
                    'category': widget.category,
                  },
                ),
                child: const Text('Rejouer'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _share,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                ),
                child: const Text('Partager'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text(
                  'Accueil',
                  style: TextStyle(color: AppTheme.textSecondary),
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
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}