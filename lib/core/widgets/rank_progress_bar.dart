import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/hive_service.dart';

class RankProgressBar extends StatefulWidget {
  final int vpBefore;
  final int vpGained;
  final int rankIndexBefore;
  final int rankIndexAfter;

  const RankProgressBar({
    super.key,
    required this.vpBefore,
    required this.vpGained,
    required this.rankIndexBefore,
    required this.rankIndexAfter,
  });

  @override
  State<RankProgressBar> createState() => _RankProgressBarState();
}

class _RankProgressBarState extends State<RankProgressBar> {
  int _displayedVP = 0;
  int _displayedRankIndex = 0;
  bool _isFlashing = false;

  static const int _vpPerRank = 10;

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

  @override
  void initState() {
    super.initState();
    _displayedVP = widget.vpBefore;
    _displayedRankIndex = widget.rankIndexBefore;
    WidgetsBinding.instance.addPostFrameCallback((_) => _animate());
  }

  Future<void> _animate() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    var target = widget.vpBefore + widget.vpGained;
    int current = widget.vpBefore;

    while (current != target) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      if (current < target) {
        current++;
      } else {
        current--;
      }

      // Rank up
      if (current >= _vpPerRank &&
          _displayedRankIndex < HiveService.rankNames.length - 1) {
        setState(() => _displayedVP = _vpPerRank);
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        setState(() => _isFlashing = true);
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;

        target = widget.vpGained - (_vpPerRank - widget.vpBefore);

        setState(() {
          _isFlashing = false;
          _displayedRankIndex++;
          _displayedVP = 0;
          current = 0;
        });

        continue;
      }

      // Rank down
      if (current < 0 && _displayedRankIndex > 0) {
        setState(() => _displayedVP = 0);
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        setState(() => _isFlashing = true);
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;

        setState(() {
          _isFlashing = false;
          _displayedRankIndex--;
          _displayedVP = _vpPerRank;
          current = _vpPerRank;
        });
        continue;
      }

      setState(() => _displayedVP = current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColors[_displayedRankIndex.clamp(0, _rankColors.length - 1)];
    final rankName = HiveService.rankNames[_displayedRankIndex.clamp(0, HiveService.rankNames.length - 1)];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isFlashing ? rankColor.withOpacity(0.15) : AppTheme.surface,
        borderRadius: AppTheme.neutralRadius,
        border: Border.all(
          color: _isFlashing ? rankColor.withOpacity(0.6) : AppTheme.textTertiary,
          width: _isFlashing ? 1 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                rankName,
                style: TextStyle(
                  color: rankColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              Text(
                '$_displayedVP / $_vpPerRank VP',
                style: TextStyle(
                  color: rankColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 10 segments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_vpPerRank, (i) {
              final filled = i < _displayedVP;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: filled ? rankColor.withOpacity(0.9) : AppTheme.background,
                  borderRadius: AppTheme.inputRadius,
                  border: Border.all(
                    color: filled ? rankColor : AppTheme.textTertiary,
                    width: 0.5,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.vpGained > 0
                    ? '+${widget.vpGained} VP'
                    : '${widget.vpGained} VP',
                style: TextStyle(
                  color: rankColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}