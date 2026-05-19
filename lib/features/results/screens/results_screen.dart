import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:voidguess/core/l10n/app_strings.dart';
import 'package:voidguess/core/l10n/l10n.dart';
import 'package:voidguess/core/provider/locale_provider.dart';
import 'package:voidguess/core/widgets/result_screen_shell.dart';
import 'package:voidguess/core/widgets/result_stats_panel.dart';
import 'package:voidguess/core/widgets/void_action_button.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/rank_progress_bar.dart';
import '../../../data/services/hive_service.dart';
import '../../game/providers/game_provider.dart';

class ResultsScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  int _vpGained = 0;
  int _rankIndexBefore = 0;
  int _vpInRankBefore = 0;
  List<String> _unlockedAchievementIds = [];

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

    final itemResultsMaps = widget.itemResults
        .map(
          (r) => {
            'score': r.score,
            'time': r.timeSeconds,
            'found': r.found,
            'lettersRevealed': r.lettersRevealed,
          },
        )
        .toList();

    await HiveService().saveRun(
      totalScore: widget.totalScore,
      itemsFound: widget.itemsFound,
      totalItems: widget.totalItems,
      avgTimeSeconds: avgTime,
      mode: widget.mode.name,
      category: widget.category,
      itemResults: itemResultsMaps,
    );

    final unlockedIds = await HiveService().checkAndUnlockAchievements(
      totalScore: widget.totalScore,
      itemsFound: widget.itemsFound,
      totalItems: widget.totalItems,
      avgTime: avgTime,
      usedHint: widget.itemResults.any((r) => r.usedHint),
      isHardcore: widget.mode.isHardcore,
      category: widget.category,
      itemResults: itemResultsMaps,
    );

    if (!mounted) return;

    if (widget.totalItems == 10) {
      final rankIndexBefore = HiveService().getCurrentRankIndex();
      final vpInRankBefore = HiveService().getVPInCurrentRank();
      final vp = await HiveService().updateRank(
        widget.totalScore,
        widget.mode.isHardcore,
      );
      setState(() {
        _vpGained = vp;
        _rankIndexBefore = rankIndexBefore;
        _vpInRankBefore = vpInRankBefore;
        _unlockedAchievementIds = unlockedIds;
      });
    } else {
      setState(() {
        _unlockedAchievementIds = unlockedIds;
      });
    }
  }

  void _share() {
    final locale = ref.read(localeProvider);
    final text = AppStrings.format('share_guess', locale, {
      'mode': widget.mode.label,
      'found': '${widget.itemsFound}',
      'total': '${widget.totalItems}',
      'score': '${widget.totalScore}',
    });

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.get('result_copied', locale),
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

  String get _runLabelKey {
    if (widget.isHardcoreFail) return 'game_over';
    if (widget.itemsFound == widget.totalItems) return 'perfect';
    if (widget.itemsFound >= widget.totalItems * 0.7) return 'great_job';
    if (widget.itemsFound >= widget.totalItems * 0.4) return 'good_effort';
    return 'keep_practicing';
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
    return ResultScreenShell(
      achievementIds: _unlockedAchievementIds,
      children: [
        const SizedBox(height: 48),

        // ── Label run ────────────────────────────────────────────────
        Text(
          ref.tr(_runLabelKey),
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
            vpBefore: _vpInRankBefore,
            vpGained: _vpGained,
            rankIndexBefore: _rankIndexBefore,
            rankIndexAfter: HiveService().getCurrentRankIndex(),
          ),
        ],

        const SizedBox(height: 32),

        // ── Score global ─────────────────────────────────────────────
        ResultStatsPanel(
          stats: [
            ResultStatData(
              label: ref.tr('score'),
              value: '${widget.totalScore}',
              unit: 'pts',
              color: _runColor,
            ),
            ResultStatData(
              label: ref.tr('found_label'),
              value: '${widget.itemsFound}',
              unit: '/ ${widget.totalItems}',
              color: AppTheme.primary,
            ),
            ResultStatData(
              label: ref.tr('avg_time'),
              value: widget.itemResults.isEmpty
                  ? '0'
                  : '${widget.itemResults.fold<int>(0, (s, r) => s + r.timeSeconds) ~/ widget.itemResults.length}',
              unit: 's',
              color: AppTheme.hint,
            ),
          ],
        ),

        const SizedBox(height: 32),

        // ── Breakdown ────────────────────────────────────────────────
        Text(
          ref.tr('breakdown'),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        VoidActionButton(
          onTap: () => context.go(
            '/game',
            extra: {'mode': widget.mode, 'category': widget.category},
          ),
          label: ref.tr('play_again'),
        ),
        const SizedBox(height: 10),

        Pressable(
          onTap: _share,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: AppTheme.chipRadius,
              border: Border.all(color: AppTheme.textTertiary, width: 0.5),
            ),
            child: Text(
              ref.tr('share_result'),
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
              ref.tr('home'),
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
    );
  }
}
