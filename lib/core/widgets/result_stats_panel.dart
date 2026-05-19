import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'result_stat.dart';

class ResultStatData {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const ResultStatData({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });
}

class ResultStatsPanel extends StatelessWidget {
  final List<ResultStatData> stats;

  const ResultStatsPanel({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.neutralRadius,
        border: Border.all(color: AppTheme.textTertiary, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var index = 0; index < stats.length; index++) ...[
            ResultStat(
              label: stats[index].label,
              value: stats[index].value,
              unit: stats[index].unit,
              color: stats[index].color,
            ),
            if (index != stats.length - 1)
              Container(width: 0.5, height: 40, color: AppTheme.textTertiary),
          ],
        ],
      ),
    );
  }
}
