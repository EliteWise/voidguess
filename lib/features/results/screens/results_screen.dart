import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:voidguess/core/widgets/result_stat.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/rank_progress_bar.dart';
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
  int _rankIndexBefore = 0;

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
      final rankIndexBefore = HiveService().getCurrentRankIndex();
      final vp = await HiveService().updateRank(
          widget.totalScore, widget.mode.isHardcore);
      setState(() {
        _vpGained = vp;
        _rankIndexBefore = rankIndexBefore;
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
          content: Text(
            'Result copied to clipboard!',
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
    } else {
      Share.share(text);
    }
  }

  String get _runLabel {
    if (widget.isHardcoreFail) return 'Game over!';
    if (widget.itemsFound == widget.totalItems) return 'Perfect!';
    if (widget.itemsFound >= widget.totalItems * 0.7) return 'Great job!';
    if (widget.itemsFound >= widget.totalItems * 0.4) return 'Good effort!';
    return 'Keep practicing!';
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

              // ── Label run ────────────────────────────────────────────────
              Text(
                _runLabel,
                style: AppTheme.inter(
                  color: _runColor,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                widget.mode.label,
                style: AppTheme.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              // ── VP ───────────────────────────────────────────────────────
              if (widget.totalItems == 10 && _vpGained != 0) ...[
                const SizedBox(height: 24),
                RankProgressBar(
                  vpBefore: HiveService().getVPInCurrentRank() - _vpGained,
                  vpGained: _vpGained,
                  rankIndexBefore: _rankIndexBefore,
                  rankIndexAfter: HiveService().getCurrentRankIndex(),
                ),
              ],

              const SizedBox(height: 32),

              // ── Score global ─────────────────────────────────────────────
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
                    ResultStat(
                      label: 'Score',
                      value: '${widget.totalScore}',
                      unit: 'pts',
                      color: _runColor,
                    ),
                    Container(width: 0.5, height: 40, color: AppTheme.textTertiary),
                    ResultStat(
                      label: 'Found',
                      value: '${widget.itemsFound}',
                      unit: '/ ${widget.totalItems}',
                      color: AppTheme.primary,
                    ),
                    Container(width: 0.5, height: 40, color: AppTheme.textTertiary),
                    ResultStat(
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

              // ── Breakdown ────────────────────────────────────────────────
              Text(
                'Breakdown',
                style: AppTheme.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

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
                          ? AppTheme.correct.withOpacity(0.3)
                          : AppTheme.wrong.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${i + 1}',
                          style: AppTheme.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          result.name,
                          style: AppTheme.inter(
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
                        style: AppTheme.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        result.found ? '+${result.score}' : '—',
                        style: AppTheme.inter(
                          color: result.found
                              ? AppTheme.correct
                              : AppTheme.textTertiary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 32),

              // ── Boutons ──────────────────────────────────────────────────
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
                  child: Text(
                    'Play again',
                    textAlign: TextAlign.center,
                    style: AppTheme.inter(
                      color: AppTheme.background,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

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
                  child: Text(
                    'Share result',
                    textAlign: TextAlign.center,
                    style: AppTheme.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Pressable(
                onTap: () => context.go('/'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Home',
                    textAlign: TextAlign.center,
                    style: AppTheme.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
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