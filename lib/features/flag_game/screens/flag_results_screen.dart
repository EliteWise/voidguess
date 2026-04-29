import 'dart:io';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/rank_progress_bar.dart';
import '../../../core/widgets/result_stat.dart';
import '../../../data/services/hive_service.dart';
import '../providers/flag_game_provider.dart';

class FlagResultsScreen extends StatefulWidget {
  final List<FlagItemResult> results;
  final int totalScore;
  final int correctCount;
  final int totalItems;

  const FlagResultsScreen({
    super.key,
    required this.results,
    required this.totalScore,
    required this.correctCount,
    required this.totalItems,
  });

  @override
  State<FlagResultsScreen> createState() => _FlagResultsScreenState();
}

class _FlagResultsScreenState extends State<FlagResultsScreen> {
  int _vpGained = 0;
  int _rankIndexBefore = 0;

  @override
  void initState() {
    super.initState();
    _saveRun();
  }

  Future<void> _saveRun() async {
    final rankIndexBefore = HiveService().getCurrentRankIndex();
    final vp = await HiveService().updateFlagRank(
      correctCount: widget.correctCount,
      totalItems: widget.totalItems,
    );
    setState(() {
      _vpGained = vp;
      _rankIndexBefore = rankIndexBefore;
    });
  }

  void _share() {
    final text =
        'Void Flags — ${widget.correctCount}/${widget.totalItems} correct · ${widget.totalScore} pts! Can you do better?';
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
    final ratio = widget.correctCount / widget.totalItems;
    if (ratio == 1.0) return 'Perfect!';
    if (ratio >= 0.8) return 'Great job!';
    if (ratio >= 0.5) return 'Good effort!';
    return 'Keep practicing!';
  }

  Color get _runColor {
    final ratio = widget.correctCount / widget.totalItems;
    if (ratio == 1.0) return AppTheme.correct;
    if (ratio >= 0.8) return AppTheme.primary;
    if (ratio >= 0.5) return AppTheme.hint;
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

              // ── Label run ───────────────────────────────────────────────
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
                'FLAGS',
                style: AppTheme.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              // ── VP gagnés ───────────────────────────────────────────────
              if (_vpGained != 0) ...[
                const SizedBox(height: 24),
                RankProgressBar(
                  vpBefore: HiveService().getVPInCurrentRank() - _vpGained,
                  vpGained: _vpGained,
                  rankIndexBefore: _rankIndexBefore,
                  rankIndexAfter: HiveService().getCurrentRankIndex(),
                ),
              ],

              const SizedBox(height: 40),

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
                      label: 'Avg time',
                      value: widget.results.isEmpty
                          ? '0'
                          : '${(widget.results.fold<int>(0, (s, r) => s + r.timeSeconds) ~/ widget.results.length)}',
                      unit: 's',
                      color: _runColor,
                    ),
                    Container(width: 0.5, height: 40, color: AppTheme.textTertiary),
                    ResultStat(
                      label: 'Correct',
                      value: '${widget.correctCount}',
                      unit: '/ ${widget.totalItems}',
                      color: AppTheme.primary,
                    ),
                    Container(width: 0.5, height: 40, color: AppTheme.textTertiary),
                    ResultStat(
                      label: 'Accuracy',
                      value: '${((widget.correctCount / widget.totalItems) * 100).round()}',
                      unit: '%',
                      color: AppTheme.hint,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Breakdown ───────────────────────────────────────────────
              Text(
                'Breakdown',
                style: AppTheme.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              ...widget.results.asMap().entries.map((entry) {
                final i = entry.key;
                final result = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: AppTheme.neutralRadius,
                    border: Border.all(
                      color: result.correct
                          ? AppTheme.correct.withOpacity(0.5)
                          : AppTheme.wrong.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Numéro
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
                      const SizedBox(width: 8),

                      // Drapeau
                      ClipRRect(
                        borderRadius: AppTheme.inputRadius,
                        child: SizedBox(
                          width: 36,
                          height: 24,
                          child: CountryFlag.fromCountryCode(
                            // Récupère le code depuis le nom — à améliorer
                            result.countryCode
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Nom du pays
                      Expanded(
                        child: Text(
                          result.countryName,
                          style: AppTheme.inter(
                            color: result.correct
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Temps
                      Text(
                        '${result.timeSeconds}s',
                        style: AppTheme.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 32),

              // ── Boutons ─────────────────────────────────────────────────
              Pressable(
                onTap: () => context.go('/flag_game'),
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
                      letterSpacing: 1,
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